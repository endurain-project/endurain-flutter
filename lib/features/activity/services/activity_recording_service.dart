import 'dart:async';

import 'package:endurain/core/services/diagnostics_service.dart';
import 'package:endurain/core/services/location_service.dart';
import 'package:endurain/core/services/location_settings_builder.dart';
import 'package:endurain/core/utils/id_generation.dart';
import 'package:endurain/features/activity/models/activity_recording_error.dart';
import 'package:endurain/features/activity/models/active_activity_session.dart';
import 'package:endurain/features/activity/models/activity_recording_state.dart';
import 'package:endurain/features/activity/models/activity_track_segment.dart';
import 'package:endurain/features/activity/models/activity_track_point.dart';
import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/models/recorded_activity_point.dart';
import 'package:endurain/features/activity/models/recorded_sensor_sample.dart';
import 'package:endurain/features/activity/services/activity_location_recorder.dart';
import 'package:endurain/features/activity/services/movement_auto_pause_detector.dart';
import 'package:endurain/features/activity/services/native_activity_recorder_channel.dart';
import 'package:endurain/features/activity/services/sensor_reading_buffer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:geolocator/geolocator.dart' hide ActivityType;

class ActivityRecordingService {
  ActivityRecordingService({
    required ActivityLocationRecorder recorder,
    DateTime Function()? now,
    DiagnosticsRecorder? diagnostics,
    LocationService? locationService,
    Stream<RecordedSensorSample>? sensorReadings,
    Map<RecordedSensorKind, Future<String?> Function()> prepareSensorSources =
        const {},
    Duration sensorFreshness = const Duration(seconds: 10),
  }) : _recorder = recorder,
       _now = now ?? DateTime.now,
       _diagnostics = diagnostics ?? const NoopDiagnosticsRecorder(),
       _locationService = locationService ?? LocationService(),
       _sensorFreshness = sensorFreshness,
       _prepareSensorSources = prepareSensorSources {
    _sensorSubscription = sensorReadings?.listen(_onSensorReading);
  }

  final DateTime Function() _now;
  final DiagnosticsRecorder _diagnostics;
  final LocationService _locationService;
  final ActivityLocationRecorder _recorder;
  final Duration _sensorFreshness;

  /// Resolves each paired sensor's device id for the native recorder (and frees
  /// the Dart-side BLE connection) at recording start, keyed by sensor kind.
  /// Empty when native sensor capture is not in use (e.g. iOS keeps the Dart
  /// BLE connection and streams readings in instead).
  final Map<RecordedSensorKind, Future<String?> Function()>
  _prepareSensorSources;

  /// Time-ordered buffers of sensor readings captured while recording, keyed by
  /// sensor kind, used to stamp the nearest reading onto each track point.
  late final Map<RecordedSensorKind, SensorReadingBuffer> _sensorBuffers = {
    for (final kind in RecordedSensorKind.values)
      kind: SensorReadingBuffer(_sensorFreshness),
  };
  StreamSubscription<RecordedSensorSample>? _sensorSubscription;

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
  MovementAutoPauseConfig _autoPauseConfig = const MovementAutoPauseConfig();
  String? _localSessionId;
  String? _connectionOrigin;
  String? _connectionProfileId;

  ActivityRecordingState get state => _state;

  String? get localSessionId => _localSessionId;
  String? get connectionOrigin => _connectionOrigin;
  String? get connectionProfileId => _connectionProfileId;

  Stream<ActivityRecordingState> get stateStream => _stateController.stream;

  void configureBackgroundTracking(BackgroundLocationConfig config) {
    _backgroundConfig = config;
  }

  /// Supplies the auto-pause configuration to snapshot into the next
  /// recording's session. Called by the controller before [start] with the
  /// current value of `AutoPauseSettingsRepository.getConfig()`.
  void configureAutoPause(MovementAutoPauseConfig config) {
    _autoPauseConfig = config;
  }

