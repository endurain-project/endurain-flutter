import 'package:endurain/core/utils/gpx_document_builder.dart';
import 'package:endurain/features/activity/models/activity_recording_state.dart';
import 'package:endurain/features/activity/models/activity_track_point.dart';
import 'package:endurain/features/activity/models/activity_track_segment.dart';
import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/services/activity_track_outlier_filter.dart';

class ActivityGpxBuilder {
  const ActivityGpxBuilder({
    this.outlierFilter = const ActivityTrackOutlierFilter(),
  });

  final ActivityTrackOutlierFilter outlierFilter;

  String build(ActivityRecordingState state, {String? trackName}) {
    final segments = _segmentsForGpx(state);
    return buildGpxDocument(
      name: trackName ?? _defaultTrackName(state.activityType),
      type: _trackType(state.activityType),
      metadataTime: _metadataTime(state),
      bounds: GpxBounds.fromPoints(
        segments.expand((segment) => segment.points).map(_toGpxPoint),
      ),
      segments: segments
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
    heartRate: point.heartRateBpm,
    cadence: point.cadenceRpm,
    powerWatts: point.powerWatts,
  );

  String _defaultTrackName(ActivityType? activityType) {
    return activityType?.apiValue ?? ActivityType.other.apiValue;
  }

  String _trackType(ActivityType? activityType) {
    return activityType?.apiValue ?? ActivityType.other.apiValue;
  }

  List<ActivityTrackSegment> _segmentsForGpx(ActivityRecordingState state) {
    final segments = outlierFilter
        .filter(state.segments, state.activityType)
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
