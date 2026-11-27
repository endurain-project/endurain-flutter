import 'package:endurain/features/activity/models/activity_track_point.dart';
import 'package:endurain/features/activity/models/append_only_list.dart';

/// A run of consecutive track points between pauses.
///
/// Segments are immutable. Growing one returns a new instance, so a segment's
/// identity changes exactly when its points do (callers cache derived work such
/// as map polylines by that identity). Growing is amortised O(points added)
/// because the instances share an append-only backing store.
class ActivityTrackSegment {
  ActivityTrackSegment({List<ActivityTrackPoint> points = const []})
    : _points = AppendOnlyList<ActivityTrackPoint>.of(points);

  ActivityTrackSegment._(this._points);

  final AppendOnlyList<ActivityTrackPoint> _points;

  /// The points, unmodifiable.
  List<ActivityTrackPoint> get points => _points;

  /// A new segment with [points] appended; this segment is unchanged.
  ActivityTrackSegment addPoints(Iterable<ActivityTrackPoint> points) =>
      ActivityTrackSegment._(_points.appended(points));
}
