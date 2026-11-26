import 'dart:async';

import 'package:endurain/core/diagnostics/diagnostics_service.dart';
import 'package:endurain/features/activity/models/active_activity_session.dart';
import 'package:endurain/features/activity/models/activity_recording_error.dart';
import 'package:endurain/features/activity/models/activity_recording_state.dart';
import 'package:endurain/features/activity/models/recorded_activity_point.dart';
import 'package:endurain/features/activity/services/activity_location_recorder.dart';
import 'package:endurain/features/activity/services/recording_elapsed_clock.dart';
import 'package:endurain/features/activity/services/recording_point_batcher.dart';
import 'package:endurain/features/activity/services/recording_sensor_session.dart';

/// Restores a recording from the recorder's durable session (after the app
/// was killed or lost its event sink) and replays the recorder events that
/// arrived while the restore was in flight.
class RecordingSessionRecovery {
  RecordingSessionRecovery({
    required ActivityLocationRecorder recorder,
    required RecordingSensorSession sensors,
    required RecordingElapsedClock clock,
    required RecordingPointBatcher batcher,
    required DiagnosticsRecorder diagnostics,
    required DateTime Function() now,
    required bool Function() isDisposed,
    required void Function() startRecorderEvents,
    required void Function(ActiveActivitySession session) adoptSession,
    required void Function(ActivityRecordingState state) emit,
    required void Function() startElapsedTimer,
    required void Function(int pointCount) onPointsRestored,
    required void Function(ActivityRecorderEvent event) replayEvent,
  }) : _recorder = recorder,
       _sensors = sensors,
       _clock = clock,
       _batcher = batcher,
       _diagnostics = diagnostics,
       _now = now,
       _isDisposed = isDisposed,
       _startRecorderEvents = startRecorderEvents,
       _adoptSession = adoptSession,
       _emit = emit,
       _startElapsedTimer = startElapsedTimer,
       _onPointsRestored = onPointsRestored,
       _replayEvent = replayEvent;

  final ActivityLocationRecorder _recorder;
  final RecordingSensorSession _sensors;
  final RecordingElapsedClock _clock;
  final RecordingPointBatcher _batcher;
  final DiagnosticsRecorder _diagnostics;
  final DateTime Function() _now;
  final bool Function() _isDisposed;
  final void Function() _startRecorderEvents;
  final void Function(ActiveActivitySession session) _adoptSession;
  final void Function(ActivityRecordingState state) _emit;
  final void Function() _startElapsedTimer;
  final void Function(int pointCount) _onPointsRestored;
  final void Function(ActivityRecorderEvent event) _replayEvent;

  Future<bool>? _active;
  bool _isRecovering = false;
  final List<ActivityRecorderEvent> _bufferedEvents = [];

  /// The recovery in flight, if any; commands wait for it before running.
  Future<bool>? get pending => _active;

  /// Holds [event] back while a recovery runs. Returns whether it was held;
  /// held events are replayed once the recovery settles.
  bool buffer(ActivityRecorderEvent event) {
    if (!_isRecovering) {
      return false;
    }
    _bufferedEvents.add(event);
    return true;
  }

  /// Attempts to restore a recoverable active recording from the recorder.
  ///
  /// Live and paused sessions retain their status, including sessions waiting
  /// for their first fix. Only an explicitly stopped session is finalized.
  /// [isActive] is whether the in-memory state already is a live recording,
  /// in which case there is nothing to recover.
  Future<bool> recover({required bool isActive}) {
    final existing = _active;
    if (existing != null) {
      return existing;
    }
    if (isActive) {
      return Future.value(false);
    }
    final recovery = recoverNow().whenComplete(() {
      _active = null;
    });
    _active = recovery;
    return recovery;
  }

  /// Restores without the in-flight and already-active guards of [recover],
  /// for the start path that has just been told a session already exists.
  Future<bool> recoverNow() async {
    _isRecovering = true;
    _sensors.stopCapture();
    ActiveActivitySession? session;
    try {
      await _sensors.pendingWrites;
      _startRecorderEvents();
      session = await _recorder.recoverActiveSession();
      if (session == null || _isDisposed()) {
        return false;
      }
      _adoptSession(session);
      await _sensors.restore();
      final recordedPoints = await _recorder.drain();
      if (_isDisposed()) {
        return false;
      }
      final completed =
          session.status == ActiveActivityStatus.completed ||
          session.status == ActiveActivityStatus.stopping;
      if (completed && recordedPoints.isEmpty) {
        await _recorder.discard();
        return false;
      }
      return _restore(
        session,
        recordedPoints,
        status: completed
            ? ActivityRecordingStatus.completed
            : session.status == ActiveActivityStatus.recording
            ? ActivityRecordingStatus.recording
            : ActivityRecordingStatus.paused,
      );
    } catch (error, stackTrace) {
      if (_isDisposed()) {
        return false;
      }
      _diagnostics.recordErrorSync(
        error,
        stackTrace,
        source: DiagnosticsSources.activityRecorder,
      );
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
      final events = List<ActivityRecorderEvent>.of(_bufferedEvents);
      _bufferedEvents.clear();
      if (!_isDisposed()) {
        events.forEach(_replayEvent);
      }
    }
  }

  /// Rebuilds and emits recording state from a recovered durable [session] and
  /// its persisted [recordedPoints].
  ///
  /// A `completed` recovery stamps [ActivityRecordingState.endedAt] (the
  /// session's own end time, or now as a fallback) so the finished activity can
  /// be finalized; a `paused` recovery leaves it unset so recording can resume.
  bool _restore(
    ActiveActivitySession session,
    List<RecordedActivityPoint> recordedPoints, {
    required ActivityRecordingStatus status,
  }) {
    final isCompleted = status == ActivityRecordingStatus.completed;
    final isRecording = status == ActivityRecordingStatus.recording;
    _adoptSession(session);
    final segments = _batcher.segmentsFromRecorded(recordedPoints);
    _clock.restore(
      elapsedBeforeSeconds: session.elapsedDurationSeconds,
      segmentStartedAt: isRecording
          ? session.resumedAt ?? session.startedAt
          : null,
    );
    _onPointsRestored(recordedPoints.length);
    _batcher.restore(recordedPoints);
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
    _diagnostics.recordBreadcrumbSync(
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
}
