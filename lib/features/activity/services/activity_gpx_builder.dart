import 'package:endurain/core/utils/gpx_document_builder.dart';
import 'package:endurain/features/activity/models/activity_recording_state.dart';
import 'package:endurain/features/activity/models/activity_track_segment.dart';
import 'package:endurain/features/activity/models/activity_track_point.dart';
import 'package:endurain/features/activity/models/activity_type.dart';

class ActivityGpxBuilder {
  const ActivityGpxBuilder();

  String build(ActivityRecordingState state, {String? trackName}) {
    return buildGpxDocument(
      name: trackName ?? _defaultTrackName(state.activityType),
      type: _trackType(state.activityType),
      metadataTime: _metadataTime(state),
      bounds: GpxBounds.fromPoints(state.points.map(_toGpxPoint)),
      segments: _segmentsForGpx(state)
          .map(
            (segment) =>
                segment.points.map(_toGpxPoint).toList(growable: false),
          )
          .toList(growable: false),
    );
  }

  GpxTrackPoint _toGpxPoint(ActivityTrackPoint point) => GpxTrackPoint(
    latitude: point.latitude,
    longitude: point.longitude,
    elevationMeters: point.elevationMeters,
    time: point.timestamp,
  );

  String _defaultTrackName(ActivityType? activityType) {
    return activityType?.apiValue ?? ActivityType.other.apiValue;
  }

  String _trackType(ActivityType? activityType) {
    return activityType?.apiValue ?? ActivityType.other.apiValue;
  }

  List<ActivityTrackSegment> _segmentsForGpx(ActivityRecordingState state) {
    final segments = state.segments
        .where((segment) => segment.points.isNotEmpty)
        .toList(growable: false);
    if (segments.isEmpty) {
      return [ActivityTrackSegment()];
    }
    return segments;
  }

  DateTime? _metadataTime(ActivityRecordingState state) {
    if (state.startedAt != null) {
      return state.startedAt;
    }
    if (state.points.isEmpty) {
      return null;
    }
    return state.points.first.timestamp;
  }
}
