import 'package:endurain/features/activity/models/activity_track_point.dart';
import 'package:endurain/features/activity/models/activity_track_segment.dart';
import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/services/activity_track_outlier_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ActivityTrackOutlierFilter', () {
    const filter = ActivityTrackOutlierFilter();

    // ~1.11 m per 0.00001 degrees of longitude at the equator.
    ActivityTrackPoint point(double metersEast, double seconds) {
      return ActivityTrackPoint(
        latitude: 0,
        longitude: metersEast / 111195,
        timestamp: DateTime.utc(2026)
            .add(Duration(microseconds: (seconds * 1e6).round())),
      );
    }

    List<ActivityTrackPoint> run(
      List<ActivityTrackPoint> points, [
      ActivityType? type = ActivityType.run,
    ]) {
      return filter
          .filter([ActivityTrackSegment(points: points)], type)
          .expand((segment) => segment.points)
          .toList();
    }

    test('keeps a steady run untouched', () {
      final points = [for (var i = 0; i < 8; i++) point(i * 3.0, i.toDouble())];
      expect(run(points), hasLength(8));
    });

    test('drops a fix that jumps ahead and comes back', () {
      final points = [
        point(0, 0),
        point(3, 1),
        point(40, 2), // 37 m/s for a runner
        point(9, 3),
        point(12, 4),
      ];
      final kept = run(points);
      expect(kept, hasLength(4));
      expect(kept.map((p) => p.timestamp.second), [0, 1, 3, 4]);
    });

    test('drops two fixes less than a second apart that jump', () {
      final points = [
        point(0, 0),
        point(3, 1),
        point(18, 1.3), // 15 m in 0.3s, treated as 1s -> 15 m/s
        point(6, 2),
      ];
      expect(run(points), hasLength(3));
    });

    test('drops a bad first fix of a segment', () {
      final points = [point(60, 0), point(0, 1), point(3, 2), point(6, 3)];
      final kept = run(points);
      expect(kept, hasLength(3));
      expect(kept.first.timestamp.second, 1);
    });

    test('splits the track where a persistent relocation is accepted', () {
      final points = [
        for (var i = 0; i < 3; i++) point(i * 3.0, i.toDouble()),
        for (var i = 3; i <= 8; i++) point(500 + i * 3.0, i.toDouble()),
      ];
      final segments = filter.filter([
        ActivityTrackSegment(points: points),
      ], ActivityType.run);

      expect(segments, hasLength(2));
      expect(segments[0].points, hasLength(3));
      // Three fixes are dropped, the fourth starts the new segment.
      expect(segments[1].points.first.timestamp.second, 6);
      expect(segments[1].points.last.timestamp.second, 8);
    });

    test('allows cycling speeds that would be impossible for a run', () {
      final points = [
        for (var i = 0; i < 5; i++) point(i * 15.0, i.toDouble()),
      ];
      expect(run(points, ActivityType.run).length, lessThan(5));
      expect(run(points, ActivityType.ride), hasLength(5));
    });

    test('keeps empty and single-point segments', () {
      final result = filter.filter([
        ActivityTrackSegment(),
        ActivityTrackSegment(points: [point(0, 0)]),
      ], ActivityType.run);
      expect(result, hasLength(2));
      expect(result[1].points, hasLength(1));
    });
  });
}
