import 'dart:async';

import 'package:endurain/core/services/diagnostics_service.dart';
import 'package:endurain/core/services/location_service.dart';
import 'package:endurain/core/services/location_settings_builder.dart';
import 'package:endurain/features/activity/models/active_activity_session.dart';
import 'package:endurain/features/activity/models/activity_track_point.dart';
import 'package:endurain/features/activity/models/recorded_activity_point.dart';
import 'package:endurain/features/activity/repositories/active_activity_store.dart';
import 'package:endurain/features/activity/services/activity_location_recorder.dart';
import 'package:endurain/features/activity/services/activity_segment_policy.dart';
import 'package:endurain/features/activity/services/movement_auto_pause_detector.dart';
import 'package:geolocator/geolocator.dart';

/// Foreground/fallback [ActivityLocationRecorder] backed by the `geolocator`
/// position stream.
///
/// Every received point is persisted to the [ActiveActivityStore] before it is
/// emitted to Flutter, so the Dart isolate is never the only owner of active
/// recording data. This adapter remains the development and unsupported-platform
/// implementation; the production mobile recorder is native and background
/// capable.
class GeolocatorActivityLocationRecorder implements ActivityLocationRecorder {
  GeolocatorActivityLocationRecorder({
    required this._store,
    LocationService? locationService,
    this._segmentPolicy = const ActivitySegmentPolicy(),
    DiagnosticsRecorder? diagnostics,
    DateTime Function()? now,
  }) : _locationService = locationService ?? LocationService(),
       _diagnostics = diagnostics ?? const NoopDiagnosticsRecorder(),
       _now = now ?? DateTime.now;

  final ActiveActivityStore _store;
  final LocationService _locationService;
  final ActivitySegmentPolicy _segmentPolicy;
  final DiagnosticsRecorder _diagnostics;
  final DateTime Function() _now;

  final StreamController<ActivityRecorderEvent> _eventController =
      StreamController<ActivityRecorderEvent>.broadcast();

  StreamSubscription<Position>? _positionSubscription;
  Future<void> _positionQueue = Future<void>.value();
  ActiveActivitySession? _session;
  BackgroundLocationConfig? _backgroundConfig;
  RecordedActivityPoint? _lastPoint;
  bool _resumedFromPause = false;
  bool _disposed = false;
  MovementAutoPauseDetector? _autoPauseDetector;

  @override
  Stream<ActivityRecorderEvent> get events => _eventController.stream;

  @override
  Future<void> start(ActivityRecorderStartRequest request) async {
    await _waitForPendingPositions();
    if (await _store.loadSession() != null) {
      throw StateError('A recoverable activity session already exists.');
    }
    final autoPauseConfig = request.autoPauseConfig;
    final session = ActiveActivitySession(
      localSessionId: request.localSessionId,
      activityType: request.activityType,
      status: ActiveActivityStatus.recording,
      startedAt: request.startedAt,
      connectionOrigin: request.connectionOrigin,
      connectionProfileId: request.connectionProfileId,
      heartRateDeviceId: request.heartRateDeviceId,
      powerDeviceId: request.powerDeviceId,
      cadenceDeviceId: request.cadenceDeviceId,
      autoPauseEnabled: autoPauseConfig.enabled,
      autoPauseDelaySeconds: autoPauseConfig.pauseDelay.inSeconds,
    );
    _session = session;
    _backgroundConfig = request.backgroundConfig;
    _lastPoint = null;
    _resumedFromPause = false;
    _autoPauseDetector = MovementAutoPauseDetector(config: autoPauseConfig)
      ..reset(movementAt: request.startedAt);
    await _store.saveSession(session);
    _emit(ActivityRecorderEvent.started(session));
    _diagnostics.recordBreadcrumbSync(
      DiagnosticsEvents.activityRecorderStarted,
      details: {'activityType': request.activityType.name},
    );
    _startStream();
  }

