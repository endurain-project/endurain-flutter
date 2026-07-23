import 'package:endurain/features/sensors/services/cycling_power_measurement_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CyclingPowerMeasurementParser', () {
    test('parses instantaneous power from the mandatory fields', () {
      // Flags (uint16) then instantaneous power (sint16, little-endian) = 250 W.
      final data = [0x00, 0x00, 0xFA, 0x00];

      expect(
        CyclingPowerMeasurementParser.parseInstantaneousPowerWatts(data),
        250,
      );
    });

    test('parses power regardless of the optional flag bits', () {
      // Flags with several optional-field bits set; power is still at offset 2.
      final data = [0x30, 0x00, 0x2C, 0x01, 0x11, 0x22];

      expect(
        CyclingPowerMeasurementParser.parseInstantaneousPowerWatts(data),
        300,
      );
    });

    test('decodes negative power as a signed value', () {
      // 0xFFFB little-endian = -5 W.
      final data = [0x00, 0x00, 0xFB, 0xFF];

      expect(
        CyclingPowerMeasurementParser.parseInstantaneousPowerWatts(data),
        -5,
      );
    });

    test('returns null for a truncated payload', () {
      expect(
        CyclingPowerMeasurementParser.parseInstantaneousPowerWatts([
          0x00,
          0x00,
        ]),
        isNull,
      );
    });

    test('returns null for non-byte values', () {
      expect(
        CyclingPowerMeasurementParser.parseInstantaneousPowerWatts([
          0,
          0,
          256,
          0,
        ]),
        isNull,
      );
    });
  });
}
