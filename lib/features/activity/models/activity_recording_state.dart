import 'dart:collection';

import 'package:endurain/core/utils/copy_with.dart';
import 'package:endurain/features/activity/models/activity_recording_error.dart';
import 'package:endurain/features/activity/models/activity_track_segment.dart';
import 'package:endurain/features/activity/models/activity_track_point.dart';
import 'package:endurain/features/activity/models/activity_type.dart';

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
