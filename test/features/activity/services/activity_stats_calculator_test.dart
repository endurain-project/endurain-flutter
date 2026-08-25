import 'package:endurain/features/activity/models/activity_track_point.dart';
import 'package:endurain/features/activity/models/activity_track_segment.dart';
import 'package:endurain/features/activity/services/activity_stats_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/elevation_profile.dart';

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
      expect(stats.averageSpeedMetersPerSecond, 0);
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

      expect(stats.distanceMeters, closeTo(222.6, 0.1));
      expect(stats.durationSeconds, 120);
      expect(stats.averageSpeedMetersPerSecond, closeTo(1.24, 0.01));
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

      expect(stats.distanceMeters, closeTo(222.6, 0.1));
      expect(stats.durationSeconds, 60);
      // The segment's first point and the backwards pair both contribute zero
      // velocity samples, matching the uploaded GPX calculation.
      expect(stats.averageSpeedMetersPerSecond, closeTo(0.62, 0.01));
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
      expect(stats.averageSpeedMetersPerSecond, closeTo(0.93, 0.01));
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
          _point(latitude: 0, longitude: 10, seconds: 60),
          _point(latitude: 0, longitude: 10.001, seconds: 90),
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

    test('derives max speed from movement, not the reported GPS speed', () {
      // The uploaded GPX carries no speed field, so the server derives speed
      // from position deltas. Reported GPS speed must not change the summary.
      final stats = calculator.calculate(
        oneSegment([
          _point(latitude: 0, longitude: 0, seconds: 0, speed: 2),
          _point(latitude: 0, longitude: 0.001, seconds: 60, speed: 50),
          _point(latitude: 0, longitude: 0.003, seconds: 120, speed: 3),
        ]),
      );

      // Second leg (~222m/60s) is faster than the first (~111m/60s).
      expect(stats.maxSpeedMetersPerSecond, closeTo(3.7, 0.1));
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

    test('uses sub-second timestamp deltas when deriving speed', () {
      final stats = calculator.calculate(
        oneSegment([
          ActivityTrackPoint(
            latitude: 0,
            longitude: 0,
            timestamp: DateTime.utc(2026),
          ),
          ActivityTrackPoint(
            latitude: 0,
            longitude: 0.001,
            timestamp: DateTime.utc(2026)
                .add(const Duration(milliseconds: 1500)),
          ),
        ]),
      );

      // ~111m over 1.5s, not over the 1s a truncated delta would report.
      expect(stats.maxSpeedMetersPerSecond, closeTo(74.2, 0.5));
    });

    test('reports zero max speed for a single-point segment', () {
      final stats = calculator.calculate(
        oneSegment([_point(latitude: 0, longitude: 0)]),
      );

      expect(stats.maxSpeedMetersPerSecond, 0);
    });

    test('rejects altimeter spikes instead of counting them as climb', () {
      final elevations = List<double>.filled(12, 100)..[6] = 130;

      final stats = calculator.calculate(
        oneSegment(_elevationProfile(elevations)),
      );

      expect(stats.elevationGainMeters, 0);
    });

    test('sums a sustained climb after smoothing', () {
      final stats = calculator.calculate(
        oneSegment(_elevationProfile(climbElevationProfile())),
      );

      expect(
        stats.elevationGainMeters,
        closeTo(climbElevationGainMeters, 0.001),
      );
    });

    test('ignores non-finite and implausible elevation samples', () {
      final stats = calculator.calculate(
        oneSegment(
          _elevationProfile([
            ...climbElevationProfile(),
            double.nan,
            double.infinity,
            10000,
            -10000,
          ]),
        ),
      );

      expect(
        stats.elevationGainMeters,
        closeTo(climbElevationGainMeters, 0.001),
      );
    });

    test('reports zero elevation gain for a pure descent', () {
      final stats = calculator.calculate(
        oneSegment(
          _elevationProfile(
            climbElevationProfile().reversed.toList(growable: false),
          ),
        ),
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

    test('smooths the flattened GPX elevation stream across segments', () {
      final seg1 = ActivityTrackSegment(
        points: _elevationProfile(climbElevationProfile()),
      );
      final seg2 = ActivityTrackSegment(
        points: _elevationProfile(
          climbElevationProfile(base: 500),
          startSecond: 600,
          startLongitude: 5,
        ),
      );

      final stats = calculator.calculate([seg1, seg2]);

      // The backend flattens elevation waypoints before smoothing, so this is
      // 100 m + the 300 m segment-boundary rise + another 100 m.
      expect(stats.elevationGainMeters, closeTo(500, 0.001));
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

      // Only HR-bearing points count. Python's round uses ties-to-even, so the
      // backend rounds (100+121)/2 = 110.5 to 110.
      expect(stats.averageHeartRateBpm, 110);
      expect(stats.currentHeartRateBpm, 121);
    });

    test('treats zero heart rate and power as sensor dropouts', () {
      final stats = calculator.calculate(
        oneSegment([
          _point(
            latitude: 0,
            longitude: 0,
            seconds: 0,
            heartRate: 140,
            power: 200,
            cadence: 90,
          ),
          _point(
            latitude: 0,
            longitude: 0.001,
            seconds: 60,
            heartRate: 0,
            power: 0,
            cadence: 0,
          ),
        ]),
      );

      // The zero readings are dropped, so the averages match the single real
      // sample. Cadence keeps its zeros: coasting is a genuine measurement.
      expect(stats.averageHeartRateBpm, 140);
      expect(stats.currentHeartRateBpm, 140);
      expect(stats.averagePowerWatts, 200);
      expect(stats.currentPowerWatts, 200);
      expect(stats.averageCadenceRpm, 45);
      expect(stats.currentCadenceRpm, 0);
    });

    test('reports null power and cadence when no point carries them', () {
      final stats = calculator.calculate(
        oneSegment([
          _point(latitude: 0, longitude: 0, seconds: 0),
          _point(latitude: 0, longitude: 0.001, seconds: 60),
        ]),
      );

      expect(stats.currentPowerWatts, isNull);
      expect(stats.averagePowerWatts, isNull);
      expect(stats.currentCadenceRpm, isNull);
      expect(stats.averageCadenceRpm, isNull);
    });

    test('keeps an all-zero cadence out of the summary', () {
      final stats = calculator.calculate(
        oneSegment([
          _point(latitude: 0, longitude: 0, seconds: 0, cadence: 0),
          _point(latitude: 0, longitude: 0.001, seconds: 60, cadence: 0),
        ]),
      );

      expect(stats.currentCadenceRpm, 0);
      expect(stats.averageCadenceRpm, isNull);
    });

    test('tracks the latest and average power and cadence', () {
      final stats = calculator.calculate(
        oneSegment([
          _point(
            latitude: 0,
            longitude: 0,
            seconds: 0,
            power: 200,
            cadence: 80,
          ),
          _point(latitude: 0, longitude: 0.001, seconds: 60),
          _point(
            latitude: 0,
            longitude: 0.002,
            seconds: 120,
            power: 300,
            cadence: 90,
          ),
        ]),
      );

      // Power omits missing samples. Cadence mirrors the backend's per-point
      // GPX stream, where the missing middle extension becomes zero:
      // (80+0+90)/3 = 56.67 -> 57.
      expect(stats.currentPowerWatts, 300);
      expect(stats.averagePowerWatts, 250);
      expect(stats.currentCadenceRpm, 90);
      expect(stats.averageCadenceRpm, 57);
    });

    test('uses backend ties-to-even rounding for average power', () {
      final stats = calculator.calculate(
        oneSegment([
          _point(latitude: 0, longitude: 0, power: 200),
          _point(latitude: 0, longitude: 0.001, power: 201),
        ]),
      );

      expect(stats.averagePowerWatts, 200);
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
  int? power,
  int? cadence,
}) {
  return ActivityTrackPoint(
    latitude: latitude,
    longitude: longitude,
    timestamp: DateTime.utc(2026).add(Duration(seconds: seconds)),
    speedMetersPerSecond: speed,
    elevationMeters: elevation,
    heartRateBpm: heartRate,
    powerWatts: power,
    cadenceRpm: cadence,
  );
}

/// Turns an elevation series into points sampled one second and ~11 m apart.
List<ActivityTrackPoint> _elevationProfile(
  List<double> elevations, {
  int startSecond = 0,
  double startLongitude = 0,
}) {
  return [
    for (var index = 0; index < elevations.length; index += 1)
      _point(
        latitude: 0,
        longitude: startLongitude + index * 0.0001,
        seconds: startSecond + index,
        elevation: elevations[index],
      ),
  ];
}
