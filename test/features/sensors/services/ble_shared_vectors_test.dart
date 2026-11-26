import 'dart:convert';
import 'dart:io';

import 'package:endurain/features/sensors/services/cycling_power_measurement_parser.dart';
import 'package:endurain/features/sensors/services/cycling_speed_cadence_measurement_parser.dart';
import 'package:endurain/features/sensors/services/heart_rate_measurement_parser.dart';
import 'package:flutter_test/flutter_test.dart';

// The same vectors run against the Kotlin GATT clients (see the
// `kotlinFunction` key in each file), keeping both decoders on one wire format.

Map<String, dynamic> _load(String name) =>
    jsonDecode(File('test/fixtures/$name').readAsStringSync())
        as Map<String, dynamic>;

List<Map<String, dynamic>> _list(Map<String, dynamic> json, String key) => [
  for (final item in json[key] as List<dynamic>? ?? const [])
    item as Map<String, dynamic>,
];

List<int> _bytes(String hex) => [
  for (var i = 0; i < hex.length; i += 2)
    int.parse(hex.substring(i, i + 2), radix: 16),
];

void main() {
  group('shared BLE heart rate vectors', () {
    final json = _load('ble_heart_rate_vectors.json');
    for (final spec in _list(json, 'cases')) {
      test(spec['name'] as String, () {
        final measurement = HeartRateMeasurementParser.parse(
          _bytes(spec['hex'] as String),
        );
        final bpm = spec['bpm'] as int?;
        expect(measurement?.value, bpm);
        final dartOnly = spec['dartOnly'] as Map<String, dynamic>?;
        if (dartOnly == null) return;
        expect(measurement!.sensorContact.name, dartOnly['sensorContact']);
        expect(
          measurement.energyExpendedKilojoules,
          (dartOnly['energyKilojoules'] as num?)?.toDouble(),
        );
        expect(
          measurement.rrIntervals.map((d) => d.inMicroseconds).toList(),
          dartOnly['rrIntervalsMicros'],
        );
      });
    }
  });

  group('shared BLE cycling speed and cadence vectors', () {
    final json = _load('ble_cycling_speed_cadence_vectors.json');
    for (final spec in _list(json, 'cases')) {
      test(spec['name'] as String, () {
        final crank = CyclingSpeedCadenceMeasurementParser.parseCrank(
          _bytes(spec['hex'] as String),
        );
        expect(crank?.cumulativeCrankRevolutions, spec['crankRevolutions']);
        expect(crank?.lastCrankEventTime, spec['lastCrankEventTime']);
      });
    }
  });

  group('shared BLE cycling power vectors', () {
    final json = _load('ble_cycling_power_vectors.json');
    for (final spec in _list(json, 'cases')) {
      test(spec['name'] as String, () {
        final signed =
            CyclingPowerMeasurementParser.parseInstantaneousPowerWatts(
              _bytes(spec['hex'] as String),
            );
        final dartOnly = spec['dartOnly'] as Map<String, dynamic>?;
        expect(signed, dartOnly?['signedWatts']);
        // Kotlin clamps negative power to zero; Dart's callers do the same.
        expect(
          signed == null ? null : (signed < 0 ? 0 : signed),
          spec['watts'],
        );
      });
    }
  });
}
