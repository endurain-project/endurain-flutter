import 'dart:async';

import 'package:endurain/core/diagnostics/diagnostics_service.dart';
import 'package:endurain/core/location/location_service.dart';
import 'package:endurain/core/location/location_settings_builder.dart';
import 'package:endurain/core/utils/id_generation.dart';
import 'package:endurain/core/utils/serial_task_queue.dart';
import 'package:endurain/features/activity/models/active_activity_session.dart';
import 'package:endurain/features/activity/models/activity_recording_error.dart';
import 'package:endurain/features/activity/models/activity_recording_state.dart';
import 'package:endurain/features/activity/models/activity_track_point.dart';
import 'package:endurain/features/activity/models/activity_track_segment.dart';
import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/models/audio_announcement_config.dart';
import 'package:endurain/features/activity/models/recorded_activity_point.dart';
import 'package:endurain/features/activity/models/recorded_sensor_sample.dart';
import 'package:endurain/features/activity/services/activity_location_recorder.dart';
import 'package:endurain/features/activity/services/movement_auto_pause_detector.dart';
import 'package:endurain/features/activity/services/native_activity_recorder_channel.dart';
import 'package:endurain/features/activity/services/recording_elapsed_clock.dart';
import 'package:endurain/features/activity/services/recording_error_resolver.dart';
import 'package:endurain/features/activity/services/recording_sensor_session.dart';
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
    _permissions = RecordingPermissionGate(_locationService);
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

  final StreamController<ActivityRecordingState> _stateController =
      StreamController<ActivityRecordingState>.broadcast();

  ActivityRecordingState _state = ActivityRecordingState();
  StreamSubscription<ActivityRecorderEvent>? _recorderSubscription;
  int _lastBreadcrumbPointCount = 0;
  bool _isDisposed = false;
  BackgroundLocationConfig? _backgroundConfig;
  MovementAutoPauseConfig _autoPauseConfig = const MovementAutoPauseConfig();
  AudioAnnouncementConfig? _audioAnnouncementConfig;
  String? _localSessionId;
  String? _connectionOrigin;
  String? _connectionProfileId;
  Future<bool>? _activeRecovery;
  bool _isRecovering = false;
  final List<ActivityRecorderEvent> _recoveryEvents = [];
  Future<void> _pointEventQueue = Future<void>.value();
  int _nextPointOffset = 0;
  int? _lastRecordedSegmentIndex;

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
    await _activeRecovery;
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
    _clock
      ..reset()
      ..beginSegment(startedAt);
    _lastBreadcrumbPointCount = 0;
    _nextPointOffset = 0;
    _lastRecordedSegmentIndex = null;
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
          autoPauseConfig: _autoPauseConfig,
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

  Future<bool> openAppSettings() {
    return _locationService.openAppSettings();
  }

  Future<bool> isBackgroundTrackingReady() async {
    return await _backgroundTrackingErrorKey() == null;
  }

  Future<bool> requestBackgroundTrackingPermission() => _permissions
      .requestBackground(required: _requiresAppleBackgroundPermission);

  Future<void> pause() => _commands.run(_pause);

  Future<void> _pause() async {
    await _activeRecovery;
    _ensureNotDisposed();
    if (_state.status == ActivityRecordingStatus.paused) {
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

  Future<void> resume() => _commands.run(_resume);

  Future<void> _resume() async {
    await _activeRecovery;
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
        await _backgroundTrackingErrorKey();
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
    await _activeRecovery;
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
    await _activeRecovery;
    _ensureNotDisposed();
    _sensors.stopCapture();
    await _sensors.pendingWrites;
    _clock.reset();
    _lastBreadcrumbPointCount = 0;
    _backgroundConfig = null;
    _audioAnnouncementConfig = null;
    _nextPointOffset = 0;
    _lastRecordedSegmentIndex = null;
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
    _recorderSubscription?.cancel();
    _recorderSubscription = null;
    _sensorSubscription?.cancel();
    _sensorSubscription = null;
    _disposeRecorderWithoutThrow();
    _stateController.close();
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
    if (_isRecovering) {
      _recoveryEvents.add(event);
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
        _pointEventQueue = _pointEventQueue.then(
          (_) => _handlePointBatch(event),
        );
      case ActivityRecorderEventType.failed:
        _fail(recordingErrorForRecorderFailure(event.failureReason));
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
  /// `event.session` over recomputing locally: the recorder timestamps the
  /// pause from the fix that triggered it, which stays correct even if the
  /// Dart isolate's own timer was throttled while backgrounded.
  void _handleAutoPaused(ActivityRecorderEvent event) {
    if (_state.status != ActivityRecordingStatus.recording) {
      return;
    }
    final elapsedDurationSeconds = _clock.freeze(
      elapsedSeconds: event.session?.elapsedDurationSeconds,
    );
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
    _clock.beginSegment(event.session?.resumedAt ?? _now());
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
      if (await _recoverActiveSession()) {
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
      final segments = _segmentsFromRecorded(recordedPoints);
      _lastBreadcrumbPointCount = recordedPoints.length;
      _emit(_state.copyWith(segments: segments));
      return true;
    } catch (error, stackTrace) {
      _recordRecorderError(error, stackTrace);
      return false;
    }
  }

  Future<void> _handlePointBatch(ActivityRecorderEvent event) async {
    final pointOffset = event.pointOffset;
    final sessionId = event.localSessionId;
    if (_isDisposed ||
        _state.status != ActivityRecordingStatus.recording ||
        sessionId != _localSessionId ||
        pointOffset == null ||
        pointOffset < 0) {
      return;
    }
    try {
      if (pointOffset > _nextPointOffset) {
        final offset = _nextPointOffset;
        final points = await _recorder.drain(sinceOffset: offset);
        if (_isDisposed || sessionId != _localSessionId) {
          return;
        }
        _recordRecordedPoints(points, pointOffset: offset);
      }
      if (pointOffset <= _nextPointOffset) {
        _recordRecordedPoints(event.points, pointOffset: pointOffset);
      } else {
        _fail(ActivityRecordingError.localSaveFailed);
      }
    } catch (error, stackTrace) {
      if (!_isDisposed && sessionId == _localSessionId) {
        _recordRecorderError(error, stackTrace);
        _fail(ActivityRecordingError.localSaveFailed);
      }
    }
  }

  void _recordRecordedPoints(
    List<RecordedActivityPoint> points, {
    required int pointOffset,
  }) {
    if (_state.status != ActivityRecordingStatus.recording || points.isEmpty) {
      return;
    }
    final skipCount = _nextPointOffset - pointOffset;
    if (skipCount < 0 || skipCount >= points.length) {
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

    for (final recordedPoint in points.skip(skipCount)) {
      if (_lastRecordedSegmentIndex != recordedPoint.segmentIndex &&
          segmentPoints.last.isNotEmpty) {
        segmentPoints.add(<ActivityTrackPoint>[]);
      }
      segmentPoints.last.add(_toTrackPointWithSensors(recordedPoint));
      _lastRecordedSegmentIndex = recordedPoint.segmentIndex;
    }
    _nextPointOffset = pointOffset + points.length;

    final segments = [
      for (final pts in segmentPoints) ActivityTrackSegment(points: pts),
    ];
    _emit(_state.copyWith(segments: segments));
    _recordPointMilestoneIfNeeded(pointCount: _state.points.length);
  }

  Future<ActivityRecordingError?> _backgroundTrackingErrorKey() => _permissions
      .backgroundError(required: _requiresAppleBackgroundPermission);

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
    final existing = _activeRecovery;
    if (existing != null) {
      return existing;
    }
    if (_state.isActive) {
      return Future.value(false);
    }
    final recovery = _recoverActiveSession().whenComplete(() {
      _activeRecovery = null;
    });
    _activeRecovery = recovery;
    return recovery;
  }

  Future<bool> _recoverActiveSession() async {
    _isRecovering = true;
    _sensors.stopCapture();
    ActiveActivitySession? session;
    try {
      await _sensors.pendingWrites;
      _startRecorderEvents();
      session = await _recorder.recoverActiveSession();
      if (session == null || _isDisposed) {
        return false;
      }
      _localSessionId = session.localSessionId;
      _connectionOrigin = session.connectionOrigin;
      _connectionProfileId = session.connectionProfileId;
      await _sensors.restore();
      final recordedPoints = await _recorder.drain();
      if (_isDisposed) {
        return false;
      }
      final completed =
          session.status == ActiveActivityStatus.completed ||
          session.status == ActiveActivityStatus.stopping;
      if (completed && recordedPoints.isEmpty) {
        await _recorder.discard();
        return false;
      }
      return _recoverSession(
        session,
        recordedPoints,
        status: completed
            ? ActivityRecordingStatus.completed
            : session.status == ActiveActivityStatus.recording
            ? ActivityRecordingStatus.recording
            : ActivityRecordingStatus.paused,
      );
    } catch (error, stackTrace) {
      if (_isDisposed) {
        return false;
      }
      _recordRecorderError(error, stackTrace);
      _emit(
        ActivityRecordingState(
          status: ActivityRecordingStatus.failed,
          activityType: session?.activityType,
          startedAt: session?.startedAt,
          elapsedDurationSeconds: session?.elapsedDurationSeconds ?? 0,
          lastError: ActivityRecordingError.localSaveFailed,
        ),
      );
      return true;
    } finally {
      _isRecovering = false;
      final events = List<ActivityRecorderEvent>.of(_recoveryEvents);
      _recoveryEvents.clear();
      if (!_isDisposed) {
        for (final event in events) {
          _handleRecorderEvent(event);
        }
      }
    }
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
    final isRecording = status == ActivityRecordingStatus.recording;
    _localSessionId = session.localSessionId;
    _connectionOrigin = session.connectionOrigin;
    _connectionProfileId = session.connectionProfileId;
    final segments = _segmentsFromRecorded(recordedPoints);
    _clock.restore(
      elapsedBeforeSeconds: session.elapsedDurationSeconds,
      segmentStartedAt: isRecording
          ? session.resumedAt ?? session.startedAt
          : null,
    );
    _lastBreadcrumbPointCount = recordedPoints.length;
    _nextPointOffset = recordedPoints.length;
    _lastRecordedSegmentIndex = recordedPoints.lastOrNull?.segmentIndex;
    _sensors.startCapture(isRecording ? session.localSessionId : null);
    _emit(
      ActivityRecordingState(
        status: status,
        activityType: session.activityType,
        startedAt: session.startedAt,
        endedAt: isCompleted ? (session.endedAt ?? _now()) : null,
        isAutoPaused:
            status == ActivityRecordingStatus.paused &&
            session.pausedAutomatically,
        elapsedDurationSeconds: _clock.currentSeconds,
        segments: segments,
      ),
    );
    if (isRecording) {
      _startElapsedTimer();
    } else {
      _clock.cancelTicker();
    }
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
    if (points.isEmpty) {
      return [ActivityTrackSegment()];
    }
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
