import 'package:endurain/features/activity/services/activity_stats_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ActivityStatsFormatter', () {
    const formatter = ActivityStatsFormatter();

    test('formats durations', () {
      expect(formatter.formatDuration(0), '0:00');
      expect(formatter.formatDuration(65), '1:05');
      expect(formatter.formatDuration(3661), '1:01:01');
      expect(formatter.formatDuration(-10), '0:00');
    });

    test('formats distances', () {
      expect(formatter.formatDistance(42.4), '42 m');
      expect(formatter.formatDistance(999.6), '1000 m');
      expect(formatter.formatDistance(1200), '1.20 km');
      expect(formatter.formatDistance(1200, locale: 'pt-PT'), '1,20 km');
    });

    test('formats speed only when available', () {
      expect(formatter.formatSpeed(null), '-');
      expect(formatter.formatSpeed(2), '7.2 km/h');
      expect(formatter.formatSpeed(2, locale: 'pt-PT'), '7,2 km/h');
    });

    test('formats pace only for positive speeds', () {
      expect(formatter.formatPace(null), '-');
      expect(formatter.formatPace(0), '-');
      expect(formatter.formatPace(2.5), '6:40 min/km');
    });

    test('formats elevation only when available', () {
      expect(formatter.formatElevation(null), '-');
      expect(formatter.formatElevation(123.4), '123 m');
      expect(formatter.formatElevation(124.6), '125 m');
      expect(formatter.formatElevation(1235, locale: 'en-US'), '1,235 m');
    });

    test('formats heart rate only when available', () {
      expect(formatter.formatHeartRate(null), '-');
      expect(formatter.formatHeartRate(142), '142 bpm');
    });
  });
}
