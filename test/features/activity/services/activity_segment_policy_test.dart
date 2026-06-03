import 'package:endurain/features/activity/models/recorded_activity_point.dart';
import 'package:endurain/features/activity/services/activity_segment_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ActivitySegmentPolicy', () {
    const policy = ActivitySegmentPolicy();
    final base = DateTime.utc(2026, 6, 3, 9);

    RecordedActivityPoint point({
      double latitude = 41,
      double longitude = -8,
      int second = 0,
      double? accuracy,
    }) {
      return RecordedActivityPoint(
        timestamp: base.add(Duration(seconds: second)),
        latitude: latitude,
        longitude: longitude,
        segmentIndex: 0,
        horizontalAccuracyMeters: accuracy,
      );
    }

    test('no previous point never requires a new segment', () {
      final decision = policy.evaluate(previous: null, next: point());
      expect(decision.requiresNewSegment, isFalse);
      expect(decision.reason, ActivitySegmentBreakReason.none);
    });

    test('normal movement keeps the same segment', () {
      final decision = policy.evaluate(
        previous: point(second: 0),
        next: point(latitude: 41.0001, second: 2),
      );
      expect(decision.requiresNewSegment, isFalse);
    });

    test('a long time gap requires a new segment', () {
      final decision = policy.evaluate(
        previous: point(second: 0),
        next: point(latitude: 41.0001, second: 120),
      );
      expect(decision.requiresNewSegment, isTrue);
      expect(decision.reason, ActivitySegmentBreakReason.timeGap);
    });

    test('an impossible jump requires a new segment', () {
      final decision = policy.evaluate(
        previous: point(latitude: 41, longitude: -8, second: 0),
        next: point(latitude: 45, longitude: -2, second: 2),
      );
      expect(decision.requiresNewSegment, isTrue);
      expect(decision.reason, ActivitySegmentBreakReason.impossibleSpeed);
    });

    test('poor accuracy requires a new segment', () {
      final decision = policy.evaluate(
        previous: point(second: 0),
        next: point(latitude: 41.0001, second: 2, accuracy: 250),
      );
      expect(decision.requiresNewSegment, isTrue);
      expect(decision.reason, ActivitySegmentBreakReason.poorAccuracy);
    });

    test('resuming from pause requires a new segment', () {
      final decision = policy.evaluate(
        previous: point(second: 0),
        next: point(latitude: 41.0001, second: 2),
        resumedFromPause: true,
      );
      expect(decision.requiresNewSegment, isTrue);
      expect(decision.reason, ActivitySegmentBreakReason.pauseResume);
    });

    test('a recovery boundary requires a new segment', () {
      final decision = policy.evaluate(
        previous: point(second: 0),
        next: point(latitude: 41.0001, second: 2),
        recoveredFromBoundary: true,
      );
      expect(decision.requiresNewSegment, isTrue);
      expect(decision.reason, ActivitySegmentBreakReason.recoveryBoundary);
    });
  });
}
