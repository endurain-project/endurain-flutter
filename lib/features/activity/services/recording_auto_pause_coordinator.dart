import 'package:endurain/core/diagnostics/diagnostics_service.dart';
import 'package:endurain/features/activity/models/activity_recording_state.dart';
import 'package:endurain/features/activity/services/activity_location_recorder.dart';
import 'package:endurain/features/activity/services/movement_auto_pause_config.dart';
import 'package:endurain/features/activity/services/recording_elapsed_clock.dart';
import 'package:endurain/features/activity/services/recording_sensor_session.dart';

/// Bridges the native recorder's autonomous auto-pause and auto-resume events
/// (its movement detector, not an explicit pause or resume call) into the live
/// recording state, and holds the auto-pause configuration snapshotted into
/// the next recording.
class RecordingAutoPauseCoordinator {
  RecordingAutoPauseCoordinator({
    required RecordingSensorSession sensors,
    required RecordingElapsedClock clock,
    required DateTime Function() now,
    required ActivityRecordingState Function() readState,
    required void Function(ActivityRecordingState state) emit,
    required String? Function() localSessionId,
    required void Function() startElapsedTimer,
    required void Function(String event, {Map<String, Object?> details})
    recordBreadcrumb,
  }) : _sensors = sensors,
       _clock = clock,
       _now = now,
       _readState = readState,
       _emit = emit,
       _localSessionId = localSessionId,
       _startElapsedTimer = startElapsedTimer,
       _recordBreadcrumb = recordBreadcrumb;

  final RecordingSensorSession _sensors;
  final RecordingElapsedClock _clock;
  final DateTime Function() _now;
  final ActivityRecordingState Function() _readState;
  final void Function(ActivityRecordingState state) _emit;
  final String? Function() _localSessionId;
  final void Function() _startElapsedTimer;
  final void Function(String event, {Map<String, Object?> details})
  _recordBreadcrumb;

  /// The auto-pause configuration to snapshot into the next recording's
  /// session.
  MovementAutoPauseConfig config = const MovementAutoPauseConfig();

  /// Applies a recorder event when it is an auto-pause or auto-resume.
  /// Returns whether [event] was one of those two.
  bool handle(ActivityRecorderEvent event) {
    switch (event.type) {
      case ActivityRecorderEventType.autoPaused:
        _handleAutoPaused(event);
        return true;
      case ActivityRecorderEventType.autoResumed:
        _handleAutoResumed(event);
        return true;
      default:
        return false;
    }
  }

  /// Guarded to only act while actively recording so a duplicate or
  /// out-of-order event can never clobber a state the controller already
  /// knows about. Prefers the recorder's own elapsed-time computation (from
  /// `event.session`) over recomputing locally: the recorder timestamps the
  /// pause from the fix that triggered it, which stays correct even if the
  /// Dart isolate's own timer was throttled while backgrounded.
  ///
  /// The recorder has already saved the session as paused, so it rejects
  /// further sensor samples: capture stops here and restarts on auto-resume.
  void _handleAutoPaused(ActivityRecorderEvent event) {
    final state = _readState();
    if (state.status != ActivityRecordingStatus.recording) {
      return;
    }
    _sensors.stopCapture();
    final elapsedDurationSeconds = _clock.freeze(
      elapsedSeconds: event.session?.elapsedDurationSeconds,
    );
    _emit(
      state.copyWith(
        status: ActivityRecordingStatus.paused,
        elapsedDurationSeconds: elapsedDurationSeconds,
        isAutoPaused: true,
      ),
    );
    _recordBreadcrumb(
      DiagnosticsEvents.activityAutoPaused,
      details: {
        'elapsedSeconds': elapsedDurationSeconds,
        'pointCount': state.points.length,
        'segmentCount': state.segments.length,
      },
    );
  }

  /// Starts a new track segment as required.
  ///
  /// Guarded to only act while auto-paused: in particular, a manually paused
  /// recording (`isAutoPaused == false`) never transitions here, which is the
  /// state-side half of "manual pause never auto-resumes" (the recorder-side
  /// half is that a manual pause stops monitoring location entirely).
  void _handleAutoResumed(ActivityRecorderEvent event) {
    final paused = _readState();
    if (paused.status != ActivityRecordingStatus.paused ||
        !paused.isAutoPaused) {
      return;
    }
    _clock.beginSegment(event.session?.resumedAt ?? _now());
    _emit(
      paused.startNewSegment().copyWith(
        status: ActivityRecordingStatus.recording,
        isAutoPaused: false,
      ),
    );
    final state = _readState();
    _recordBreadcrumb(
      DiagnosticsEvents.activityAutoResumed,
      details: {
        'elapsedSeconds': state.elapsedDurationSeconds,
        'pointCount': state.points.length,
        'segmentCount': state.segments.length,
      },
    );
    _startElapsedTimer();
    _sensors.startCapture(_localSessionId());
  }
}
