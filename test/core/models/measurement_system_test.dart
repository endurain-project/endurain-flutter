import 'dart:ui';

import 'package:endurain/core/models/measurement_system.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MeasurementSystem.fromJson', () {
    test('parses known values', () {
      expect(MeasurementSystem.fromJson('metric'), MeasurementSystem.metric);
      expect(
        MeasurementSystem.fromJson('imperial'),
        MeasurementSystem.imperial,
      );
    });

    test('returns null for absent or unknown values', () {
      // Null means "follow the device region", so an unrecognised stored value
      // must not silently pin the user to one system.
      expect(MeasurementSystem.fromJson(null), isNull);
      expect(MeasurementSystem.fromJson(''), isNull);
      expect(MeasurementSystem.fromJson('METRIC'), isNull);
      expect(MeasurementSystem.fromJson('us_customary'), isNull);
      expect(MeasurementSystem.fromJson(42), isNull);
    });

    test('round-trips through toJson', () {
      for (final system in MeasurementSystem.values) {
        expect(MeasurementSystem.fromJson(system.toJson()), system);
      }
    });
  });

  group('MeasurementSystem.forLocale', () {
    test('defaults to metric without a locale or region', () {
      expect(MeasurementSystem.forLocale(null), MeasurementSystem.metric);
      expect(
        MeasurementSystem.forLocale(const Locale('en')),
        MeasurementSystem.metric,
      );
    });

    test('uses imperial for imperial regions', () {
      for (final region in ['US', 'GB', 'LR', 'MM', 'PR', 'GU']) {
        expect(
          MeasurementSystem.forLocale(Locale('en', region)),
          MeasurementSystem.imperial,
          reason: '$region should be imperial',
        );
      }
    });

    test('uses metric elsewhere, including other English regions', () {
      for (final locale in [
        const Locale('en', 'AU'),
        const Locale('en', 'IE'),
        const Locale('pt', 'PT'),
        const Locale('de', 'DE'),
        const Locale('fr', 'CA'),
      ]) {
        expect(
          MeasurementSystem.forLocale(locale),
          MeasurementSystem.metric,
          reason: '$locale should be metric',
        );
      }
    });

    test('is case-insensitive on the region subtag', () {
      expect(
        MeasurementSystem.forLocale(const Locale('en', 'us')),
        MeasurementSystem.imperial,
      );
    });
  });
}
