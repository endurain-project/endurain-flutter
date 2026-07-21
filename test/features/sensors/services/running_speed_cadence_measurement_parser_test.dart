import 'package:endurain/features/sensors/services/running_speed_cadence_measurement_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RunningSpeedCadenceMeasurementParser', () {
    test('parses instantaneous cadence in steps per minute', () {
      // Flags (1) + instantaneous speed uint16 (2) + cadence uint8 (1) = 85 spm.
      final data = [0x00, 0x00, 0x02, 85];

      expect(
        RunningSpeedCadenceMeasurementParser.parseInstantaneousCadenceSpm(data),
        85,
      );
    });

    test('reads cadence regardless of optional flag bits', () {
      // Stride length + total distance flags set; cadence is still at offset 3.
      final data = [0x03, 0x00, 0x02, 90, 0x10, 0x00];

      expect(
        RunningSpeedCadenceMeasurementParser.parseInstantaneousCadenceSpm(data),
        90,
      );
    });

    test('returns null for a truncated payload', () {
      expect(
        RunningSpeedCadenceMeasurementParser.parseInstantaneousCadenceSpm([
          0x00,
          0x00,
          0x02,
        ]),
        isNull,
      );
    });

    test('returns null for non-byte values', () {
      expect(
        RunningSpeedCadenceMeasurementParser.parseInstantaneousCadenceSpm([
          0,
          0,
          0,
          300,
        ]),
        isNull,
      );
    });
  });
}
