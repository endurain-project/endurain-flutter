import 'dart:async';

import 'package:endurain/core/diagnostics/diagnostics_service.dart';
import 'package:endurain/core/location/location_service.dart';
import 'package:endurain/core/location/location_settings_builder.dart';
import 'package:endurain/core/utils/id_generation.dart';
import 'package:endurain/core/utils/serial_task_queue.dart';
import 'package:endurain/features/activity/models/activity_recording_error.dart';
import 'package:endurain/features/activity/models/activity_recording_state.dart';
import 'package:endurain/features/activity/models/activity_track_point.dart';
import 'package:endurain/features/activity/models/activity_track_segment.dart';
import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/models/audio_announcement_config.dart';
import 'package:endurain/features/activity/models/recorded_activity_point.dart';
import 'package:endurain/features/activity/models/recorded_sensor_sample.dart';
import 'package:endurain/features/activity/services/activity_location_recorder.dart';
import 'package:endurain/features/activity/services/movement_auto_pause_config.dart';
import 'package:endurain/features/activity/services/native_activity_recorder_channel.dart';
import 'package:endurain/features/activity/services/recording_auto_pause_coordinator.dart';
import 'package:endurain/features/activity/services/recording_elapsed_clock.dart';
import 'package:endurain/features/activity/services/recording_permission_gate.dart';
import 'package:endurain/features/activity/services/recording_point_batcher.dart';
import 'package:endurain/features/activity/services/recording_sensor_session.dart';
import 'package:endurain/features/activity/services/recording_session_recovery.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;

class ActivityRecordingService {
  ActivityRecordingService({
    required ActivityLocationRecorder recorder,
    DateTime Function()? now,
    DiagnosticsRecorder? diagnostics,
    LocationService? locationService,
    Stream<RecordedSensorSample>? sensorReadings,
    ActivitySensorRecorder? sensorRecorder,
    Map<RecordedSensorKind, Future<String?> Function()> prepareSensorSources =
        const {},
    Duration sensorFreshness = const Duration(seconds: 10),
  }) : _recorder = recorder,
       _sensorRecorder = sensorRecorder,
       _now = now ?? DateTime.now,
       _diagnostics = diagnostics ?? const NoopDiagnosticsRecorder(),
       _locationService = locationService ?? LocationService(),
       _sensorFreshness = sensorFreshness,
       _prepareSensorSources = prepareSensorSources {
    _clock = RecordingElapsedClock(_now);
    _permissions = RecordingPermissionGate(
      _locationService,
      requiresBackground: () => _requiresAppleBackgroundPermission,
    );
    _sensorSubscription = sensorReadings?.listen(_sensors.onReading);
  }

  final DateTime Function() _now;
  final DiagnosticsRecorder _diagnostics;
  final LocationService _locationService;
  final ActivityLocationRecorder _recorder;
  final ActivitySensorRecorder? _sensorRecorder;
  final Duration _sensorFreshness;
  final SerialTaskQueue _commands = SerialTaskQueue();

  /// Resolves each paired sensor's device id for the native recorder (and frees
  /// the Dart-side BLE connection) at recording start, keyed by sensor kind.
  /// Empty when native sensor capture is not in use (e.g. iOS keeps the Dart
  /// BLE connection and streams readings in instead).
  final Map<RecordedSensorKind, Future<String?> Function()>
  _prepareSensorSources;

  late final RecordingElapsedClock _clock;
  late final RecordingPermissionGate _permissions;

  late final RecordingPointBatcher _batcher = RecordingPointBatcher(
    recorder: _recorder,
    toTrackPoint: _toTrackPointWithSensors,
    readState: () => _state,
    emit: _emit,
    isCurrentSession: (sessionId) =>
        !_isDisposed && sessionId == _localSessionId,
    onSaveFailed: (error, stackTrace) {
      _recordRecorderError(error, stackTrace);
      _fail(ActivityRecordingError.localSaveFailed);
    },
    onSaveGap: () => _fail(ActivityRecordingError.localSaveFailed),
    onApplied: (pointCount) =>
        _recordPointMilestoneIfNeeded(pointCount: pointCount),
  );

  late final RecordingSessionRecovery _recovery = RecordingSessionRecovery(
    recorder: _recorder,
    sensors: _sensors,
    clock: _clock,
    batcher: _batcher,
    diagnostics: _diagnostics,
    now: _now,
    isDisposed: () => _isDisposed,
    startRecorderEvents: _startRecorderEvents,
    adoptSession: (session) {
      _localSessionId = session.localSessionId;
      _connectionOrigin = session.connectionOrigin;
      _connectionProfileId = session.connectionProfileId;
    },
    emit: _emit,
    startElapsedTimer: _startElapsedTimer,
    onPointsRestored: (count) => _lastBreadcrumbPointCount = count,
    replayEvent: _handleRecorderEvent,
  );

