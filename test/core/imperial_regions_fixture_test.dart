import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:endurain/core/models/measurement_system.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // The Wear OS app keeps its own copy of the imperial regions
  // (WorkoutFormat.IMPERIAL_REGIONS) and checks it against the same file.
  test('MeasurementSystem.forLocale imperial regions match the fixture', () {
    final json = jsonDecode(
      File('test/fixtures/imperial_regions.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final fixture = (json['regions'] as List<dynamic>).cast<String>().toSet();

    // The region list is private, so probe every two-letter region code.
    final actual = <String>{};
    for (var a = 0x41; a <= 0x5A; a++) {
      for (var b = 0x41; b <= 0x5A; b++) {
        final region = String.fromCharCodes([a, b]);
        final locale = Locale('en', region);
        // Flutter canonicalizes deprecated regions (BU becomes MM), which
        // would list the alias as well; the canonical code is counted once.
        if (locale.countryCode == region &&
            MeasurementSystem.forLocale(locale) == MeasurementSystem.imperial) {
          actual.add(region);
        }
      }
    }

    expect(actual, fixture);
  });
}
