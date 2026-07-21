import 'package:endurain/features/sensors/models/sensor_measurement.dart';
import 'package:endurain/features/sensors/services/heart_rate_measurement_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HeartRateMeasurementParser', () {
    final timestamp = DateTime.utc(2026, 7, 16, 8);

    test('parses an 8-bit heart rate value', () {
      final measurement = HeartRateMeasurementParser.parse([
        0x00,
        72,
      ], timestamp: timestamp);

      expect(measurement, isNotNull);
      expect(measurement!.kind, SensorMeasurementKind.heartRate);
      expect(measurement.value, 72);
      expect(measurement.timestamp, timestamp);
      expect(measurement.sensorContact, SensorContactStatus.notSupported);
      expect(measurement.energyExpendedKilojoules, isNull);
      expect(measurement.rrIntervals, isEmpty);
    });

    test('parses a 16-bit heart rate value above 255', () {
      // Flag bit 0 set => UINT16, little-endian 0x012C = 300.
      final measurement = HeartRateMeasurementParser.parse([0x01, 0x2C, 0x01]);

      expect(measurement, isNotNull);
      expect(measurement!.value, 300);
    });

    test('reports sensor contact detected when supported', () {
      // bit1 (detected) + bit2 (supported) = 0x06.
      final measurement = HeartRateMeasurementParser.parse([0x06, 60]);
      expect(measurement!.sensorContact, SensorContactStatus.detected);
    });

    test('reports sensor contact not detected when supported but absent', () {
      // bit2 (supported) only = 0x04.
      final measurement = HeartRateMeasurementParser.parse([0x04, 60]);
      expect(measurement!.sensorContact, SensorContactStatus.notDetected);
    });

    test('parses energy expended in kilojoules', () {
      // bit3 (energy) = 0x08; energy = 0x0010 = 16 kJ.
      final measurement = HeartRateMeasurementParser.parse([
        0x08,
        60,
        0x10,
        0x00,
      ]);
      expect(measurement!.value, 60);
      expect(measurement.energyExpendedKilojoules, 16);
    });

    test('parses RR intervals in units of 1/1024 second', () {
      // bit4 (RR) = 0x10; 0x0400 = 1024 => exactly 1 second.
      final measurement = HeartRateMeasurementParser.parse([
        0x10,
        60,
        0x00,
        0x04,
      ]);
      expect(measurement!.rrIntervals, [const Duration(seconds: 1)]);
    });

    test('parses multiple RR intervals', () {
      final measurement = HeartRateMeasurementParser.parse([
        0x10,
        60,
        0x00,
        0x04, // 1024 => 1s
        0x00,
        0x02, // 512 => 500ms
      ]);
      expect(measurement!.rrIntervals, [
        const Duration(seconds: 1),
        const Duration(milliseconds: 500),
      ]);
    });

    test('parses combined energy and RR interval payloads', () {
      // bits 3+4 = 0x18: 8-bit HR, energy (16 kJ), then one RR interval (1s).
      final measurement = HeartRateMeasurementParser.parse([
        0x18,
        75,
        0x10,
        0x00,
        0x00,
        0x04,
      ]);
      expect(measurement!.value, 75);
      expect(measurement.energyExpendedKilojoules, 16);
      expect(measurement.rrIntervals, [const Duration(seconds: 1)]);
    });

    test('ignores a trailing partial RR interval byte', () {
      final measurement = HeartRateMeasurementParser.parse([
        0x10,
        60,
        0x00,
        0x04, // one complete RR interval
        0x00, // stray trailing byte
      ]);
      expect(measurement!.rrIntervals, [const Duration(seconds: 1)]);
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