  Future<void> start({
    required ActivityType activityType,
    BackgroundLocationConfig? backgroundConfig,
    String? localSessionId,
    String? connectionOrigin,
    String? connectionProfileId,
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
          lastError: locationErrorKey,
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
          lastError: backgroundErrorKey,
        ),
      );
      return;
    }
    final startedAt = _now();
    final resolvedSessionId = localSessionId ?? recordingSessionId();
    _localSessionId = resolvedSessionId;
    _connectionOrigin = connectionOrigin;
    _connectionProfileId = connectionProfileId;
    _recordingSegmentStartedAt = startedAt;
    _elapsedBeforeCurrentSegmentSeconds = 0;
    _lastBreadcrumbPointCount = 0;
    for (final buffer in _sensorBuffers.values) {
      buffer.clear();
    }
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
    // Hand each paired sensor off to the native recorder (Android), resolving
    // its device id and releasing the Dart-side BLE link. A handoff failure for
    // any kind must never block the recording start.
    final sensorDeviceIds = <RecordedSensorKind, String?>{};
    for (final entry in _prepareSensorSources.entries) {
      try {
        sensorDeviceIds[entry.key] = await entry.value();
      } catch (_) {
        sensorDeviceIds[entry.key] = null;
      }
    }
    try {
      await _startRecorder(
        ActivityRecorderStartRequest(
          localSessionId: resolvedSessionId,
          activityType: activityType,
          startedAt: startedAt,
          connectionOrigin: connectionOrigin,
          connectionProfileId: connectionProfileId,
          backgroundConfig: _backgroundConfig,
          heartRateDeviceId: sensorDeviceIds[RecordedSensorKind.heartRate],
          powerDeviceId: sensorDeviceIds[RecordedSensorKind.power],
          cadenceDeviceId: sensorDeviceIds[RecordedSensorKind.cadence],
          autoPauseConfig: _autoPauseConfig,
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
        isAutoPaused: false,
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
        isAutoPaused: false,
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

    if (!await _finalizeStateFromStore()) {
      _emit(
        _state.copyWith(
          status: ActivityRecordingStatus.failed,
          endedAt: _now(),
          lastError: ActivityRecordingError.localSaveFailed,
          elapsedDurationSeconds: elapsedDurationSeconds,
        ),
      );
      return;
    }
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
          lastError: ActivityRecordingError.emptyRecording,
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
    _localSessionId = null;
    _connectionOrigin = null;
    _connectionProfileId = null;
    _emit(ActivityRecordingState());
    _recordBreadcrumb(DiagnosticsEvents.activityDiscarded);
  }

  /// Clears the durable recorder session after the completed activity has
  /// been committed to local GPX and metadata storage.
  Future<void> acknowledgeFinalized() async {
    _ensureNotDisposed();
    await _recorder.discard();
    _localSessionId = null;
    _connectionOrigin = null;
    _connectionProfileId = null;
  }

  void dispose() {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    _cancelElapsedTimer();
    _recorderSubscription?.cancel();
    _recorderSubscription = null;
    _sensorSubscription?.cancel();
    _sensorSubscription = null;
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
      case ActivityRecorderEventType.autoPaused:
        _handleAutoPaused(event);
      case ActivityRecorderEventType.autoResumed:
        _handleAutoResumed(event);
    }
  }

  /// Bridges an autonomous auto-pause (the recorder's movement detector, not
  /// an explicit [pause] call) into the live UI state.
  ///
  /// Guarded to only act while actively recording so a duplicate or
  /// out-of-order event can never clobber a state the controller already
  /// knows about. Prefers the recorder's own elapsed-time computation (from
  /// [event.session]) over recomputing locally: the recorder timestamps the
  /// pause from the fix that triggered it, which stays correct even if the
  /// Dart isolate's own timer was throttled while backgrounded.
  void _handleAutoPaused(ActivityRecorderEvent event) {
    if (_state.status != ActivityRecordingStatus.recording) {
      return;
    }
    final elapsedDurationSeconds =
        event.session?.elapsedDurationSeconds ??
        _currentElapsedDurationSeconds();
    _elapsedBeforeCurrentSegmentSeconds = elapsedDurationSeconds;
    _recordingSegmentStartedAt = null;
    _cancelElapsedTimer();
    _emit(
      _state.copyWith(
        status: ActivityRecordingStatus.paused,
        elapsedDurationSeconds: elapsedDurationSeconds,
        isAutoPaused: true,
      ),
    );
    _recordBreadcrumb(
      DiagnosticsEvents.activityAutoPaused,
      details: {
        'elapsedSeconds': elapsedDurationSeconds,
        'pointCount': _state.points.length,
        'segmentCount': _state.segments.length,
      },
    );
  }

  /// Bridges an autonomous auto-resume (the recorder observed enough
  /// consecutive movement, not an explicit [resume] call) into the live UI
  /// state, starting a new track segment as required.
  ///
  /// Guarded to only act while auto-paused — in particular, a manually paused
  /// recording (`isAutoPaused == false`) never transitions here, which is the
  /// state-side half of "manual pause never auto-resumes" (the recorder-side
  /// half is that a manual pause stops monitoring location entirely).
  void _handleAutoResumed(ActivityRecorderEvent event) {
    if (_state.status != ActivityRecordingStatus.paused ||
        !_state.isAutoPaused) {
      return;
    }
    _recordingSegmentStartedAt = event.session?.resumedAt ?? _now();
    _emit(
      _state.startNewSegment().copyWith(
        status: ActivityRecordingStatus.recording,
        isAutoPaused: false,
      ),
    );
    _recordBreadcrumb(
      DiagnosticsEvents.activityAutoResumed,
      details: {
        'elapsedSeconds': _state.elapsedDurationSeconds,
        'pointCount': _state.points.length,
        'segmentCount': _state.segments.length,
      },
    );
    _startElapsedTimer();
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

  /// Starts the native recorder, self-healing a stale durable session.
  ///
  /// The native side rejects `start` with
  /// [NativeActivityRecorderChannelContract.errorInvalidState] while its store
  /// still holds a recoverable session. That can be left behind by a start that
  /// failed before any point was collected. Because the recorder never began
  /// collecting, there is nothing to preserve: discard the stale session once
  /// and retry, instead of leaving recording permanently blocked until the
  /// process restarts.
  Future<void> _startRecorder(ActivityRecorderStartRequest request) async {
    try {
      await _recorder.start(request);
    } on PlatformException catch (error) {
      if (error.code !=
          NativeActivityRecorderChannelContract.errorInvalidState) {
        rethrow;
      }
      _recordBreadcrumb(
        DiagnosticsEvents.activityStaleSessionCleared,
        details: {'activityType': request.activityType.name},
      );
      await _recorder.discard();
      await _recorder.start(request);
    }
  }

  void _recordRecorderError(Object error, StackTrace stackTrace) {
    _diagnostics.recordErrorSync(
      error,
      stackTrace,
      source: DiagnosticsSources.activityRecorder,
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
  Future<bool> _finalizeStateFromStore() async {
    try {
      final recordedPoints = await _recorder.drain();
      if (recordedPoints.isEmpty) {
        return true;
      }
      final segments = _segmentsFromRecorded(recordedPoints);
      _lastBreadcrumbPointCount = recordedPoints.length;
      _emit(_state.copyWith(segments: segments));
      return true;
    } catch (error, stackTrace) {
      _recordRecorderError(error, stackTrace);
      return false;
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
      segmentPoints.last.add(_toTrackPointWithSensors(recordedPoint));
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
    _recordBreadcrumb(
      DiagnosticsEvents.activityFailed,
      details: {'reason': errorKey.name, 'pointCount': _state.points.length},
    );
    _emit(
      _state.copyWith(
        status: ActivityRecordingStatus.failed,
        lastError: errorKey,
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
  /// Returns `true` when a non-empty recording was recovered. Active sessions
  /// become paused; completed or failed sessions become completed so their
  /// durable points can be finalized idempotently by the controller.
  Future<bool> recoverActiveSession() async {
    _ensureNotDisposed();
    if (_state.isActive) {
      return false;
    }
    _startRecorderEvents();
    final session = await _recorder.recoverActiveSession();
    if (session == null) {
      return false;
    }
    _localSessionId = session.localSessionId;
    _connectionOrigin = session.connectionOrigin;
    _connectionProfileId = session.connectionProfileId;
    final List<RecordedActivityPoint> recordedPoints;
    try {
      recordedPoints = await _recorder.drain();
    } catch (error, stackTrace) {
      _recordRecorderError(error, stackTrace);
      _emit(
        ActivityRecordingState(
          status: ActivityRecordingStatus.failed,
          activityType: session.activityType,
          startedAt: session.startedAt,
          endedAt: session.endedAt,
          elapsedDurationSeconds: session.elapsedDurationSeconds,
          lastError: ActivityRecordingError.localSaveFailed,
        ),
      );
      return true;
    }
    if (recordedPoints.isEmpty) {
      await _recorder.discard();
      _recordBreadcrumb(
        DiagnosticsEvents.activityActiveSessionRecovered,
        details: {'pointCount': 0, 'recovered': false},
      );
      return false;
    }

    if (session.status == ActiveActivityStatus.completed ||
        session.status == ActiveActivityStatus.failed) {
      return _recoverSession(
        session,
        recordedPoints,
        status: ActivityRecordingStatus.completed,
      );
    }
    if (!session.isActive) {
      return false;
    }
    return _recoverSession(
      session,
      recordedPoints,
      status: ActivityRecordingStatus.paused,
    );
  }

  /// Rebuilds and emits recording state from a recovered durable [session] and
  /// its persisted [recordedPoints].
  ///
  /// A `completed` recovery stamps [ActivityRecordingState.endedAt] (the
  /// session's own end time, or now as a fallback) so the finished activity can
  /// be finalized; a `paused` recovery leaves it unset so recording can resume.
  bool _recoverSession(
    ActiveActivitySession session,
    List<RecordedActivityPoint> recordedPoints, {
    required ActivityRecordingStatus status,
  }) {
    final isCompleted = status == ActivityRecordingStatus.completed;
    _localSessionId = session.localSessionId;
    _connectionOrigin = session.connectionOrigin;
    _connectionProfileId = session.connectionProfileId;
    final segments = _segmentsFromRecorded(recordedPoints);
    _elapsedBeforeCurrentSegmentSeconds = session.elapsedDurationSeconds;
    _recordingSegmentStartedAt = null;
    _lastBreadcrumbPointCount = recordedPoints.length;
    _emit(
      ActivityRecordingState(
        status: status,
        activityType: session.activityType,
        startedAt: session.startedAt,
        endedAt: isCompleted ? (session.endedAt ?? _now()) : null,
        elapsedDurationSeconds: session.elapsedDurationSeconds,
        isAutoPaused: status == ActivityRecordingStatus.paused &&
            session.pausedAutomatically,
        segments: segments,
      ),
    );
    _recordBreadcrumb(
      DiagnosticsEvents.activityActiveSessionRecovered,
      details: {
        'pointCount': recordedPoints.length,
        'segmentCount': segments.length,
        'recovered': true,
        if (isCompleted) 'completed': true,
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
      currentPoints.add(_toTrackPointWithSensors(point));
    }
    if (currentPoints.isNotEmpty) {
      segments.add(ActivityTrackSegment(points: currentPoints));
    }
    return segments;
  }

  ActivityTrackPoint _toTrackPointWithSensors(RecordedActivityPoint point) {
    // Overlay live sensor readings captured this session onto the point,
    // preserving any values the recorder already persisted (e.g. heart rate
    // stamped by the native recorder). Each buffer returns the nearest reading
    // within its freshness window, or null when none is close enough.
    var trackPoint = point.toTrackPoint();
    for (final entry in _sensorBuffers.entries) {
      final value = entry.value.nearest(point.timestamp);
      if (value != null) {
        trackPoint = trackPoint.withSensorValue(entry.key, value);
      }
    }
    return trackPoint;
  }

  void _onSensorReading(RecordedSensorSample sample) {
    // Only buffer while actively recording; readings while idle or paused are
    // not associated with any track point.
    if (_state.status != ActivityRecordingStatus.recording) {
      return;
    }
    _sensorBuffers[sample.kind]!.add(sample.timestamp, sample.value);
    // Surface the live reading immediately so the UI shows a current value even
    // before the next (distance-filtered) GPS point is recorded. The durable
    // per-point value is still stamped from the buffer when points land.
    if (sample.value != _state.currentSensorValue(sample.kind)) {
      _emit(_state.withCurrentSensorValue(sample.kind, sample.value));
    }
  }

  void _ensureNotDisposed() {
    if (_isDisposed) {
      throw StateError('ActivityRecordingService is disposed.');
    }
  }
}
