import 'dart:collection';

import 'package:endurain/core/utils/copy_with.dart';
import 'package:endurain/features/activity/models/activity_recording_error.dart';
import 'package:endurain/features/activity/models/activity_track_segment.dart';
import 'package:endurain/features/activity/models/activity_track_point.dart';
import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/models/recorded_sensor_sample.dart';

/// Ephemeral UI/recording status used by [ActivityRecordingState], the live
/// state pushed to the controller/screen during a session. The durable,
/// persisted counterpart is `ActiveActivityStatus` in
/// `active_activity_session.dart` (which has no `idle` — sessions only exist
/// once recording has begun); both intentionally stay separate so the
/// ephemeral UI model and the recoverable persisted model can evolve apart.
enum ActivityRecordingStatus {
  idle,
  recording,
  paused,
  stopping,
  completed,
  failed,
}

class ActivityRecordingState {
  ActivityRecordingState({
    this.status = ActivityRecordingStatus.idle,
    this.activityType,
    this.startedAt,
    this.endedAt,
    this.localActivityId,
    this.lastError,
    this.elapsedDurationSeconds = 0,
    this.currentHeartRateBpm,
    this.currentPowerWatts,
    this.currentCadenceRpm,
    this.isAutoPaused = false,
    List<ActivityTrackPoint> points = const [],
    List<ActivityTrackSegment> segments = const [],
  }) : _segments = List<ActivityTrackSegment>.unmodifiable(
         segments.isEmpty ? _segmentsFromPoints(points) : segments,
       ),
       _points = List<ActivityTrackPoint>.unmodifiable(
         segments.isEmpty ? points : _flattenSegments(segments),
       );

  final ActivityRecordingStatus status;
  final ActivityType? activityType;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final String? localActivityId;
  final ActivityRecordingError? lastError;
  final int elapsedDurationSeconds;

  /// Most recent live heart rate (bpm) from a connected sensor, updated as
  /// readings arrive rather than only when a GPS point is recorded. `null` when
  /// no live heart-rate stream is feeding the recording (e.g. Android, where
  /// the native recorder stamps heart rate onto points instead). Surfaced live
  /// while recording; the durable per-point heart rate still lives on the
  /// track points.
  final int? currentHeartRateBpm;

  /// Most recent live power (watts) from a connected power meter, updated as
  /// readings arrive rather than only when a GPS point is recorded. `null` when
  /// no live power stream is feeding the recording. Surfaced live while
  /// recording; the durable per-point power still lives on the track points.
  final int? currentPowerWatts;

  /// Most recent live cadence (rpm) from a connected cadence sensor, updated as
  /// readings arrive rather than only when a GPS point is recorded. `null` when
  /// no live cadence stream is feeding the recording. Surfaced live while
  /// recording; the durable per-point cadence still lives on the track points.
  final int? currentCadenceRpm;

  /// Whether the recording is currently paused automatically by the
  /// movement/auto-pause detector, as opposed to an explicit user pause.
  /// Only meaningful when [status] is [ActivityRecordingStatus.paused]; the
  /// UI uses this to show a distinct "auto-paused" indicator and to know
  /// that this pause may resume on its own once movement is detected again.
  final bool isAutoPaused;

  final List<ActivityTrackPoint> _points;
  final List<ActivityTrackSegment> _segments;

  List<ActivityTrackPoint> get points => UnmodifiableListView(_points);

  List<ActivityTrackSegment> get segments => UnmodifiableListView(_segments);

  bool get isActive {
    return status == ActivityRecordingStatus.recording ||
        status == ActivityRecordingStatus.paused;
  }

  ActivityRecordingState copyWith({
    ActivityRecordingStatus? status,
    Object? activityType = kUnset,
    Object? startedAt = kUnset,
    Object? endedAt = kUnset,
    Object? localActivityId = kUnset,
    Object? lastError = kUnset,
    int? elapsedDurationSeconds,
    Object? currentHeartRateBpm = kUnset,
    Object? currentPowerWatts = kUnset,
    Object? currentCadenceRpm = kUnset,
    bool? isAutoPaused,
    List<ActivityTrackPoint>? points,
    List<ActivityTrackSegment>? segments,
  }) {
    return ActivityRecordingState(
      status: status ?? this.status,
      activityType: identical(activityType, kUnset)
          ? this.activityType
          : activityType as ActivityType?,
      startedAt: identical(startedAt, kUnset)
          ? this.startedAt
          : startedAt as DateTime?,
      endedAt: identical(endedAt, kUnset) ? this.endedAt : endedAt as DateTime?,
      localActivityId: identical(localActivityId, kUnset)
          ? this.localActivityId
          : localActivityId as String?,
      lastError: identical(lastError, kUnset)
          ? this.lastError
          : lastError as ActivityRecordingError?,
      elapsedDurationSeconds:
          elapsedDurationSeconds ?? this.elapsedDurationSeconds,
      currentHeartRateBpm: identical(currentHeartRateBpm, kUnset)
          ? this.currentHeartRateBpm
          : currentHeartRateBpm as int?,
      currentPowerWatts: identical(currentPowerWatts, kUnset)
          ? this.currentPowerWatts
          : currentPowerWatts as int?,
      currentCadenceRpm: identical(currentCadenceRpm, kUnset)
          ? this.currentCadenceRpm
          : currentCadenceRpm as int?,
      isAutoPaused: isAutoPaused ?? this.isAutoPaused,
      points: points ?? _points,
      segments: segments ?? (points == null ? _segments : const []),
    );
  }

  ActivityRecordingState addPoint(ActivityTrackPoint point) {
    final updatedSegments = _segments.isEmpty
        ? [
            ActivityTrackSegment(points: [point]),
          ]
        : [
            ..._segments.take(_segments.length - 1),
            _segments.last.addPoint(point),
          ];
    return copyWith(segments: updatedSegments);
  }

  ActivityRecordingState startNewSegment() {
    return copyWith(segments: [..._segments, ActivityTrackSegment()]);
  }

  /// The current live value for [kind], or `null` when none has been reported.
  int? currentSensorValue(RecordedSensorKind kind) {
    return switch (kind) {
      RecordedSensorKind.heartRate => currentHeartRateBpm,
      RecordedSensorKind.power => currentPowerWatts,
      RecordedSensorKind.cadence => currentCadenceRpm,
    };
  }

  /// Returns a copy with the live value for [kind] set to [value].
  ActivityRecordingState withCurrentSensorValue(
    RecordedSensorKind kind,
    int value,
  ) {
    return switch (kind) {
      RecordedSensorKind.heartRate => copyWith(currentHeartRateBpm: value),
      RecordedSensorKind.power => copyWith(currentPowerWatts: value),
      RecordedSensorKind.cadence => copyWith(currentCadenceRpm: value),
    };
  }

  static List<ActivityTrackSegment> _segmentsFromPoints(
    List<ActivityTrackPoint> points,
  ) {
    if (points.isEmpty) {
      return const [];
    }
    return [ActivityTrackSegment(points: points)];
  }

  static List<ActivityTrackPoint> _flattenSegments(
    List<ActivityTrackSegment> segments,
  ) {
    return [for (final segment in segments) ...segment.points];
  }
}
