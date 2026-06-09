import 'dart:async';
import 'dart:math';

import 'package:endurain/core/services/diagnostics_service.dart';
import 'package:endurain/core/services/location_service.dart';
import 'package:endurain/core/services/location_settings_builder.dart';
import 'package:endurain/features/activity/models/activity_recording_error.dart';
import 'package:endurain/features/activity/models/active_activity_session.dart';
import 'package:endurain/features/activity/models/activity_recording_state.dart';
import 'package:endurain/features/activity/models/activity_track_segment.dart';
import 'package:endurain/features/activity/models/activity_track_point.dart';
import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/models/recorded_activity_point.dart';
import 'package:endurain/features/activity/services/activity_location_recorder.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart' hide ActivityType;

class ActivityRecordingService {
  ActivityRecordingService({
    required ActivityLocationRecorder recorder,
    DateTime Function()? now,
    DiagnosticsRecorder? diagnostics,
    LocationService? locationService,
  }) : _recorder = recorder,
       _now = now ?? DateTime.now,
       _diagnostics = diagnostics ?? const NoopDiagnosticsRecorder(),
       _locationService = locationService ?? LocationService();

  final DateTime Function() _now;
  final DiagnosticsRecorder _diagnostics;
  final LocationService _locationService;
  final ActivityLocationRecorder _recorder;

  final StreamController<ActivityRecordingState> _stateController =
      StreamController<ActivityRecordingState>.broadcast();

  ActivityRecordingState _state = ActivityRecordingState();
  StreamSubscription<ActivityRecorderEvent>? _recorderSubscription;
  Timer? _elapsedTimer;
  DateTime? _recordingSegmentStartedAt;
  int _elapsedBeforeCurrentSegmentSeconds = 0;
  int _lastBreadcrumbPointCount = 0;
  bool _isDisposed = false;
  BackgroundLocationConfig? _backgroundConfig;

  ActivityRecordingState get state => _state;

  Stream<ActivityRecordingState> get stateStream => _stateController.stream;

  void configureBackgroundTracking(BackgroundLocationConfig config) {
    _backgroundConfig = config;
  }

  Future<void> start({
    required ActivityType activityType,
    BackgroundLocationConfig? backgroundConfig,
  }) async {
    _ensureNotDisposed();
    if (_state.isActive || _state.status == ActivityRecordingStatus.stopping) {
      return;
    }

    _recordBreadcrumb(
      DiagnosticsEvents.activityStartRequested,
      details: {'activityType': activityType.name},
    );
    final locationErrorKey = await _locationErrorKey();
    if (locationErrorKey != null) {
      _recordBreadcrumb(
        DiagnosticsEvents.activityStartFailed,
        details: {
          'reason': locationErrorKey.name,
          'activityType': activityType.name,
        },
      );
      _emit(
        ActivityRecordingState(
          status: ActivityRecordingStatus.failed,
          activityType: activityType,
          lastErrorKey: locationErrorKey,
        ),
      );
      return;
    }
    if (backgroundConfig != null) {
      _backgroundConfig = backgroundConfig;
    }
    final backgroundErrorKey = await _backgroundTrackingErrorKey();
    if (backgroundErrorKey != null) {
      _recordBreadcrumb(
        DiagnosticsEvents.activityStartFailed,
        details: {
          'reason': backgroundErrorKey.name,
          'activityType': activityType.name,
        },
      );
      _emit(
        ActivityRecordingState(
          status: ActivityRecordingStatus.failed,
          activityType: activityType,
          lastErrorKey: backgroundErrorKey,
        ),
      );
      return;
    }
    final startedAt = _now();
    _recordingSegmentStartedAt = startedAt;
    _elapsedBeforeCurrentSegmentSeconds = 0;
    _lastBreadcrumbPointCount = 0;
    _emit(
      ActivityRecordingState(
        status: ActivityRecordingStatus.recording,
        activityType: activityType,
        startedAt: startedAt,
        segments: [ActivityTrackSegment()],
      ),
    );
    _recordBreadcrumb(
      DiagnosticsEvents.activityStarted,
      details: {
        'activityType': activityType.name,
        'distanceFilterMeters': LocationDistanceFilters.recordingMeters,
      },
    );
    _startElapsedTimer();
    _startRecorderEvents();
    try {
      await _recorder.start(
        ActivityRecorderStartRequest(
          localSessionId: _defaultSessionId(),
          activityType: activityType,
          startedAt: startedAt,
          backgroundConfig: _backgroundConfig,
        ),
      );
    } catch (error, stackTrace) {
      _diagnostics.recordErrorSync(
        error,
        stackTrace,
        source: DiagnosticsSources.activityRecorder,
      );
      _fail(ActivityRecordingError.locationStreamFailed);
    }
  }

