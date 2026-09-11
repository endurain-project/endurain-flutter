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
import 'package:endurain/features/activity/models/audio_announcement_config.dart';
import 'package:endurain/features/activity/models/recorded_activity_point.dart';
import 'package:endurain/features/activity/models/recorded_sensor_sample.dart';
import 'package:endurain/features/activity/services/activity_location_recorder.dart';
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
    _recordingSegmentStartedAt = startedAt;
    _elapsedBeforeCurrentSegmentSeconds = 0;
    _lastBreadcrumbPointCount = 0;
    _nextPointOffset = 0;
    _lastRecordedSegmentIndex = null;
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
          audioAnnouncementConfig: _audioAnnouncementConfig,
          heartRateDeviceId: sensorDeviceIds[RecordedSensorKind.heartRate],
          powerDeviceId: sensorDeviceIds[RecordedSensorKind.power],
          cadenceDeviceId: sensorDeviceIds[RecordedSensorKind.cadence],
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
    await _activeRecovery;
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
        await _locationErrorKey() ?? await _backgroundTrackingErrorKey();
    if (_isDisposed ||
        _state.status != ActivityRecordingStatus.paused ||
        sessionId != _localSessionId) {
      return;
    }
    if (locationError != null) {
      _emit(_state.copyWith(lastError: locationError));
      return;
    }

    _recordingSegmentStartedAt = _now();
    _emit(
      _state.startNewSegment().copyWith(
        status: ActivityRecordingStatus.recording,
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
    await _runRecorderCommand(
      _recorder.resume,
      ActivityRecordingError.localSaveFailed,
    );
  }

  Future<void> stop() async {
    await _activeRecovery;
    _ensureNotDisposed();
    if (_state.status == ActivityRecordingStatus.failed) {
      await _recoverFailedSession();
    }
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
    await _activeRecovery;
    _ensureNotDisposed();
    _cancelElapsedTimer();
    _recordingSegmentStartedAt = null;
    _elapsedBeforeCurrentSegmentSeconds = 0;
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
    final elapsedDurationSeconds = _currentElapsedDurationSeconds();
    _elapsedBeforeCurrentSegmentSeconds = elapsedDurationSeconds;
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
    ActiveActivitySession? session;
    try {
      _startRecorderEvents();
      session = await _recorder.recoverActiveSession();
      if (session == null || _isDisposed) {
        return false;
      }
      _localSessionId = session.localSessionId;
      _connectionOrigin = session.connectionOrigin;
      _connectionProfileId = session.connectionProfileId;
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
    _elapsedBeforeCurrentSegmentSeconds = session.elapsedDurationSeconds;
    _recordingSegmentStartedAt = isRecording
        ? session.resumedAt ?? session.startedAt
        : null;
    _lastBreadcrumbPointCount = recordedPoints.length;
    _nextPointOffset = recordedPoints.length;
    _lastRecordedSegmentIndex = recordedPoints.lastOrNull?.segmentIndex;
    _emit(
      ActivityRecordingState(
        status: status,
        activityType: session.activityType,
        startedAt: session.startedAt,
        endedAt: isCompleted ? (session.endedAt ?? _now()) : null,
        elapsedDurationSeconds: _currentElapsedDurationSeconds(),
        segments: segments,
      ),
    );
    if (isRecording) {
      _startElapsedTimer();
    } else {
      _cancelElapsedTimer();
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
