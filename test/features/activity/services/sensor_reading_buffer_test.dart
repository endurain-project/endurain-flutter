import 'package:endurain/features/activity/services/sensor_reading_buffer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final base = DateTime.utc(2026, 6, 1, 12);

  group('SensorReadingBuffer', () {
    test('returns null when empty', () {
      final buffer = SensorReadingBuffer(const Duration(seconds: 10));
      expect(buffer.nearest(base), isNull);
    });

    test('returns the value at an exact timestamp', () {
      final buffer = SensorReadingBuffer(const Duration(seconds: 10));
      buffer.add(base, 120);
      expect(buffer.nearest(base), 120);
    });

    test('returns the nearest reading within the freshness window', () {
      final buffer = SensorReadingBuffer(const Duration(seconds: 10));
      buffer.add(base, 100);
      buffer.add(base.add(const Duration(seconds: 8)), 140);

      // 3s after the first, 5s before the second -> first is closer.
      expect(buffer.nearest(base.add(const Duration(seconds: 3))), 100);
      // 6s after the first, 2s before the second -> second is closer.
      expect(buffer.nearest(base.add(const Duration(seconds: 6))), 140);
    });

    test('returns null when the nearest reading is outside freshness', () {
      final buffer = SensorReadingBuffer(const Duration(seconds: 5));
      buffer.add(base, 100);
      expect(buffer.nearest(base.add(const Duration(seconds: 6))), isNull);
    });

    test('includes a reading exactly at the freshness boundary', () {
      final buffer = SensorReadingBuffer(const Duration(seconds: 5));
      buffer.add(base, 100);
      expect(buffer.nearest(base.add(const Duration(seconds: 5))), 100);
      expect(buffer.nearest(base.subtract(const Duration(seconds: 5))), 100);
    });

    test('finds the nearest among many readings via binary search', () {
      final buffer = SensorReadingBuffer(const Duration(seconds: 10));
      for (var i = 0; i < 100; i++) {
        buffer.add(base.add(Duration(seconds: i)), 60 + i);
      }

      expect(buffer.nearest(base.add(const Duration(seconds: 42))), 60 + 42);
      // 42.4s falls between the 42s and 43s readings, closer to 42s.
      expect(
        buffer.nearest(base.add(const Duration(milliseconds: 42400))),
        60 + 42,
      );
    });

    test('queries before the first reading use the first as nearest', () {
      final buffer = SensorReadingBuffer(const Duration(seconds: 10));
      buffer.add(base.add(const Duration(seconds: 5)), 130);
      expect(buffer.nearest(base), 130);
    });

    test('clear removes all readings', () {
      final buffer = SensorReadingBuffer(const Duration(seconds: 10));
      buffer.add(base, 100);
      buffer.clear();
      expect(buffer.nearest(base), isNull);
    });
  });
}
