import 'dart:async';
import 'dart:math';

import 'package:endurain/core/services/diagnostics_service.dart';
import 'package:endurain/core/services/location_service.dart';
import 'package:endurain/core/services/location_settings_builder.dart';
import 'package:endurain/features/activity/models/active_activity_session.dart';
import 'package:endurain/features/activity/models/activity_recording_state.dart';
import 'package:endurain/features/activity/models/activity_track_segment.dart';
import 'package:endurain/features/activity/models/activity_track_point.dart';
import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/models/recorded_activity_point.dart';
import 'package:endurain/features/activity/repositories/active_activity_store.dart';
import 'package:endurain/features/activity/services/activity_location_recorder.dart';
import 'package:endurain/features/activity/services/geolocator_activity_location_recorder.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart' hide ActivityType;

class ActivityRecordingErrorKeys {
  const ActivityRecordingErrorKeys._();

  static const String invalidTransition = 'activityRecordingInvalidTransition';
  static const String locationStreamFailed = 'activityLocationStreamFailed';
  static const String emptyRecording = 'activityRecordingEmpty';
  static const String gpxGenerationFailed = 'activityGpxGenerationFailed';
  static const String localSaveFailed = 'activityLocalSaveFailed';
  static const String locationServiceDisabled =
      'activityLocationServiceDisabled';
  static const String locationPermissionDenied =
      'activityLocationPermissionDenied';
  static const String locationPermissionDeniedForever =
      'activityLocationPermissionDeniedForever';
  static const String backgroundPermissionRequired =
      'activityBackgroundPermissionRequired';
}

class ActivityRecordingService {
  ActivityRecordingService({
    DateTime Function()? now,
    DiagnosticsRecorder? diagnostics,
    LocationService? locationService,
    ActivityLocationRecorder? recorder,
    ActiveActivityStore? activeStore,
    String Function()? sessionIdProvider,
  }) : this._(
         now: now ?? DateTime.now,
         diagnostics: diagnostics ?? const NoopDiagnosticsRecorder(),
         locationService: locationService ?? LocationService(),
         recorder: recorder,
         activeStore: activeStore,
         sessionIdProvider: sessionIdProvider ?? _defaultSessionId,
       );

  ActivityRecordingService._({
    required DateTime Function() now,
    required DiagnosticsRecorder diagnostics,
    required LocationService locationService,
    required ActivityLocationRecorder? recorder,
    required ActiveActivityStore? activeStore,
    required String Function() sessionIdProvider,
  }) : _now = now,
       _diagnostics = diagnostics,
       _locationService = locationService,
       _recorder =
           recorder ??
           (activeStore == null
               ? null
               : GeolocatorActivityLocationRecorder(
                   store: activeStore,
                   locationService: locationService,
                   diagnostics: diagnostics,
                   now: now,
                 )),
       _activeStore = activeStore,
       _sessionIdProvider = sessionIdProvider;

  final DateTime Function() _now;
  final DiagnosticsRecorder _diagnostics;
  final LocationService _locationService;
  final ActivityLocationRecorder? _recorder;

  /// Optional durable store for the active recording. When provided, every
  /// point and session transition is persisted so the recording can be
  /// recovered after the app is paused, killed, or restarted. When `null`,
  /// recording behaves as an in-memory-only foreground session.
  final ActiveActivityStore? _activeStore;
  final String Function() _sessionIdProvider;
  ActiveActivitySession? _activeSession;
  Future<void> _storeChain = Future<void>.value();
  final StreamController<ActivityRecordingState> _stateController =
      StreamController<ActivityRecordingState>.broadcast();

