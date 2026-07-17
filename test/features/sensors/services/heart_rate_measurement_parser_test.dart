import 'package:endurain/features/sensors/models/heart_rate_sample.dart';
import 'package:endurain/features/sensors/services/heart_rate_measurement_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HeartRateMeasurementParser', () {
    final timestamp = DateTime.utc(2026, 7, 16, 8);

    test('parses an 8-bit heart rate value', () {
      final sample = HeartRateMeasurementParser.parse([
        0x00,
        72,
      ], timestamp: timestamp);

      expect(sample, isNotNull);
      expect(sample!.bpm, 72);
      expect(sample.timestamp, timestamp);
      expect(sample.sensorContact, SensorContactStatus.notSupported);
      expect(sample.energyExpendedKilojoules, isNull);
      expect(sample.rrIntervals, isEmpty);
    });

    test('parses a 16-bit heart rate value above 255', () {
      // Flag bit 0 set => UINT16, little-endian 0x012C = 300.
      final sample = HeartRateMeasurementParser.parse([0x01, 0x2C, 0x01]);

      expect(sample, isNotNull);
      expect(sample!.bpm, 300);
    });

    test('reports sensor contact detected when supported', () {
      // bit1 (detected) + bit2 (supported) = 0x06.
      final sample = HeartRateMeasurementParser.parse([0x06, 60]);
      expect(sample!.sensorContact, SensorContactStatus.detected);
    });

    test('reports sensor contact not detected when supported but absent', () {
      // bit2 (supported) only = 0x04.
      final sample = HeartRateMeasurementParser.parse([0x04, 60]);
      expect(sample!.sensorContact, SensorContactStatus.notDetected);
    });

    test('parses energy expended in kilojoules', () {
      // bit3 (energy) = 0x08; energy = 0x0010 = 16 kJ.
      final sample = HeartRateMeasurementParser.parse([0x08, 60, 0x10, 0x00]);
      expect(sample!.bpm, 60);
      expect(sample.energyExpendedKilojoules, 16);
    });

    test('parses RR intervals in units of 1/1024 second', () {
      // bit4 (RR) = 0x10; 0x0400 = 1024 => exactly 1 second.
      final sample = HeartRateMeasurementParser.parse([0x10, 60, 0x00, 0x04]);
      expect(sample!.rrIntervals, [const Duration(seconds: 1)]);
    });

    test('parses multiple RR intervals', () {
      final sample = HeartRateMeasurementParser.parse([
        0x10,
        60,
        0x00,
        0x04, // 1024 => 1s
        0x00,
        0x02, // 512 => 500ms
      ]);
      expect(sample!.rrIntervals, [
        const Duration(seconds: 1),
        const Duration(milliseconds: 500),
      ]);
    });

    test('parses combined energy and RR interval payloads', () {
      // bits 3+4 = 0x18: 8-bit HR, energy (16 kJ), then one RR interval (1s).
      final sample = HeartRateMeasurementParser.parse([
        0x18,
        75,
        0x10,
        0x00,
        0x00,
        0x04,
      ]);
      expect(sample!.bpm, 75);
      expect(sample.energyExpendedKilojoules, 16);
      expect(sample.rrIntervals, [const Duration(seconds: 1)]);
    });

    test('ignores a trailing partial RR interval byte', () {
      final sample = HeartRateMeasurementParser.parse([
        0x10,
        60,
        0x00,
        0x04, // one complete RR interval
        0x00, // stray trailing byte
      ]);
      expect(sample!.rrIntervals, [const Duration(seconds: 1)]);
    });

    test('returns null for empty payloads', () {
      expect(HeartRateMeasurementParser.parse(const []), isNull);
    });

    test('returns null for a truncated 16-bit value', () {
      expect(HeartRateMeasurementParser.parse([0x01, 0x2C]), isNull);
    });

    test('returns null for a truncated energy field', () {
      expect(HeartRateMeasurementParser.parse([0x08, 60, 0x10]), isNull);
    });

    test('returns null for non-byte values', () {
      expect(HeartRateMeasurementParser.parse([0x00, 300]), isNull);
    });
  });
}