  @override
  Future<void> pause() async {
    final session = _session;
    if (session == null) {
      return;
    }
    await _cancelStream();
    await _waitForPendingPositions();
    final pausedAt = _now();
    final paused = session.copyWith(
      status: ActiveActivityStatus.paused,
      elapsedDurationSeconds: _elapsedDurationSeconds(session, pausedAt),
      pausedAt: pausedAt,
      pausedAutomatically: false,
    );
    _session = paused;
    // A manual pause always stops the stream above, so no further positions
    // can reach the detector until a manual resume; reset defensively so
    // stale movement history from before this pause can never leak into a
    // later segment.
    _autoPauseDetector?.reset();
    await _store.saveSession(paused);
    _emit(ActivityRecorderEvent.paused(paused));
    _diagnostics.recordBreadcrumbSync(
      DiagnosticsEvents.activityRecorderPaused,
      details: {'segmentIndex': paused.currentSegmentIndex},
    );
  }

  @override
  Future<void> resume() async {
    final session = _session;
    if (session == null) {
      return;
    }
    await _waitForPendingPositions();
    _resumedFromPause = true;
    final resumedAt = _now();
    final resumed = session.copyWith(
      status: ActiveActivityStatus.recording,
      resumedAt: resumedAt,
      pausedAt: null,
      pausedAutomatically: false,
    );
    _session = resumed;
    _autoPauseDetector?.reset(movementAt: resumedAt);
    await _store.saveSession(resumed);
    _emit(ActivityRecorderEvent.resumed(resumed));
    _diagnostics.recordBreadcrumbSync(
      DiagnosticsEvents.activityRecorderResumed,
      details: {'segmentIndex': resumed.currentSegmentIndex},
    );
    _startStream();
  }

  @override
  Future<void> stop() async {
    final session = _session;
    if (session == null) {
      return;
    }
    await _cancelStream();
    await _waitForPendingPositions();
    final endedAt = _now();
    final completed = session.copyWith(
      status: ActiveActivityStatus.completed,
      elapsedDurationSeconds: _elapsedDurationSeconds(session, endedAt),
      endedAt: endedAt,
    );
    _session = completed;
    await _store.complete(completed);
    _emit(ActivityRecorderEvent.stopped(completed));
    _diagnostics.recordBreadcrumbSync(
      DiagnosticsEvents.activityRecorderStopped,
      details: {'segmentCount': completed.currentSegmentIndex + 1},
    );
  }

  @override
  Future<void> discard() async {
    await _cancelStream();
    await _waitForPendingPositions();
    _session = null;
    _lastPoint = null;
    _resumedFromPause = false;
    _backgroundConfig = null;
    _autoPauseDetector = null;
    await _store.clear();
    _emit(const ActivityRecorderEvent.recoverableStateChanged(null));
  }

  @override
  Future<List<RecordedActivityPoint>> drain({int sinceOffset = 0}) async {
    await _waitForPendingPositions();
    final points = await _store.readPoints(sinceOffset: sinceOffset);
    _diagnostics.recordBreadcrumbSync(
      DiagnosticsEvents.activityPointBatchDrained,
      details: {'pointCount': points.length, 'sinceOffset': sinceOffset},
    );
    return points;
  }

