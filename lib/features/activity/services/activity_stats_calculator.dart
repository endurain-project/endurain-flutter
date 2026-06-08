import 'package:endurain/features/activity/models/activity_recording_stats.dart';
import 'package:endurain/features/activity/models/activity_track_segment.dart';
import 'package:latlong2/latlong.dart';

class ActivityStatsCalculator {
  ActivityStatsCalculator({Distance? distance})
    : _distance = distance ?? const Distance();

  final Distance _distance;

  /// Calculates stats from [segments], computing distance only within each
  /// segment so that gaps between pause-and-resume boundaries are not counted.
  ///
  /// Passing an empty list returns zero stats.
  ActivityRecordingStats calculate(List<ActivityTrackSegment> segments) {
    if (segments.isEmpty) {
      return const ActivityRecordingStats(
        distanceMeters: 0,
        durationSeconds: 0,
      );
    }

    var distanceMeters = 0.0;
    var durationSeconds = 0;
    double? currentSpeedMetersPerSecond;

    for (final segment in segments) {
      final points = segment.points;
      for (var index = 1; index < points.length; index += 1) {
        final previous = points[index - 1];
        final current = points[index];
        final pairDistanceMeters = _distance.as(
          LengthUnit.Meter,
          LatLng(previous.latitude, previous.longitude),
          LatLng(current.latitude, current.longitude),
        );
        distanceMeters += pairDistanceMeters;

        final pairDurationSeconds = current.timestamp
            .difference(previous.timestamp)
            .inSeconds;
        if (pairDurationSeconds > 0) {
          durationSeconds += pairDurationSeconds;
          if (current.speedMetersPerSecond == null) {
            currentSpeedMetersPerSecond =
                pairDistanceMeters / pairDurationSeconds;
          }
        }
      }
    }

    // Use the speed from the very last point across all segments.
    final lastSegment = segments.last;
    if (lastSegment.points.isNotEmpty) {
      currentSpeedMetersPerSecond =
          lastSegment.points.last.speedMetersPerSecond ??
          currentSpeedMetersPerSecond;
    }

    final averageSpeedMetersPerSecond = durationSeconds > 0
        ? distanceMeters / durationSeconds
        : null;

    return ActivityRecordingStats(
      distanceMeters: distanceMeters,
      durationSeconds: durationSeconds,
      averageSpeedMetersPerSecond: averageSpeedMetersPerSecond,
      currentSpeedMetersPerSecond: currentSpeedMetersPerSecond,
    );
  }
}