  Future<bool> openAppSettings() {
    return _locationService.openAppSettings();
  }

  Future<bool> isBackgroundTrackingReady() async {
    return await _backgroundTrackingErrorKey() == null;
  }

  Future<bool> requestBackgroundTrackingPermission() async {
    if (!_requiresAppleBackgroundPermission) {
      return true;
    }

    var permission = await _locationService.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.unableToDetermine) {
      permission = await _locationService.requestPermission();
    }

    return permission == LocationPermission.always;
  }

  Future<void> pause() async {
    _ensureNotDisposed();
    if (_state.status == ActivityRecordingStatus.paused) {
      return;
    }
    if (_state.status != ActivityRecordingStatus.recording) {
      _failInvalidTransition();
      return;
    }

    final elapsedDurationSeconds = _currentElapsedDurationSeconds();
    _elapsedBeforeCurrentSegmentSeconds = elapsedDurationSeconds;
    _recordingSegmentStartedAt = null;
    _cancelElapsedTimer();
    _emit(
      _state.copyWith(
        status: ActivityRecordingStatus.paused,
        elapsedDurationSeconds: elapsedDurationSeconds,
      ),
    );
    _recordBreadcrumb(
      DiagnosticsEvents.activityPaused,
      details: {
        'elapsedSeconds': elapsedDurationSeconds,
        'pointCount': _state.points.length,
        'segmentCount': _state.segments.length,
      },
    );
    await _runRecorderCommand(
      _recorder.pause,
      ActivityRecordingError.localSaveFailed,
    );
  }

  Future<void> resume() async {
    _ensureNotDisposed();
    if (_state.status == ActivityRecordingStatus.recording) {
      return;
    }
    if (_state.status != ActivityRecordingStatus.paused) {
      _failInvalidTransition();
      return;
    }

    _recordingSegmentStartedAt = _now();
    _emit(
      _state.startNewSegment().copyWith(
        status: ActivityRecordingStatus.recording,
      ),
    );
    _recordBreadcrumb(
      DiagnosticsEvents.activityResumed,
      details: {
        'elapsedSeconds': _state.elapsedDurationSeconds,
        'pointCount': _state.points.length,
        'segmentCount': _state.segments.length,
      },
    );
    _startElapsedTimer();
    await _runRecorderCommand(
      _recorder.resume,
      ActivityRecordingError.localSaveFailed,
    );
  }

  Future<void> stop() async {
    _ensureNotDisposed();
    if (!_state.isActive) {
      return;
    }

    final elapsedDurationSeconds = _currentElapsedDurationSeconds();
    _elapsedBeforeCurrentSegmentSeconds = elapsedDurationSeconds;
    _recordingSegmentStartedAt = null;
    _cancelElapsedTimer();

    _emit(
      _state.copyWith(
        status: ActivityRecordingStatus.stopping,
        elapsedDurationSeconds: elapsedDurationSeconds,
      ),
    );
    final stopped = await _runRecorderCommand(
      _recorder.stop,
      ActivityRecordingError.localSaveFailed,
    );
    if (!stopped) {
      return;
    }

    await _finalizeStateFromStore();
    if (_state.points.isEmpty) {
      _recordBreadcrumb(
        DiagnosticsEvents.activityStopFailed,
        details: {
          'reason': ActivityRecordingError.emptyRecording.name,
          'elapsedSeconds': elapsedDurationSeconds,
        },
      );
      _emit(
        _state.copyWith(
          status: ActivityRecordingStatus.failed,
          endedAt: _now(),
          lastErrorKey: ActivityRecordingError.emptyRecording,
          elapsedDurationSeconds: elapsedDurationSeconds,
        ),
      );
      await _recorder.discard();
      return;
    }

    _recordBreadcrumb(
      DiagnosticsEvents.activityStopped,
      details: {
        'elapsedSeconds': elapsedDurationSeconds,
        'pointCount': _state.points.length,
        'segmentCount': _state.segments.length,
      },
    );
    _emit(
      _state.copyWith(
        status: ActivityRecordingStatus.completed,
        endedAt: _now(),
      ),
    );
  }

  Future<void> discard() async {
    _ensureNotDisposed();
    _cancelElapsedTimer();
    _recordingSegmentStartedAt = null;
    _elapsedBeforeCurrentSegmentSeconds = 0;
    _lastBreadcrumbPointCount = 0;
    _backgroundConfig = null;
    final discarded = await _runRecorderCommand(
      _recorder.discard,
      ActivityRecordingError.localSaveFailed,
    );
    if (!discarded) {
      return;
    }
    _emit(ActivityRecordingState());
    _recordBreadcrumb(DiagnosticsEvents.activityDiscarded);
  }

  void dispose() {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    _cancelElapsedTimer();
    _recorderSubscription?.cancel();
    _recorderSubscription = null;
    _disposeRecorderWithoutThrow();
    _stateController.close();
  }

  void _startElapsedTimer() {
    _cancelElapsedTimer();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_state.status != ActivityRecordingStatus.recording) {
        return;
      }
      final elapsedDurationSeconds = _currentElapsedDurationSeconds();
      if (elapsedDurationSeconds == _state.elapsedDurationSeconds) {
        return;
      }
      _emit(_state.copyWith(elapsedDurationSeconds: elapsedDurationSeconds));
    });
  }

  void _cancelElapsedTimer() {
    _elapsedTimer?.cancel();
    _elapsedTimer = null;
  }

  int _currentElapsedDurationSeconds() {
    final segmentStartedAt = _recordingSegmentStartedAt;
    if (segmentStartedAt == null) {
      return _elapsedBeforeCurrentSegmentSeconds;
    }
    final segmentSeconds = _now().difference(segmentStartedAt).inSeconds;
    return _elapsedBeforeCurrentSegmentSeconds +
        (segmentSeconds < 0 ? 0 : segmentSeconds);
  }

  void _recordPointMilestoneIfNeeded({required int pointCount}) {
    if (pointCount == 1 || pointCount - _lastBreadcrumbPointCount >= 25) {
      _lastBreadcrumbPointCount = pointCount;
      _recordBreadcrumb(
        DiagnosticsEvents.activityPointMilestone,
        details: {
          'pointCount': pointCount,
          'segmentCount': _state.segments.length,
          'elapsedSeconds': _state.elapsedDurationSeconds,
        },
      );
    }
  }

  void _startRecorderEvents() {
    if (_recorderSubscription != null) {
      return;
    }
    _recorderSubscription = _recorder.events.listen(
      _handleRecorderEvent,
      onError: (Object error, StackTrace stackTrace) {
        _diagnostics.recordErrorSync(
          error,
          stackTrace,
          source: DiagnosticsSources.activityRecorder,
        );
        _fail(ActivityRecordingError.locationStreamFailed);
      },
    );
  }

  void _handleRecorderEvent(ActivityRecorderEvent event) {
    switch (event.type) {
      case ActivityRecorderEventType.started:
      case ActivityRecorderEventType.paused:
      case ActivityRecorderEventType.resumed:
      case ActivityRecorderEventType.stopped:
      case ActivityRecorderEventType.recoverableStateChanged:
        break;
      case ActivityRecorderEventType.pointBatchAvailable:
        _recordRecordedPoints(event.points);
      case ActivityRecorderEventType.failed:
        _fail(_errorKeyForRecorderFailure(event.failureReason));
    }
  }

  Future<bool> _runRecorderCommand(
    Future<void> Function() command,
    ActivityRecordingError errorKey,
  ) async {
    try {
      await command();
      return true;
    } catch (error, stackTrace) {
      _recordRecorderError(error, stackTrace);
      _fail(errorKey);
      return false;
    }
  }

  void _recordRecorderError(Object error, StackTrace stackTrace) {
    _diagnostics.recordErrorSync(
      error,
      stackTrace,
      source: DiagnosticsSources.activityRecorder,
    );
  }

  void _discardRecorderWithoutThrow() {
    unawaited(
      _recorder.discard().catchError((Object error, StackTrace stackTrace) {
        _recordRecorderError(error, stackTrace);
      }),
    );
  }

  void _disposeRecorderWithoutThrow() {
    unawaited(
      _recorder.dispose().catchError((Object error, StackTrace stackTrace) {
        _recordRecorderError(error, stackTrace);
      }),
    );
  }

  /// Rebuilds the in-memory recording state from the durable store before
  /// completion so points persisted while the app was backgrounded (with a
  /// detached event sink) are included in the finalized activity.
  Future<void> _finalizeStateFromStore() async {
    try {
      final recordedPoints = await _recorder.drain();
      if (recordedPoints.isEmpty) {
        return;
      }
      final segments = _segmentsFromRecorded(recordedPoints);
      _lastBreadcrumbPointCount = recordedPoints.length;
      _emit(_state.copyWith(segments: segments));
    } catch (error, stackTrace) {
      _recordRecorderError(error, stackTrace);
    }
  }

  void _recordRecordedPoints(List<RecordedActivityPoint> points) {
    if (_state.status != ActivityRecordingStatus.recording || points.isEmpty) {
      return;
    }

    // Apply the whole batch with a single state emission. A background drain
    // can deliver hundreds of points at once; emitting once per point would
    // rebuild the immutable segment list and notify listeners O(n) times.
    final segmentPoints = <List<ActivityTrackPoint>>[
      for (final segment in _state.segments) [...segment.points],
    ];
    if (segmentPoints.isEmpty) {
      segmentPoints.add(<ActivityTrackPoint>[]);
    }

    for (final recordedPoint in points) {
      while (segmentPoints.length <= recordedPoint.segmentIndex) {
        segmentPoints.add(<ActivityTrackPoint>[]);
      }
      segmentPoints.last.add(recordedPoint.toTrackPoint());
    }

    final segments = [
      for (final pts in segmentPoints) ActivityTrackSegment(points: pts),
    ];
    _emit(_state.copyWith(segments: segments));
    _recordPointMilestoneIfNeeded(pointCount: _state.points.length);
  }

  ActivityRecordingError _errorKeyForRecorderFailure(
    ActivityRecorderFailureReason? reason,
  ) {
    return switch (reason) {
      ActivityRecorderFailureReason.locationUnavailable =>
        ActivityRecordingError.locationServiceDisabled,
      ActivityRecorderFailureReason.permissionLost =>
        ActivityRecordingError.locationPermissionDenied,
      ActivityRecorderFailureReason.persistenceFailed =>
        ActivityRecordingError.localSaveFailed,
      ActivityRecorderFailureReason.unsupportedPlatform ||
      ActivityRecorderFailureReason.locationStreamFailed ||
      null => ActivityRecordingError.locationStreamFailed,
    };
  }

  Future<ActivityRecordingError?> _locationErrorKey() async {
    if (!await _locationService.isLocationServiceEnabled()) {
      return ActivityRecordingError.locationServiceDisabled;
    }

    var permission = await _locationService.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _locationService.requestPermission();
    }

    return switch (permission) {
      LocationPermission.always || LocationPermission.whileInUse => null,
      LocationPermission.denied =>
        ActivityRecordingError.locationPermissionDenied,
      LocationPermission.deniedForever =>
        ActivityRecordingError.locationPermissionDeniedForever,
      LocationPermission.unableToDetermine =>
        ActivityRecordingError.locationPermissionDenied,
    };
  }

  Future<ActivityRecordingError?> _backgroundTrackingErrorKey() async {
    if (!_requiresAppleBackgroundPermission) {
      return null;
    }

    final permission = await _locationService.checkPermission();
    return permission == LocationPermission.always
        ? null
        : ActivityRecordingError.backgroundPermissionRequired;
  }

  bool get _requiresAppleBackgroundPermission {
    return _backgroundConfig != null &&
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  void _failInvalidTransition() {
    _fail(ActivityRecordingError.invalidTransition);
  }

  void _fail(ActivityRecordingError errorKey) {
    _cancelElapsedTimer();
    _recordingSegmentStartedAt = null;
    _discardRecorderWithoutThrow();
    _recordBreadcrumb(
      DiagnosticsEvents.activityFailed,
      details: {'reason': errorKey.name, 'pointCount': _state.points.length},
    );
    _emit(
      _state.copyWith(
        status: ActivityRecordingStatus.failed,
        lastErrorKey: errorKey,
      ),
    );
  }

  void _emit(ActivityRecordingState state) {
    _state = state;
    _stateController.add(state);
  }

  void _recordBreadcrumb(
    String event, {
    Map<String, Object?> details = const {},
  }) {
    _diagnostics.recordBreadcrumbSync(event, details: details);
  }

  /// Attempts to restore a recoverable active recording from the recorder.
  ///
  /// Returns `true` when a non-empty recording was recovered and the service
  /// state was restored as a paused recording the user can resume or save.
  /// Empty or non-recoverable sessions are discarded and `false` is returned.
  Future<bool> recoverActiveSession() async {
    _ensureNotDisposed();
    if (_state.isActive) {
      return false;
    }
    _startRecorderEvents();
    final session = await _recorder.recoverActiveSession();
    if (session == null || !session.isActive) {
      if (session != null) {
        await _recorder.discard();
      }
      return false;
    }
    final recordedPoints = await _recorder.drain();
    if (recordedPoints.isEmpty) {
      await _recorder.discard();
      _recordBreadcrumb(
        DiagnosticsEvents.activityActiveSessionRecovered,
        details: {'pointCount': 0, 'recovered': false},
      );
      return false;
    }

    return _recoverFromSessionAndPoints(session, recordedPoints);
  }

  bool _recoverFromSessionAndPoints(
    ActiveActivitySession session,
    List<RecordedActivityPoint> recordedPoints,
  ) {
    final segments = _segmentsFromRecorded(recordedPoints);
    _elapsedBeforeCurrentSegmentSeconds = session.elapsedDurationSeconds;
    _recordingSegmentStartedAt = null;
    _lastBreadcrumbPointCount = recordedPoints.length;
    _emit(
      ActivityRecordingState(
        status: ActivityRecordingStatus.paused,
        activityType: session.activityType,
        startedAt: session.startedAt,
        elapsedDurationSeconds: session.elapsedDurationSeconds,
        segments: segments,
      ),
    );
    _recordBreadcrumb(
      DiagnosticsEvents.activityActiveSessionRecovered,
      details: {
        'pointCount': recordedPoints.length,
        'segmentCount': segments.length,
        'recovered': true,
      },
    );
    return true;
  }

  List<ActivityTrackSegment> _segmentsFromRecorded(
    List<RecordedActivityPoint> points,
  ) {
    final segments = <ActivityTrackSegment>[];
    var currentSegmentIndex = points.first.segmentIndex;
    var currentPoints = <ActivityTrackPoint>[];
    for (final point in points) {
      if (point.segmentIndex != currentSegmentIndex &&
          currentPoints.isNotEmpty) {
        segments.add(ActivityTrackSegment(points: currentPoints));
        currentPoints = <ActivityTrackPoint>[];
        currentSegmentIndex = point.segmentIndex;
      }
      currentPoints.add(point.toTrackPoint());
    }
    if (currentPoints.isNotEmpty) {
      segments.add(ActivityTrackSegment(points: currentPoints));
    }
    return segments;
  }

  static String _defaultSessionId() {
    final timestamp = DateTime.now().toUtc().microsecondsSinceEpoch;
    final random = Random().nextInt(1 << 32);
    return 'session_${timestamp}_$random';
  }

  void _ensureNotDisposed() {
    if (_isDisposed) {
      throw StateError('ActivityRecordingService is disposed.');
    }
  }
}