  @override
  Future<ActiveActivitySession?> recoverActiveSession() async {
    await _waitForPendingPositions();
    final session = await _store.loadSession();
    _session = session;
    if (session != null) {
      _resumedFromPause = false;
      final points = await _store.readPoints();
      _lastPoint = points.isEmpty ? null : points.last;
      // Rebuild the detector from the session's own snapshotted config (not
      // whatever the current app preference is) so a recovered recording keeps
      // behaving the way it did when it started.
      _autoPauseDetector = MovementAutoPauseDetector(
        config: MovementAutoPauseConfig(
          enabled: session.autoPauseEnabled,
          pauseDelay: Duration(seconds: session.autoPauseDelaySeconds),
        ),
      )..reset(movementAt: _lastPoint?.timestamp ?? _now());
    }
    _emit(ActivityRecorderEvent.recoverableStateChanged(session));
    return session;
  }

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    await _waitForPendingPositions();
    await _eventController.close();
  }

  void _startStream() {
    if (_positionSubscription != null) {
      return;
    }
    try {
      _positionSubscription = _locationService
          .getPositionStream(
            background: _backgroundConfig,
            distanceFilter: LocationDistanceFilters.recordingMeters,
          )
          .listen(_onPosition, onError: _onStreamError);
    } catch (error, stackTrace) {
      _diagnostics.recordErrorSync(
        error,
        stackTrace,
        source: DiagnosticsSources.activityRecorder,
      );
      _emit(
        const ActivityRecorderEvent.failed(
          ActivityRecorderFailureReason.locationStreamFailed,
        ),
      );
    }
  }

  Future<void> _cancelStream() async {
    final subscription = _positionSubscription;
    _positionSubscription = null;
    await subscription?.cancel();
  }

  void _onPosition(Position position) {
    _positionQueue = _positionQueue
        .then((_) => _handlePosition(position))
        .catchError(_handlePositionError);
  }

  Future<void> _handlePosition(Position position) async {
    if (_disposed) {
      return;
    }
    final session = _session;
    if (session == null) {
      return;
    }
    if (session.status == ActiveActivityStatus.paused) {
      // A manual pause cancels the stream entirely (see `pause()`), so only
      // an auto-paused session can still be receiving positions here. This
      // guard also protects against a stray in-flight position delivered
      // just as a manual pause took effect.
      if (session.pausedAutomatically) {
        await _handleAutoPausedPosition(session, position);
      }
      return;
    }
    if (session.status != ActiveActivityStatus.recording) {
      return;
    }
    await _handleActivePosition(session, position);
  }

  Future<void> _handleActivePosition(
    ActiveActivitySession session,
    Position position,
  ) async {
    final trackPoint = ActivityTrackPoint.fromPosition(position);
    var segmentIndex = session.currentSegmentIndex;
    final candidate = RecordedActivityPoint.fromTrackPoint(
      trackPoint,
      segmentIndex: segmentIndex,
    );

    // Feed the auto-pause detector before the accuracy gate below, so
    // stillness timing advances from wall-clock progress on every fix
    // (including noisy ones the detector itself discounts as movement
    // evidence), matching the native recorders.
    final autoPauseTransition =
        _autoPauseDetector?.onActivePoint(candidate) ??
        MovementAutoPauseTransition.none;
    if (autoPauseTransition == MovementAutoPauseTransition.autoPause) {
      await _transitionToAutoPaused(session, at: candidate.timestamp);
      return;
    }

    // Drop low-accuracy fixes before they enter the track, matching the native
    // recorder. This removes "ghost" points from coarse providers rather than
    // merely splitting them into a new segment.
    final accuracy = trackPoint.horizontalAccuracyMeters;
    if (accuracy != null && accuracy > _segmentPolicy.maxAccuracyMeters) {
      return;
    }
    final decision = _segmentPolicy.evaluate(
      previous: _lastPoint,
      next: candidate,
      resumedFromPause: _resumedFromPause,
    );
    _resumedFromPause = false;
    if (decision.requiresNewSegment && _lastPoint != null) {
      _recordTrackingStall(decision, previous: _lastPoint!, next: candidate);
      segmentIndex += 1;
    }
    final point = segmentIndex == candidate.segmentIndex
        ? candidate
        : RecordedActivityPoint.fromTrackPoint(
            trackPoint,
            segmentIndex: segmentIndex,
          );

    try {
      await _store.appendPoints([point]);
    } catch (error, stackTrace) {
      _diagnostics.recordErrorSync(
        error,
        stackTrace,
        source: DiagnosticsSources.activityRecorder,
      );
      _emit(
        const ActivityRecorderEvent.failed(
          ActivityRecorderFailureReason.persistenceFailed,
        ),
      );
      return;
    }

    if (segmentIndex != session.currentSegmentIndex) {
      final updated = session.copyWith(currentSegmentIndex: segmentIndex);
      _session = updated;
      await _store.saveSession(updated);
    }
    _lastPoint = point;
    _emit(ActivityRecorderEvent.pointBatchAvailable([point]));
  }

  /// Feeds a position received while auto-paused. The recorder keeps
  /// monitoring (the stream is never cancelled for an automatic pause) so
  /// movement can resume the recording without user interaction, but no point
  /// is persisted until hysteresis confirms movement has resumed.
  Future<void> _handleAutoPausedPosition(
    ActiveActivitySession session,
    Position position,
  ) async {
    final detector = _autoPauseDetector;
    if (detector == null) {
      return;
    }
    final trackPoint = ActivityTrackPoint.fromPosition(position);
    final candidate = RecordedActivityPoint.fromTrackPoint(
      trackPoint,
      segmentIndex: session.currentSegmentIndex,
    );
    final transition = detector.onAutoPausedPoint(candidate);
    if (transition != MovementAutoPauseTransition.autoResume) {
      return;
    }

    final resumedAt = candidate.timestamp;
    final resumed = session.copyWith(
      status: ActiveActivityStatus.recording,
      resumedAt: resumedAt,
      pausedAt: null,
      pausedAutomatically: false,
    );
    _session = resumed;
    _resumedFromPause = true;
    await _store.saveSession(resumed);
    _emit(ActivityRecorderEvent.autoResumed(resumed));
    _diagnostics.recordBreadcrumbSync(
      DiagnosticsEvents.activityRecorderAutoResumed,
      details: {'segmentIndex': resumed.currentSegmentIndex},
    );
    // Persist this same triggering fix as the first point of the new segment,
    // matching the manual resume flow (`_resumedFromPause` forces a segment
    // break in the shared segment policy).
    await _handleActivePosition(resumed, position);
  }

  Future<void> _transitionToAutoPaused(
    ActiveActivitySession session, {
    required DateTime at,
  }) async {
    final paused = session.copyWith(
      status: ActiveActivityStatus.paused,
      elapsedDurationSeconds: _elapsedDurationSeconds(session, at),
      pausedAt: at,
      pausedAutomatically: true,
    );
    _session = paused;
    await _store.saveSession(paused);
    _emit(ActivityRecorderEvent.autoPaused(paused));
    _diagnostics.recordBreadcrumbSync(
      DiagnosticsEvents.activityRecorderAutoPaused,
      details: {'segmentIndex': paused.currentSegmentIndex},
    );
  }

  Future<void> _waitForPendingPositions() => _positionQueue;

  void _handlePositionError(Object error, StackTrace stackTrace) {
    _diagnostics.recordErrorSync(
      error,
      stackTrace,
      source: DiagnosticsSources.activityRecorder,
    );
    _emit(
      const ActivityRecorderEvent.failed(
        ActivityRecorderFailureReason.persistenceFailed,
      ),
    );
  }

  void _onStreamError(Object error, StackTrace stackTrace) {
    _diagnostics.recordErrorSync(
      error,
      stackTrace,
      source: DiagnosticsSources.activityRecorder,
    );
    _emit(
      const ActivityRecorderEvent.failed(
        ActivityRecorderFailureReason.locationStreamFailed,
      ),
    );
  }

  void _emit(ActivityRecorderEvent event) {
    if (_disposed || _eventController.isClosed) {
      return;
    }
    _eventController.add(event);
  }

  void _recordTrackingStall(
    ActivitySegmentDecision decision, {
    required RecordedActivityPoint previous,
    required RecordedActivityPoint next,
  }) {
    if (!_isTrackingStallReason(decision.reason)) {
      return;
    }
    final gapSeconds = next.timestamp.difference(previous.timestamp).inSeconds;
    _diagnostics.recordBreadcrumbSync(
      DiagnosticsEvents.activityTrackingStall,
      details: {
        'reason': decision.reason.name,
        'gapSeconds': gapSeconds < 0 ? 0 : gapSeconds,
        'nextSegmentIndex': next.segmentIndex + 1,
      },
    );
  }

  bool _isTrackingStallReason(ActivitySegmentBreakReason reason) {
    return switch (reason) {
      ActivitySegmentBreakReason.timeGap ||
      ActivitySegmentBreakReason.impossibleSpeed ||
      ActivitySegmentBreakReason.poorAccuracy ||
      ActivitySegmentBreakReason.recoveryBoundary => true,
      ActivitySegmentBreakReason.none ||
      ActivitySegmentBreakReason.pauseResume => false,
    };
  }

  int _elapsedDurationSeconds(
    ActiveActivitySession session,
    DateTime reference,
  ) {
    if (session.status == ActiveActivityStatus.paused) {
      return session.elapsedDurationSeconds;
    }
    final anchor = session.resumedAt ?? session.startedAt;
    final segmentSeconds = reference.difference(anchor).inSeconds;
    return session.elapsedDurationSeconds +
        (segmentSeconds < 0 ? 0 : segmentSeconds);
  }
}
