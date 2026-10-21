import 'package:endurain/features/activity/models/activity_track_point.dart';
import 'package:endurain/features/activity/models/activity_track_segment.dart';
import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/services/geo_distance.dart';

/// Removes GPS fixes that imply a speed the activity cannot reach.
///
/// Every recorder (Dart, Android, iOS) only rejects jumps above ~90 m/s, so a
/// fix that is a few tens of metres off still reaches the track. Because speed
/// is derived from position deltas, one such fix, especially the first fix after
/// a pause or one closely following its predecessor, becomes the activity's
/// max speed and a spike in the pace chart.
///
/// The filter runs where all recorders converge: when building the GPX for
/// upload and when computing the on-device stats, so both show the same data.
class ActivityTrackOutlierFilter {
  const ActivityTrackOutlierFilter({
    this.minimumIntervalSeconds = 1,
    this.maxConsecutiveDrops = 3,
  });

  /// Time deltas shorter than this are treated as this long, so a pair of
  /// fixes a fraction of a second apart cannot inflate the speed.
  final double minimumIntervalSeconds;

  /// After this many rejected fixes in a row the next one is accepted, so a
  /// genuine relocation (tunnel, signal loss) cannot erase the rest of a track.
  /// If it still breaks the speed limit it starts a new segment, so the jump
  /// is never counted as distance or speed.
  final int maxConsecutiveDrops;

  /// Fastest speed (m/s) considered plausible for [type], with headroom above
  /// elite performance (running ~12.5 m/s, cycling downhill ~28 m/s).
  static double maxSpeedMetersPerSecond(ActivityType? type) {
    return switch (type) {
      ActivityType.run => 12.5,
      ActivityType.walk => 5,
      ActivityType.hike => 6,
      ActivityType.ride => 28,
      ActivityType.other || null => 90,
    };
  }

  /// Returns [segments] without implausible fixes. Segments are filtered
  /// independently, and one is split where the track relocated. A segment that
  /// ends up empty is kept so segment counts match.
  List<ActivityTrackSegment> filter(
    List<ActivityTrackSegment> segments,
    ActivityType? type,
  ) {
    final cap = maxSpeedMetersPerSecond(type);
    return [
      for (final segment in segments)
        for (final points in _filterPoints(segment.points, cap))
          ActivityTrackSegment(points: points),
    ];
  }

  List<List<ActivityTrackPoint>> _filterPoints(
    List<ActivityTrackPoint> points,
    double cap,
  ) {
    if (points.length < 2) {
      return [points];
    }
    var start = 0;
    // A bad first fix has no predecessor to be compared with, so judge it
    // against the two fixes after it: it is bad if it is the only one that
    // breaks the speed limit.
    while (points.length - start >= 3 &&
        _exceeds(points[start], points[start + 1], cap) &&
        !_exceeds(points[start + 1], points[start + 2], cap)) {
      start += 1;
    }

    final filtered = <List<ActivityTrackPoint>>[];
    var kept = <ActivityTrackPoint>[points[start]];
    var drops = 0;
    for (var index = start + 1; index < points.length; index += 1) {
      final candidate = points[index];
      final exceeds = _exceeds(kept.last, candidate, cap);
      if (drops < maxConsecutiveDrops && exceeds) {
        drops += 1;
        continue;
      }
      if (exceeds) {
        filtered.add(kept);
        kept = [candidate];
      } else {
        kept.add(candidate);
      }
      drops = 0;
    }
    filtered.add(kept);
    return filtered;
  }

  bool _exceeds(ActivityTrackPoint from, ActivityTrackPoint to, double cap) {
    final seconds =
        to.timestamp.difference(from.timestamp).inMicroseconds /
        Duration.microsecondsPerSecond;
    if (seconds <= 0) {
      return false;
    }
    final meters = geoDistanceMeters(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
    final effectiveSeconds = seconds < minimumIntervalSeconds
        ? minimumIntervalSeconds
        : seconds;
    return meters / effectiveSeconds > cap;
  }
}
