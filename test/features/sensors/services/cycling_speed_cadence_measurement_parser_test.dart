import 'package:endurain/features/sensors/services/cycling_speed_cadence_measurement_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CyclingSpeedCadenceMeasurementParser', () {
    test('parses crank data when only crank data is present', () {
      // Flags 0x02 (crank present), cumulative crank revolutions = 100,
      // last crank event time = 1024 (0x0400), both little-endian.
      final data = [0x02, 100, 0, 0x00, 0x04];

      final crank = CyclingSpeedCadenceMeasurementParser.parseCrank(data);

      expect(crank, isNotNull);
      expect(crank!.cumulativeCrankRevolutions, 100);
      expect(crank.lastCrankEventTime, 1024);
    });

    test('skips wheel data to read crank data when both are present', () {
      // Flags 0x03 (wheel + crank). Wheel: uint32 revs + uint16 time = 6 bytes.
      // Then crank revs = 50, crank time = 2048 (0x0800).
      final data = [
        0x03,
        0x10, 0x00, 0x00, 0x00, // wheel revolutions (uint32)
        0x00, 0x02, // wheel event time (uint16)
        50, 0x00, // crank revolutions
        0x00, 0x08, // crank event time = 2048
      ];

      final crank = CyclingSpeedCadenceMeasurementParser.parseCrank(data);

      expect(crank, isNotNull);
      expect(crank!.cumulativeCrankRevolutions, 50);
      expect(crank.lastCrankEventTime, 2048);
    });

    test('returns null when no crank data is present', () {
      // Flags 0x01 (wheel only) — no cadence to derive.
      final data = [0x01, 0x10, 0x00, 0x00, 0x00, 0x00, 0x02];

      expect(CyclingSpeedCadenceMeasurementParser.parseCrank(data), isNull);
    });

    test('returns null for an empty payload', () {
      expect(CyclingSpeedCadenceMeasurementParser.parseCrank([]), isNull);
    });

    test('returns null when crank data is truncated', () {
      // Crank flag set but not enough bytes for revs + time.
      final data = [0x02, 50, 0x00];

      expect(CyclingSpeedCadenceMeasurementParser.parseCrank(data), isNull);
    });

    test('returns null for non-byte values', () {
      expect(
        CyclingSpeedCadenceMeasurementParser.parseCrank([0x02, 300, 0, 0, 0]),
        isNull,
      );
    });
  });
}
