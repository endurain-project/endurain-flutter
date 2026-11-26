import 'package:endurain/features/health/services/health_heart_rate_index.dart';
import 'package:flutter_test/flutter_test.dart';

HealthHeartRateSample _sample(int startMs, int endMs, int bpm) =>
    HealthHeartRateSample.interval(
      start: DateTime.fromMillisecondsSinceEpoch(startMs, isUtc: true),
      end: DateTime.fromMillisecondsSinceEpoch(endMs, isUtc: true),
      bpm: bpm,
    );

HealthHeartRateIndex _index(List<HealthHeartRateSample> samples) =>
    HealthHeartRateIndex(samples..sort(HealthHeartRateSample.byStart));

void main() {
  group('HealthHeartRateIndex', () {
    test('returns null without readings', () {
      expect(_index([]).bpmAt(1000), isNull);
    });

    test('a reading that covers the time wins', () {
      final index = _index([_sample(0, 60000, 120)]);
      expect(index.bpmAt(30000), 120);
      expect(index.bpmAt(0), 120);
      expect(index.bpmAt(60000), 120);
    });

    test('takes the nearest reading within the tolerance', () {
      final index = _index([_sample(0, 1000, 100), _sample(30000, 31000, 140)]);
      expect(index.bpmAt(6000), 100);
      expect(index.bpmAt(24000), 140);
    });

    test('ignores readings farther than the tolerance', () {
      final index = _index([_sample(0, 1000, 100), _sample(60000, 61000, 140)]);
      expect(index.bpmAt(30000), isNull);
      expect(index.bpmAt(11001), isNull);
      expect(index.bpmAt(11000), 100);
    });

    test('a tie between neighbours goes to the earlier reading', () {
      final index = _index([_sample(0, 0, 100), _sample(10000, 10000, 140)]);
      expect(index.bpmAt(5000), 100);
    });

    test('overlapping readings resolve to the earliest covering one', () {
      final index = _index([
        _sample(0, 100000, 90),
        _sample(10000, 20000, 150),
      ]);
      expect(index.bpmAt(15000), 90);
      expect(index.bpmAt(50000), 90);
    });

    test('a short reading inside a long one does not hide the long one', () {
      final index = _index([
        _sample(0, 100000, 90),
        _sample(10000, 20000, 150),
        _sample(200000, 201000, 170),
      ]);
      // Nearest-before uses the reading holding the latest end (the long one).
      expect(index.bpmAt(105000), 90);
    });

    test('an end before its start is treated as an instant reading', () {
      final index = _index([_sample(5000, 1000, 111)]);
      expect(index.bpmAt(5000), 111);
      expect(index.bpmAt(1000), 111);
    });
  });
}