  /// Persists and buffers sensor readings so the nearest one can be stamped
  /// onto each track point.
  late final RecordingSensorSession _sensors = RecordingSensorSession(
    recorder: _sensorRecorder,
    freshness: _sensorFreshness,
    activeSessionId: () => _localSessionId,
    isRecording: () => _state.status == ActivityRecordingStatus.recording,
    isDisposed: () => _isDisposed,
    onWriteFailed: (error, stackTrace) {
      _recordRecorderError(error, stackTrace);
      _fail(ActivityRecordingError.localSaveFailed);
    },
    onSampleRecorded: _onSensorSampleRecorded,
  );
  StreamSubscription<RecordedSensorSample>? _sensorSubscription;

  late final RecordingAutoPauseCoordinator _autoPause =
      RecordingAutoPauseCoordinator(
        sensors: _sensors,
        clock: _clock,
        now: _now,
        readState: () => _state,
        emit: _emit,
        localSessionId: () => _localSessionId,
        startElapsedTimer: _startElapsedTimer,
        recordBreadcrumb: _recordBreadcrumb,
      );

  final StreamController<ActivityRecordingState> _stateController =
      StreamController<ActivityRecordingState>.broadcast();

  ActivityRecordingState _state = ActivityRecordingState();
  StreamSubscription<ActivityRecorderEvent>? _recorderSubscription;
  int _lastBreadcrumbPointCount = 0;
  bool _isDisposed = false;
  BackgroundLocationConfig? _backgroundConfig;
  AudioAnnouncementConfig? _audioAnnouncementConfig;
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
    _autoPause.config = config;
  }

  /// Supplies the localized spoken-announcement configuration used by the
  /// native recorder for the next `start` call. Rebuilt on every UI frame by
  /// the caller (locale/unit/settings may change), so this is a cheap setter,
  /// not a start of anything by itself.
  void configureAudioAnnouncements(AudioAnnouncementConfig config) {
    _audioAnnouncementConfig = config;
  }

  Future<void> start({
    required ActivityType activityType,
    BackgroundLocationConfig? backgroundConfig,
    AudioAnnouncementConfig? audioAnnouncementConfig,
    String? localSessionId,
    String? connectionOrigin,
    String? connectionProfileId,
  }) => _commands.run(
    () => _start(
      activityType: activityType,
      backgroundConfig: backgroundConfig,
      audioAnnouncementConfig: audioAnnouncementConfig,
      localSessionId: localSessionId,
      connectionOrigin: connectionOrigin,
      connectionProfileId: connectionProfileId,
    ),
  );

  Future<void> _start({
    required ActivityType activityType,
    BackgroundLocationConfig? backgroundConfig,
    AudioAnnouncementConfig? audioAnnouncementConfig,
    String? localSessionId,
    String? connectionOrigin,
    String? connectionProfileId,
  }) async {
    await _recovery.pending;
    _ensureNotDisposed();
    if (_state.status == ActivityRecordingStatus.failed &&
        _localSessionId != null) {
      await _recoverFailedSession();
      if (_state.status != ActivityRecordingStatus.idle) {
        return;
      }
    }
    if (_state.isActive || _state.status == ActivityRecordingStatus.stopping) {
      return;
    }

    _recordBreadcrumb(
      DiagnosticsEvents.activityStartRequested,
      details: {'activityType': activityType.name},
    );
    final locationErrorKey = await _permissions.locationError();
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
    if (audioAnnouncementConfig != null) {
      _audioAnnouncementConfig = audioAnnouncementConfig;
    }
    final backgroundErrorKey = await _permissions.backgroundTrackingError();
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
    _clock
      ..reset()
      ..beginSegment(startedAt);
    _lastBreadcrumbPointCount = 0;
    _batcher.reset();
    _sensors.reset();
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
          audioAnnouncementConfig: _audioAnnouncementConfig,
          heartRateDeviceId: sensorDeviceIds[RecordedSensorKind.heartRate],
          powerDeviceId: sensorDeviceIds[RecordedSensorKind.power],
          cadenceDeviceId: sensorDeviceIds[RecordedSensorKind.cadence],
          autoPauseConfig: _autoPause.config,
        ),
      );
      if (!_isDisposed && _state.status == ActivityRecordingStatus.recording) {
        _sensors.startCapture(_localSessionId);
      }
    } catch (error, stackTrace) {
      _diagnostics.recordErrorSync(
        error,
        stackTrace,
        source: DiagnosticsSources.activityRecorder,
      );
      _fail(
        error is PlatformException &&
                error.code ==
                    NativeActivityRecorderChannelContract.errorStoreWriteFailed
            ? ActivityRecordingError.localSaveFailed
            : ActivityRecordingError.locationStreamFailed,
      );
    }
  }

  Future<bool> openAppSettings() => _permissions.openAppSettings();

  Future<bool> isBackgroundTrackingReady() => _permissions.isBackgroundReady();

  Future<bool> requestBackgroundTrackingPermission() =>
      _permissions.requestBackgroundPermission();

  /// Whether location is on and permitted, asking for permission first when
  /// it was never decided. Lets the start countdown settle the permission
  /// prompt before the user puts the phone away.
  Future<bool> isLocationReady() => _permissions.isLocationReady();

  Future<void> pause() => _commands.run(_pause);

  Future<void> _pause() async {
    await _recovery.pending;
    _ensureNotDisposed();
    if (_state.status == ActivityRecordingStatus.paused) {
      if (_state.isAutoPaused) {
        await _convertAutoPauseToManual();
      }
      return;
    }
    if (_state.status != ActivityRecordingStatus.recording) {
      _failInvalidTransition();
      return;
    }

    _sensors.stopCapture();
    final elapsedDurationSeconds = _clock.freeze();
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
    if (!await _sensors.flush()) {
      return;
    }
    await _runRecorderCommand(
      _recorder.pause,
      ActivityRecordingError.localSaveFailed,
    );
  }

  /// Turns an auto-pause into a manual one when the user pauses while the
  /// recorder has already paused on its own. The recorder is paused explicitly
  /// so it stops monitoring movement and can no longer auto-resume.
  Future<void> _convertAutoPauseToManual() async {
    _emit(_state.copyWith(isAutoPaused: false));
    _recordBreadcrumb(
      DiagnosticsEvents.activityPaused,
      details: {
        'elapsedSeconds': _state.elapsedDurationSeconds,
        'pointCount': _state.points.length,
        'segmentCount': _state.segments.length,
      },
    );
    await _runRecorderCommand(
      _recorder.pause,
      ActivityRecordingError.localSaveFailed,
    );
  }

  Future<void> resume() => _commands.run(_resume);

  Future<void> _resume() async {
    await _recovery.pending;
    _ensureNotDisposed();
    if (_state.status == ActivityRecordingStatus.failed) {
      await _recoverFailedSession();
      if (!_state.isActive) {
        return;
      }
    }
    if (_state.status == ActivityRecordingStatus.recording) {
      return;
    }
    if (_state.status != ActivityRecordingStatus.paused) {
      _failInvalidTransition();
      return;
    }

    final sessionId = _localSessionId;
    final locationError =
        await _permissions.locationError() ??
        await _permissions.backgroundTrackingError();
    if (_isDisposed ||
        _state.status != ActivityRecordingStatus.paused ||
        sessionId != _localSessionId) {
      return;
    }
    if (locationError != null) {
      _emit(_state.copyWith(lastError: locationError));
      return;
    }

    _clock.beginSegment(_now());
    _emit(
      _state.startNewSegment().copyWith(
        status: ActivityRecordingStatus.recording,
        isAutoPaused: false,
        lastError: null,
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
    final resumed = await _runRecorderCommand(
      _recorder.resume,
      ActivityRecordingError.localSaveFailed,
    );
    if (resumed &&
        !_isDisposed &&
        _state.status == ActivityRecordingStatus.recording) {
      _sensors.startCapture(_localSessionId);
    }
  }

  Future<void> stop() => _commands.run(_stop);

  Future<void> _stop() async {
    await _recovery.pending;
    _ensureNotDisposed();
    if (_state.status == ActivityRecordingStatus.failed) {
      await _recoverFailedSession();
    }
    if (!_state.isActive) {
      return;
    }

    _sensors.stopCapture();
    final elapsedDurationSeconds = _clock.freeze();

    _emit(
      _state.copyWith(
        status: ActivityRecordingStatus.stopping,
        elapsedDurationSeconds: elapsedDurationSeconds,
      ),
    );
    if (!await _sensors.flush()) {
      return;
    }
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

  Future<void> discard() => _commands.run(_discard);

  Future<void> _discard() async {
    await _recovery.pending;
    _ensureNotDisposed();
    _sensors.stopCapture();
    await _sensors.pendingWrites;
    _clock.reset();
    _lastBreadcrumbPointCount = 0;
    _backgroundConfig = null;
    _audioAnnouncementConfig = null;
    _batcher.reset();
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
    _sensors.reset();
    _emit(ActivityRecordingState());
    _recordBreadcrumb(DiagnosticsEvents.activityDiscarded);
  }

  /// Clears the durable recorder session after the completed activity has
  /// been committed to local GPX and metadata storage.
  Future<void> acknowledgeFinalized() => _commands.run(_acknowledgeFinalized);

  Future<void> _acknowledgeFinalized() async {
    _ensureNotDisposed();
    _sensors.stopCapture();
    await _sensors.pendingWrites;
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
    _clock.cancelTicker();
    unawaited(_recorderSubscription?.cancel());
    _recorderSubscription = null;
    unawaited(_sensorSubscription?.cancel());
    _sensorSubscription = null;
    _disposeRecorderWithoutThrow();
    unawaited(_stateController.close());
  }

  void _startElapsedTimer() => _clock.startTicker(_onElapsedTick);

  void _onElapsedTick() {
    if (_state.status != ActivityRecordingStatus.recording) {
      return;
    }
    final elapsedDurationSeconds = _clock.currentSeconds;
    if (elapsedDurationSeconds == _state.elapsedDurationSeconds) {
      return;
    }
    _emit(_state.copyWith(elapsedDurationSeconds: elapsedDurationSeconds));
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
    if (_recovery.buffer(event)) {
      return;
    }
    switch (event.type) {
      case ActivityRecorderEventType.started:
      case ActivityRecorderEventType.paused:
      case ActivityRecorderEventType.resumed:
      case ActivityRecorderEventType.stopped:
      case ActivityRecorderEventType.recoverableStateChanged:
        break;
      case ActivityRecorderEventType.pointBatchAvailable:
        _batcher.enqueue(event);
      case ActivityRecorderEventType.failed:
        _fail(recordingErrorForRecorderFailure(event.failureReason));
      case ActivityRecorderEventType.autoPaused:
      case ActivityRecorderEventType.autoResumed:
        _autoPause.handle(event);
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

  /// Recovers an existing session when native start rejects replacement.
  /// Only clears stale artifacts after confirming no session or points remain.
  Future<void> _startRecorder(ActivityRecorderStartRequest request) async {
    try {
      await _recorder.start(request);
    } on PlatformException catch (error) {
      if (error.code !=
          NativeActivityRecorderChannelContract.errorInvalidState) {
        rethrow;
      }
      if (await _recovery.recoverNow()) {
        return;
      }
      if ((await _recorder.drain()).isNotEmpty) {
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
    unawaited(_recorder.dispose().catchError(_recordRecorderError));
  }

  /// Rebuilds the in-memory recording state from the durable store before
  /// completion so points persisted while the app was backgrounded (with a
  /// detached event sink) are included in the finalized activity.
  Future<bool> _finalizeStateFromStore() async {
    try {
      await _sensors.restore();
      final recordedPoints = await _recorder.drain();
      if (recordedPoints.isEmpty) {
        return true;
      }
      final segments = _batcher.segmentsFromRecorded(recordedPoints);
      _lastBreadcrumbPointCount = recordedPoints.length;
      _emit(_state.copyWith(segments: segments));
      return true;
    } catch (error, stackTrace) {
      _recordRecorderError(error, stackTrace);
      return false;
    }
  }

  bool get _requiresAppleBackgroundPermission {
    return _backgroundConfig != null &&
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  void _failInvalidTransition() {
    _fail(ActivityRecordingError.invalidTransition);
  }

  void _fail(ActivityRecordingError errorKey) {
    _sensors.stopCapture();
    final elapsedDurationSeconds = _clock.freeze();
    _recordBreadcrumb(
      DiagnosticsEvents.activityFailed,
      details: {'reason': errorKey.name, 'pointCount': _state.points.length},
    );
    _emit(
      _state.copyWith(
        status: ActivityRecordingStatus.failed,
        lastError: errorKey,
        elapsedDurationSeconds: elapsedDurationSeconds,
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

  Future<void> _recoverFailedSession() async {
    if (!await recoverActiveSession() && !_isDisposed) {
      _localSessionId = null;
      _connectionOrigin = null;
      _connectionProfileId = null;
      _emit(ActivityRecordingState());
    }
  }

  /// Attempts to restore a recoverable active recording from the recorder.
  ///
  /// Live and paused sessions retain their status, including sessions waiting
  /// for their first fix. Only an explicitly stopped session is finalized.
  Future<bool> recoverActiveSession() {
    _ensureNotDisposed();
    return _recovery.recover(isActive: _state.isActive);
  }

  ActivityTrackPoint _toTrackPointWithSensors(RecordedActivityPoint point) =>
      _sensors.overlay(point.toTrackPoint(), point.timestamp);

  void _onSensorSampleRecorded(RecordedSensorSample sample) {
    // Surface the live reading immediately so the UI shows a current value even
    // before the next (distance-filtered) GPS point is recorded. The durable
    // per-point value is still stamped from the buffer when points land.
    if (_state.status == ActivityRecordingStatus.recording &&
        sample.value != _state.currentSensorValue(sample.kind)) {
      _emit(_state.withCurrentSensorValue(sample.kind, sample.value));
    }
  }

  void _ensureNotDisposed() {
    if (_isDisposed) {
      throw StateError('ActivityRecordingService is disposed.');
    }
  }
}
