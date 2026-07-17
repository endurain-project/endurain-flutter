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

    // -------------------------------------------------------------------------
    // Max speed and elevation gain (post-recording summary metrics).
    // -------------------------------------------------------------------------

    test('tracks the fastest reported instantaneous speed', () {
      final stats = calculator.calculate(
        oneSegment([
          _point(latitude: 0, longitude: 0, seconds: 0, speed: 2),
          _point(latitude: 0, longitude: 0.001, seconds: 60, speed: 5),
          _point(latitude: 0, longitude: 0.002, seconds: 120, speed: 3),
        ]),
      );

      expect(stats.maxSpeedMetersPerSecond, 5);
    });

    test('derives max speed from movement when GPS speed is missing', () {
      final stats = calculator.calculate(
        oneSegment([
          _point(latitude: 0, longitude: 0, seconds: 0),
          _point(latitude: 0, longitude: 0.001, seconds: 60),
          _point(latitude: 0, longitude: 0.003, seconds: 120),
        ]),
      );

      // Second leg (~222m/60s) is faster than the first (~111m/60s).
      expect(stats.maxSpeedMetersPerSecond, closeTo(3.7, 0.1));
    });

    test('reports null max speed for a single-point segment', () {
      final stats = calculator.calculate(
        oneSegment([_point(latitude: 0, longitude: 0)]),
      );

      expect(stats.maxSpeedMetersPerSecond, isNull);
    });

    test('sums positive elevation deltas as elevation gain', () {
      final stats = calculator.calculate(
        oneSegment([
          _point(latitude: 0, longitude: 0, seconds: 0, elevation: 100),
          _point(latitude: 0, longitude: 0.001, seconds: 60, elevation: 110),
          _point(latitude: 0, longitude: 0.002, seconds: 120, elevation: 105),
          _point(latitude: 0, longitude: 0.003, seconds: 180, elevation: 125),
        ]),
      );

      // +10, then -5 (ignored), then +20 = 30.
      expect(stats.elevationGainMeters, closeTo(30, 0.001));
    });

    test('reports zero elevation gain for a pure descent', () {
      final stats = calculator.calculate(
        oneSegment([
          _point(latitude: 0, longitude: 0, seconds: 0, elevation: 200),
          _point(latitude: 0, longitude: 0.001, seconds: 60, elevation: 150),
        ]),
      );

      expect(stats.elevationGainMeters, 0);
    });

    test('reports null elevation gain without elevation data', () {
      final stats = calculator.calculate(
        oneSegment([
          _point(latitude: 0, longitude: 0, seconds: 0),
          _point(latitude: 0, longitude: 0.001, seconds: 60),
        ]),
      );

      expect(stats.elevationGainMeters, isNull);
    });

    test('does not count elevation change between segments', () {
      final seg1 = ActivityTrackSegment(
        points: [
          _point(latitude: 0, longitude: 0, seconds: 0, elevation: 100),
          _point(latitude: 0, longitude: 0.001, seconds: 60, elevation: 110),
        ],
      );
      final seg2 = ActivityTrackSegment(
        points: [
          _point(latitude: 0, longitude: 5, seconds: 120, elevation: 500),
          _point(latitude: 0, longitude: 5.001, seconds: 180, elevation: 520),
        ],
      );

      final stats = calculator.calculate([seg1, seg2]);

      // +10 in the first segment and +20 in the second; the 110->500 jump
      // across the pause boundary is not counted.
      expect(stats.elevationGainMeters, closeTo(30, 0.001));
    });

    // -------------------------------------------------------------------------
    // Heart rate (live current + summary average).
    // -------------------------------------------------------------------------

    test('reports null heart rate when no point carries a reading', () {
      final stats = calculator.calculate(
        oneSegment([
          _point(latitude: 0, longitude: 0, seconds: 0),
          _point(latitude: 0, longitude: 0.001, seconds: 60),
        ]),
      );

      expect(stats.currentHeartRateBpm, isNull);
      expect(stats.averageHeartRateBpm, isNull);
    });

    test('tracks the latest and average heart rate across segments', () {
      final seg1 = ActivityTrackSegment(
        points: [
          _point(latitude: 0, longitude: 0, seconds: 0, heartRate: 100),
          _point(latitude: 0, longitude: 0.001, seconds: 60, heartRate: 120),
        ],
      );
      final seg2 = ActivityTrackSegment(
        points: [
          _point(latitude: 0, longitude: 5, seconds: 120, heartRate: 140),
          _point(latitude: 0, longitude: 5.001, seconds: 180, heartRate: 160),
        ],
      );

      final stats = calculator.calculate([seg1, seg2]);

      // Latest reading is the last point's; average is (100+120+140+160)/4.
      expect(stats.currentHeartRateBpm, 160);
      expect(stats.averageHeartRateBpm, 130);
    });

    test('rounds the average heart rate and ignores points without one', () {
      final stats = calculator.calculate(
        oneSegment([
          _point(latitude: 0, longitude: 0, seconds: 0, heartRate: 100),
          _point(latitude: 0, longitude: 0.001, seconds: 60),
          _point(latitude: 0, longitude: 0.002, seconds: 120, heartRate: 121),
        ]),
      );

      // Only the two HR-bearing points count: (100+121)/2 = 110.5 -> 111.
      expect(stats.averageHeartRateBpm, 111);
      expect(stats.currentHeartRateBpm, 121);
    });
  });
}

ActivityTrackPoint _point({
  required double latitude,
  required double longitude,
  int seconds = 0,
  double? speed,
  double? elevation,
  int? heartRate,
}) {
  return ActivityTrackPoint(
    latitude: latitude,
    longitude: longitude,
    timestamp: DateTime.utc(2026).add(Duration(seconds: seconds)),
    speedMetersPerSecond: speed,
    elevationMeters: elevation,
    heartRateBpm: heartRate,
  );
}
