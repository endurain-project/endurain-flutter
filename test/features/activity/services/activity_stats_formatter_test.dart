import 'package:endurain/core/models/measurement_system.dart';
import 'package:endurain/features/activity/services/activity_stats_formatter.dart';
import 'package:endurain/l10n/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Labels come from the real English catalog rather than hand-written
  // literals, so a change to an ARB unit string is caught here instead of
  // silently diverging from what users see.
  final labels = UnitLabels.of(AppLocalizationsEn());

  final metric = ActivityStatsFormatter(labels: labels);
  final imperial = ActivityStatsFormatter(
    labels: labels,
    system: MeasurementSystem.imperial,
  );

  group('ActivityStatsFormatter (shared)', () {
    test('formats durations', () {
      expect(metric.formatDuration(0), '0:00');
      expect(metric.formatDuration(65), '1:05');
      expect(metric.formatDuration(3661), '1:01:01');
      expect(metric.formatDuration(-10), '0:00');
    });

    test('duration is unit-system independent', () {
      expect(imperial.formatDuration(3661), metric.formatDuration(3661));
    });

    test('defaults to metric when no system is given', () {
      expect(
        ActivityStatsFormatter(labels: labels).system,
        MeasurementSystem.metric,
      );
    });

    test('formats heart rate, power, and cadence in both systems', () {
      for (final formatter in [metric, imperial]) {
        expect(formatter.formatHeartRate(null), '-');
        expect(formatter.formatHeartRate(142), '142 bpm');
        expect(formatter.formatPower(null), '-');
        expect(formatter.formatPower(250), '250 W');
        expect(formatter.formatCadence(null), '-');
        expect(formatter.formatCadence(88), '88 rpm');
      }
    });
  });

  group('ActivityStatsFormatter (metric)', () {
    test('formats distances, switching to km past 1000 m', () {
      expect(metric.formatDistance(42.4), '42 m');
      expect(metric.formatDistance(999.6), '1000 m');
      expect(metric.formatDistance(1000), '1.00 km');
      expect(metric.formatDistance(1200), '1.20 km');
      expect(metric.formatDistance(1200, locale: 'pt-PT'), '1,20 km');
    });

    test('formats speed only when available', () {
      expect(metric.formatSpeed(null), '-');
      expect(metric.formatSpeed(2), '7.2 km/h');
      expect(metric.formatSpeed(2, locale: 'pt-PT'), '7,2 km/h');
    });

    test('formats pace only for positive speeds', () {
      expect(metric.formatPace(null), '-');
      expect(metric.formatPace(0), '-');
      expect(metric.formatPace(-1), '-');
      expect(metric.formatPace(2.5), '6:40 min/km');
    });

    test('formats elevation only when available', () {
      expect(metric.formatElevation(null), '-');
      expect(metric.formatElevation(123.4), '123 m');
      expect(metric.formatElevation(124.6), '125 m');
      expect(metric.formatElevation(1235, locale: 'en-US'), '1,235 m');
    });
  });

  group('ActivityStatsFormatter (imperial)', () {
    test('formats distances in feet below a mile and miles above', () {
      // 1 mi is exactly 1609.344 m; 100 m is 328.084 ft.
      expect(imperial.formatDistance(100), '328 ft');
      expect(imperial.formatDistance(1609.343), '5280 ft');
      expect(imperial.formatDistance(1609.344), '1.00 mi');
      expect(imperial.formatDistance(5000), '3.11 mi');
      expect(imperial.formatDistance(5000, locale: 'pt-PT'), '3,11 mi');
    });

    test('groups large foot values by locale', () {
      expect(imperial.formatDistance(1000, locale: 'en-US'), '3,281 ft');
    });

    test('formats speed in mph', () {
      expect(imperial.formatSpeed(null), '-');
      // 2 m/s = 4.4739 mph.
      expect(imperial.formatSpeed(2), '4.5 mph');
      expect(imperial.formatSpeed(2, locale: 'pt-PT'), '4,5 mph');
    });

    test('formats pace in min/mi', () {
      expect(imperial.formatPace(null), '-');
      expect(imperial.formatPace(0), '-');
      // 2.5 m/s over 1609.344 m = 643.7 s = 10:44 per mile.
      expect(imperial.formatPace(2.5), '10:44 min/mi');
    });

    test('formats elevation in feet', () {
      expect(imperial.formatElevation(null), '-');
      // 123.4 m = 404.85 ft.
      expect(imperial.formatElevation(123.4), '405 ft');
      expect(imperial.formatElevation(1000, locale: 'en-US'), '3,281 ft');
    });
  });

  group('unit conversions', () {
    test('use exact international definitions', () {
      expect(UnitConversions.metersPerFoot, 0.3048);
      expect(UnitConversions.metersPerMile, 1609.344);
      expect(UnitConversions.metersToMiles(1609.344), closeTo(1, 1e-12));
      expect(UnitConversions.metersToFeet(0.3048), closeTo(1, 1e-12));
      expect(UnitConversions.metersToKilometers(2500), 2.5);
    });
  });
}
