import 'package:endurain/features/activity/models/activity_track_point.dart';
import 'package:endurain/features/activity/models/activity_track_segment.dart';
import 'package:endurain/features/activity/services/activity_stats_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ActivityStatsCalculator', () {
    final calculator = ActivityStatsCalculator();

    // Convenience: wrap flat points in one segment (single-segment tests).
    List<ActivityTrackSegment> oneSegment(List<ActivityTrackPoint> pts) => [
      ActivityTrackSegment(points: pts),
    ];

    test('returns zero stats for an empty segment list', () {
      final stats = calculator.calculate([]);

      expect(stats.distanceMeters, 0);
      expect(stats.durationSeconds, 0);
      expect(stats.averageSpeedMetersPerSecond, isNull);
      expect(stats.currentSpeedMetersPerSecond, isNull);
    });

    test('returns zero stats for a single-point segment', () {
      final stats = calculator.calculate(
        oneSegment([_point(latitude: 0, longitude: 0)]),
      );

      expect(stats.distanceMeters, 0);
      expect(stats.durationSeconds, 0);
      expect(stats.averageSpeedMetersPerSecond, isNull);
      expect(stats.currentSpeedMetersPerSecond, isNull);
    });

    test('handles duplicate points within a segment', () {
      final stats = calculator.calculate(
        oneSegment([
          _point(latitude: 41, longitude: -8, seconds: 0),
          _point(latitude: 41, longitude: -8, seconds: 60),
        ]),
      );

      expect(stats.distanceMeters, 0);
      expect(stats.durationSeconds, 60);
      expect(stats.averageSpeedMetersPerSecond, 0);
      expect(stats.currentSpeedMetersPerSecond, 0);
    });

    test('calculates distance, duration and speed for multiple points', () {
      final stats = calculator.calculate(
        oneSegment([
          _point(latitude: 0, longitude: 0, seconds: 0),
          _point(latitude: 0, longitude: 0.001, seconds: 60),
          _point(latitude: 0, longitude: 0.002, seconds: 120, speed: 2.5),
        ]),
      );

      expect(stats.distanceMeters, closeTo(222, 0.5));
      expect(stats.durationSeconds, 120);
      expect(stats.averageSpeedMetersPerSecond, closeTo(1.85, 0.01));
      expect(stats.currentSpeedMetersPerSecond, 2.5);
    });

    test('ignores non-monotonic timestamp pairs for duration', () {
      final stats = calculator.calculate(
        oneSegment([
          _point(latitude: 0, longitude: 0, seconds: 60),
          _point(latitude: 0, longitude: 0.001, seconds: 30),
          _point(latitude: 0, longitude: 0.002, seconds: 90),
        ]),
      );

      expect(stats.distanceMeters, closeTo(222, 0.5));
      expect(stats.durationSeconds, 60);
      expect(stats.averageSpeedMetersPerSecond, closeTo(3.7, 0.01));
    });

    // -------------------------------------------------------------------------
    // Multi-segment regression: distance between segments must NOT be counted.
    // -------------------------------------------------------------------------

    test('does not count the gap between two segments as distance', () {
      // Segment 1: walk ~111m east over 60s.
      // Segment 2: resume 5° away (teleportation during pause), walk ~111m east.
      final seg1 = ActivityTrackSegment(
        points: [
          _point(latitude: 0, longitude: 0, seconds: 0),
          _point(latitude: 0, longitude: 0.001, seconds: 60),
        ],
      );
      final seg2 = ActivityTrackSegment(
        points: [
          // 5° longitude jump that should NOT be counted.
          _point(latitude: 0, longitude: 5, seconds: 120),
          _point(latitude: 0, longitude: 5.001, seconds: 180),
        ],
      );

      final stats = calculator.calculate([seg1, seg2]);

      // Only ~222m total (two 111m legs), NOT ~555km (including the 5° gap).
      expect(stats.distanceMeters, closeTo(222, 1));
      expect(stats.durationSeconds, 120);
    });

    test('accumulates distance from multiple segments correctly', () {
      final seg1 = ActivityTrackSegment(
        points: [
          _point(latitude: 0, longitude: 0, seconds: 0),
          _point(latitude: 0, longitude: 0.001, seconds: 30),
        ],
      );
      final seg2 = ActivityTrackSegment(
        points: [
          _point(latitude: 10, longitude: 10, seconds: 60),
          _point(latitude: 10, longitude: 10.001, seconds: 90),
        ],
      );

      final single = calculator.calculate([
        ActivityTrackSegment(
          points: [
            _point(latitude: 0, longitude: 0, seconds: 0),
            _point(latitude: 0, longitude: 0.001, seconds: 30),
          ],
        ),
      ]);

      final stats = calculator.calculate([seg1, seg2]);

      // Distance should be double that of a single-segment walk of the same length.
      expect(stats.distanceMeters, closeTo(single.distanceMeters * 2, 1));
    });
  });
}

ActivityTrackPoint _point({
  required double latitude,
  required double longitude,
  int seconds = 0,
  double? speed,
}) {
  return ActivityTrackPoint(
    latitude: latitude,
    longitude: longitude,
    timestamp: DateTime.utc(2026).add(Duration(seconds: seconds)),
    speedMetersPerSecond: speed,
  );
}
