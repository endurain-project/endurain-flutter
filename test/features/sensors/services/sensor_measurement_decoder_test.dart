import 'package:endurain/features/sensors/models/sensor_measurement.dart';
import 'package:endurain/features/sensors/services/sensor_measurement_decoder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final timestamp = DateTime.utc(2026, 7, 19);

  group('CyclingPowerMeasurementDecoder', () {
    test('decodes power in watts', () {
      final decoder = CyclingPowerMeasurementDecoder();

      final result = decoder.decode([0x00, 0x00, 0xFA, 0x00], timestamp);

      expect(result, hasLength(1));
      expect(result.single.kind, SensorMeasurementKind.power);
      expect(result.single.value, 250);
      expect(result.single.timestamp, timestamp);
    });

    test('clamps negative power to zero', () {
      final decoder = CyclingPowerMeasurementDecoder();

      final result = decoder.decode([0x00, 0x00, 0xFB, 0xFF], timestamp);

      expect(result.single.value, 0);
    });

    test('returns nothing for a truncated payload', () {
      final decoder = CyclingPowerMeasurementDecoder();

      expect(decoder.decode([0x00, 0x00], timestamp), isEmpty);
    });
  });

  group('RunningSpeedCadenceMeasurementDecoder', () {
    test('decodes cadence in steps per minute', () {
      final decoder = RunningSpeedCadenceMeasurementDecoder();

      final result = decoder.decode([0x00, 0x00, 0x02, 85], timestamp);

      expect(result, hasLength(1));
      expect(result.single.kind, SensorMeasurementKind.cadence);
      expect(result.single.value, 85);
    });

    test('returns nothing for a truncated payload', () {
      final decoder = RunningSpeedCadenceMeasurementDecoder();

      expect(decoder.decode([0x00, 0x00, 0x02], timestamp), isEmpty);
    });
  });

  group('CyclingSpeedCadenceMeasurementDecoder', () {
    test('yields no cadence from the first (baseline) sample', () {
      final decoder = CyclingSpeedCadenceMeasurementDecoder();

      final result = decoder.decode([0x02, 100, 0, 0x00, 0x04], timestamp);

      expect(result, isEmpty);
    });

    test('derives cadence by differencing consecutive crank samples', () {
      final decoder = CyclingSpeedCadenceMeasurementDecoder();

      // Baseline: 100 revs at t=1024. Next: 102 revs at t=2048 → 2 revolutions
      // over 1024/1024 s = 1 s → 120 rpm.
      decoder.decode([0x02, 100, 0, 0x00, 0x04], timestamp);
      final result = decoder.decode([0x02, 102, 0, 0x00, 0x08], timestamp);

      expect(result, hasLength(1));
      expect(result.single.kind, SensorMeasurementKind.cadence);
      expect(result.single.value, 120);
    });

    test('reports no cadence when the crank event time has not advanced', () {
      final decoder = CyclingSpeedCadenceMeasurementDecoder();

      decoder.decode([0x02, 102, 0, 0x00, 0x08], timestamp);
      final result = decoder.decode([0x02, 102, 0, 0x00, 0x08], timestamp);

      expect(result, isEmpty);
    });

    test('reports 0 rpm once after coasting past the timeout', () {
      final decoder = CyclingSpeedCadenceMeasurementDecoder();
      const sample = [0x02, 102, 0, 0x00, 0x08];

      decoder.decode([0x02, 100, 0, 0x00, 0x04], timestamp);
      // Last crank event at t+1 s; the rider then stops pedalling.
      final last = timestamp.add(const Duration(seconds: 1));
      expect(decoder.decode(sample, last).single.value, 120);

      // Still within the timeout: nothing new to report.
      expect(
        decoder.decode(sample, last.add(const Duration(seconds: 2))),
        isEmpty,
      );

      // Past the timeout: report 0 rpm so the old cadence does not stick.
      final coasting = decoder.decode(
        sample,
        last.add(const Duration(seconds: 3)),
      );
      expect(coasting.single.value, 0);
      expect(coasting.single.kind, SensorMeasurementKind.cadence);

      // Reported once per coasting stretch.
      expect(
        decoder.decode(sample, last.add(const Duration(seconds: 4))),
        isEmpty,
      );

      // Pedalling again resumes normal cadence.
      final resumed = decoder.decode([
        0x02,
        104,
        0,
        0x00,
        0x0C,
      ], last.add(const Duration(seconds: 5)));
      expect(resumed.single.value, 120);
    });

    test('handles 16-bit rollover of the counters', () {
      final decoder = CyclingSpeedCadenceMeasurementDecoder();

      // Baseline: revs=65534, time=65000. Next: revs=1 (Δ=3), time=488
      // (Δ=1024) → 3 revolutions per second → 180 rpm.
      decoder.decode([0x02, 0xFE, 0xFF, 0xE8, 0xFD], timestamp);
      final result = decoder.decode([0x02, 0x01, 0x00, 0xE8, 0x01], timestamp);

      expect(result.single.value, 180);
    });

    test('ignores notifications without crank data', () {
      final decoder = CyclingSpeedCadenceMeasurementDecoder();

      // Wheel-only measurement (flags 0x01): no cadence to derive.
      expect(
        decoder.decode([0x01, 0x10, 0x00, 0x00, 0x00, 0x00, 0x02], timestamp),
        isEmpty,
      );
    });
  });
}