  ActivityRecordingState _state = ActivityRecordingState();
  StreamSubscription<Position>? _positionSubscription;
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
          'reason': locationErrorKey,
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
          'reason': backgroundErrorKey,
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
    if (_recorder != null) {
      _startRecorderEvents();
      try {
        await _recorder.start(
          ActivityRecorderStartRequest(
            localSessionId: _sessionIdProvider(),
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
        _fail(ActivityRecordingErrorKeys.locationStreamFailed);
      }
    } else {
      _beginActiveSession(activityType, startedAt);
      _startLocationStream();
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
    final cancelPositionSubscription = _recorder == null
        ? _cancelPositionSubscription()
        : null;
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
    if (_recorder != null) {
      await _runRecorderCommand(
        _recorder.pause,
        ActivityRecordingErrorKeys.localSaveFailed,
      );
    } else {
      _updateActiveSession(
        (session) => session.copyWith(
          status: ActiveActivityStatus.paused,
          elapsedDurationSeconds: elapsedDurationSeconds,
          currentSegmentIndex: _currentSegmentIndex,
          pausedAt: _now(),
        ),
        save: true,
      );
      await cancelPositionSubscription;
    }
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
    if (_recorder != null) {
      await _runRecorderCommand(
        _recorder.resume,
        ActivityRecordingErrorKeys.localSaveFailed,
      );
    } else {
      _updateActiveSession(
        (session) => session.copyWith(
          status: ActiveActivityStatus.recording,
          currentSegmentIndex: _currentSegmentIndex,
          resumedAt: _now(),
        ),
        save: true,
      );
      _startLocationStream();
    }
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
    if (_recorder == null) {
      await _cancelPositionSubscription();
    }
    if (_state.points.isEmpty) {
      _recordBreadcrumb(
        DiagnosticsEvents.activityStopFailed,
        details: {
          'reason': ActivityRecordingErrorKeys.emptyRecording,
          'elapsedSeconds': elapsedDurationSeconds,
        },
      );
      _emit(
        _state.copyWith(
          status: ActivityRecordingStatus.failed,
          endedAt: _now(),
          lastErrorKey: ActivityRecordingErrorKeys.emptyRecording,
          elapsedDurationSeconds: elapsedDurationSeconds,
        ),
      );
      if (_recorder != null) {
        await _recorder.discard();
      } else {
        _clearActiveSession();
      }
      return;
    }

    _emit(
      _state.copyWith(
        status: ActivityRecordingStatus.stopping,
        elapsedDurationSeconds: elapsedDurationSeconds,
      ),
    );
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
    if (_recorder != null) {
      await _runRecorderCommand(
        _recorder.stop,
        ActivityRecordingErrorKeys.localSaveFailed,
      );
    } else {
      _updateActiveSession(
        (session) => session.copyWith(
          status: ActiveActivityStatus.completed,
          elapsedDurationSeconds: elapsedDurationSeconds,
          currentSegmentIndex: _currentSegmentIndex,
          endedAt: _now(),
        ),
        complete: true,
      );
    }
  }

  Future<void> discard() async {
    _ensureNotDisposed();
    _cancelElapsedTimer();
    _recordingSegmentStartedAt = null;
    _elapsedBeforeCurrentSegmentSeconds = 0;
    _lastBreadcrumbPointCount = 0;
    _backgroundConfig = null;
    if (_recorder != null) {
      final discarded = await _runRecorderCommand(
        _recorder.discard,
        ActivityRecordingErrorKeys.localSaveFailed,
      );
      if (!discarded) {
        return;
      }
    } else {
      await _cancelPositionSubscription();
    }
    _emit(ActivityRecordingState());
    _recordBreadcrumb(DiagnosticsEvents.activityDiscarded);
    if (_recorder == null) {
      _clearActiveSession();
    }
  }

  void dispose() {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    _cancelElapsedTimer();
    _positionSubscription?.cancel();
    _positionSubscription = null;
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

  void _startLocationStream() {
    if (_positionSubscription != null) {
      return;
    }

    try {
      _positionSubscription = _locationService
          .getPositionStream(
            background: _backgroundConfig,
            distanceFilter: LocationDistanceFilters.recordingMeters,
          )
          .listen(
            _recordPosition,
            onError: _handlePositionError,
            onDone: _handlePositionStreamDone,
          );
    } catch (error, stackTrace) {
      _diagnostics.recordErrorSync(
        error,
        stackTrace,
        source: DiagnosticsSources.activityLocationStream,
      );
      _fail(ActivityRecordingErrorKeys.locationStreamFailed);
    }
  }

  Future<void> _cancelPositionSubscription() async {
    final subscription = _positionSubscription;
    _positionSubscription = null;
    await subscription?.cancel();
  }

  void _recordPosition(Position position) {
    if (_state.status != ActivityRecordingStatus.recording) {
      return;
    }
    final trackPoint = ActivityTrackPoint.fromPosition(position);
    _emit(_state.addPoint(trackPoint));
    _persistRecordedPoint(trackPoint);
    _recordPointMilestoneIfNeeded(pointCount: _state.points.length);
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

  void _handlePositionError(Object error, StackTrace stackTrace) {
    _diagnostics.recordErrorSync(
      error,
      stackTrace,
      source: DiagnosticsSources.activityLocationStream,
    );
    _fail(ActivityRecordingErrorKeys.locationStreamFailed);
  }

  void _handlePositionStreamDone() {
    _recordBreadcrumb(
      DiagnosticsEvents.activityLocationStreamDone,
      details: {
        'status': _state.status.name,
        'pointCount': _state.points.length,
      },
    );
  }

  void _startRecorderEvents() {
    if (_recorder == null || _recorderSubscription != null) {
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
        _fail(ActivityRecordingErrorKeys.locationStreamFailed);
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
        _activeSession = event.session;
      case ActivityRecorderEventType.pointBatchAvailable:
        _recordRecordedPoints(event.points);
      case ActivityRecorderEventType.failed:
        _fail(_errorKeyForRecorderFailure(event.failureReason));
    }
  }

  Future<bool> _runRecorderCommand(
    Future<void> Function() command,
    String errorKey,
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
    final recorder = _recorder;
    if (recorder == null) {
      return;
    }
    unawaited(
      recorder.discard().catchError((Object error, StackTrace stackTrace) {
        _recordRecorderError(error, stackTrace);
      }),
    );
  }

  void _disposeRecorderWithoutThrow() {
    final recorder = _recorder;
    if (recorder == null) {
      return;
    }
    unawaited(
      recorder.dispose().catchError((Object error, StackTrace stackTrace) {
        _recordRecorderError(error, stackTrace);
      }),
    );
  }

  void _recordRecordedPoints(List<RecordedActivityPoint> points) {
    if (_state.status != ActivityRecordingStatus.recording || points.isEmpty) {
      return;
    }

    for (final recordedPoint in points) {
      var nextState = _state;
      while (nextState.segments.length <= recordedPoint.segmentIndex) {
        nextState = nextState.startNewSegment();
      }

      _emit(nextState.addPoint(recordedPoint.toTrackPoint()));
      _recordPointMilestoneIfNeeded(pointCount: _state.points.length);
    }
  }

  String _errorKeyForRecorderFailure(ActivityRecorderFailureReason? reason) {
    return switch (reason) {
      ActivityRecorderFailureReason.locationUnavailable =>
        ActivityRecordingErrorKeys.locationServiceDisabled,
      ActivityRecorderFailureReason.permissionLost =>
        ActivityRecordingErrorKeys.locationPermissionDenied,
      ActivityRecorderFailureReason.persistenceFailed =>
        ActivityRecordingErrorKeys.localSaveFailed,
      ActivityRecorderFailureReason.unsupportedPlatform ||
      ActivityRecorderFailureReason.locationStreamFailed ||
      null => ActivityRecordingErrorKeys.locationStreamFailed,
    };
  }

  Future<String?> _locationErrorKey() async {
    if (!await _locationService.isLocationServiceEnabled()) {
      return ActivityRecordingErrorKeys.locationServiceDisabled;
    }

    var permission = await _locationService.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _locationService.requestPermission();
    }

    return switch (permission) {
      LocationPermission.always || LocationPermission.whileInUse => null,
      LocationPermission.denied =>
        ActivityRecordingErrorKeys.locationPermissionDenied,
      LocationPermission.deniedForever =>
        ActivityRecordingErrorKeys.locationPermissionDeniedForever,
      LocationPermission.unableToDetermine =>
        ActivityRecordingErrorKeys.locationPermissionDenied,
    };
  }

  Future<String?> _backgroundTrackingErrorKey() async {
    if (!_requiresAppleBackgroundPermission) {
      return null;
    }

    final permission = await _locationService.checkPermission();
    return permission == LocationPermission.always
        ? null
        : ActivityRecordingErrorKeys.backgroundPermissionRequired;
  }

  bool get _requiresAppleBackgroundPermission {
    return _backgroundConfig != null &&
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  void _failInvalidTransition() {
    _fail(ActivityRecordingErrorKeys.invalidTransition);
  }

  void _fail(String errorKey) {
    _cancelElapsedTimer();
    _recordingSegmentStartedAt = null;
    if (_recorder != null) {
      _discardRecorderWithoutThrow();
    } else {
      unawaited(_cancelPositionSubscription());
    }
    _recordBreadcrumb(
      DiagnosticsEvents.activityFailed,
      details: {'reason': errorKey, 'pointCount': _state.points.length},
    );
    _emit(
      _state.copyWith(
        status: ActivityRecordingStatus.failed,
        lastErrorKey: errorKey,
      ),
    );
    if (_recorder == null) {
      _clearActiveSession();
    }
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

  int get _currentSegmentIndex {
    return _state.segments.isEmpty ? 0 : _state.segments.length - 1;
  }

  void _beginActiveSession(ActivityType activityType, DateTime startedAt) {
    final store = _activeStore;
    if (store == null) {
      return;
    }
    final session = ActiveActivitySession(
      localSessionId: _sessionIdProvider(),
      activityType: activityType,
      status: ActiveActivityStatus.recording,
      startedAt: startedAt,
    );
    _activeSession = session;
    _enqueueStore(() async {
      await store.clear();
      await store.saveSession(session);
    });
  }

  void _persistRecordedPoint(ActivityTrackPoint point) {
    final store = _activeStore;
    if (store == null || _activeSession == null) {
      return;
    }
    final recorded = RecordedActivityPoint.fromTrackPoint(
      point,
      segmentIndex: _currentSegmentIndex,
    );
    _enqueueStore(() => store.appendPoints([recorded]));
  }

  void _updateActiveSession(
    ActiveActivitySession Function(ActiveActivitySession session) update, {
    bool save = false,
    bool complete = false,
  }) {
    final store = _activeStore;
    final session = _activeSession;
    if (store == null || session == null) {
      return;
    }
    final updated = update(session);
    _activeSession = updated;
    if (complete) {
      _enqueueStore(() => store.complete(updated));
    } else if (save) {
      _enqueueStore(() => store.saveSession(updated));
    }
  }

  void _clearActiveSession() {
    final store = _activeStore;
    _activeSession = null;
    if (store == null) {
      return;
    }
    _enqueueStore(() => store.clear());
  }

  void _enqueueStore(Future<void> Function() action) {
    _storeChain = _storeChain.then((_) => action()).catchError((
      Object error,
      StackTrace stackTrace,
    ) {
      _recordBreadcrumb(
        DiagnosticsEvents.activityRecorderFailed,
        details: const {'reason': 'persistenceFailed'},
      );
    });
  }

  /// Attempts to restore a recoverable active recording from the durable store.
  ///
  /// Returns `true` when a non-empty recording was recovered and the service
  /// state was restored as a paused recording the user can resume or save.
  /// Empty or non-recoverable sessions are cleared and `false` is returned.
  Future<bool> recoverActiveSession() async {
    _ensureNotDisposed();
    if (_recorder != null) {
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

    final store = _activeStore;
    if (store == null || _state.isActive) {
      return false;
    }

    final session = await store.loadSession();
    if (session == null || !session.isActive) {
      if (session != null) {
        await store.clear();
      }
      return false;
    }

    final recordedPoints = await store.readPoints();
    if (recordedPoints.isEmpty) {
      await store.clear();
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
    _activeSession = session.copyWith(status: ActiveActivityStatus.paused);
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
