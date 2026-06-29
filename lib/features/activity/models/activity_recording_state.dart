import 'dart:collection';

import 'package:endurain/features/activity/models/activity_recording_error.dart';
import 'package:endurain/features/activity/models/activity_track_segment.dart';
import 'package:endurain/features/activity/models/activity_track_point.dart';
import 'package:endurain/features/activity/models/activity_type.dart';

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
    Object? activityType = _unset,
    Object? startedAt = _unset,
    Object? endedAt = _unset,
    Object? localActivityId = _unset,
    Object? lastError = _unset,
    int? elapsedDurationSeconds,
    List<ActivityTrackPoint>? points,
    List<ActivityTrackSegment>? segments,
  }) {
    return ActivityRecordingState(
      status: status ?? this.status,
      activityType: identical(activityType, _unset)
          ? this.activityType
          : activityType as ActivityType?,
      startedAt: identical(startedAt, _unset)
          ? this.startedAt
          : startedAt as DateTime?,
      endedAt: identical(endedAt, _unset) ? this.endedAt : endedAt as DateTime?,
      localActivityId: identical(localActivityId, _unset)
          ? this.localActivityId
          : localActivityId as String?,
      lastError: identical(lastError, _unset)
          ? this.lastError
          : lastError as ActivityRecordingError?,
      elapsedDurationSeconds:
          elapsedDurationSeconds ?? this.elapsedDurationSeconds,
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

  static const Object _unset = Object();

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
