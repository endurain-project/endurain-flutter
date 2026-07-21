import 'package:endurain/features/sensors/models/sensor_measurement.dart';
import 'package:endurain/features/sensors/services/cycling_power_measurement_parser.dart';
import 'package:endurain/features/sensors/services/cycling_speed_cadence_measurement_parser.dart';
import 'package:endurain/features/sensors/services/heart_rate_measurement_parser.dart';
import 'package:endurain/features/sensors/services/running_speed_cadence_measurement_parser.dart';

/// Turns raw BLE characteristic bytes into [SensorMeasurement]s.
///
/// A decoder is created per connection (see `SensorProfile.createDecoder`) so
/// stateful profiles (cycling cadence, which differences consecutive crank
/// samples) keep their state isolated to a single sensor link. `decode` may
/// return an empty list when a notification yields no usable value yet (e.g. the
/// first cadence sample has no prior sample to difference against).
abstract class SensorMeasurementDecoder {
  List<SensorMeasurement> decode(List<int> data, DateTime timestamp);
}

/// Decodes Heart Rate Measurement (`0x2A37`) notifications into heart rate in
/// beats per minute, carrying the optional RR-intervals, sensor-contact status,
/// and energy-expended fields the characteristic can report. Malformed or
/// truncated payloads yield no measurement instead of throwing.
class HeartRateMeasurementDecoder implements SensorMeasurementDecoder {
  @override
  List<SensorMeasurement> decode(List<int> data, DateTime timestamp) {
    final measurement = HeartRateMeasurementParser.parse(
      data,
      timestamp: timestamp,
    );
    if (measurement == null) {
      return const <SensorMeasurement>[];
    }
    return <SensorMeasurement>[measurement];
  }
}

/// Decodes Cycling Power Measurement (`0x2A63`) notifications into power in
/// watts. Negative instantaneous power (some trainers report it while coasting)
/// is clamped to zero so the value is always meaningful to display.
class CyclingPowerMeasurementDecoder implements SensorMeasurementDecoder {
  @override
  List<SensorMeasurement> decode(List<int> data, DateTime timestamp) {
    final watts = CyclingPowerMeasurementParser.parseInstantaneousPowerWatts(
      data,
    );
    if (watts == null) {
      return const <SensorMeasurement>[];
    }
    return <SensorMeasurement>[
      SensorMeasurement(
        kind: SensorMeasurementKind.power,
        value: watts < 0 ? 0 : watts,
        timestamp: timestamp,
      ),
    ];
  }
}

/// Decodes RSC Measurement (`0x2A53`) notifications into running cadence in
/// steps per minute. Cadence is carried directly, so this decoder is stateless.
class RunningSpeedCadenceMeasurementDecoder implements SensorMeasurementDecoder {
  @override
  List<SensorMeasurement> decode(List<int> data, DateTime timestamp) {
    final spm = RunningSpeedCadenceMeasurementParser.parseInstantaneousCadenceSpm(
      data,
    );
    if (spm == null) {
      return const <SensorMeasurement>[];
    }
    return <SensorMeasurement>[
      SensorMeasurement(
        kind: SensorMeasurementKind.cadence,
        value: spm,
        timestamp: timestamp,
      ),
    ];
  }
}

/// Decodes CSC Measurement (`0x2A5B`) notifications into cycling cadence in
/// revolutions per minute.
///
/// Cadence is derived by differencing the cumulative crank revolutions and the
/// last crank event time between consecutive notifications, so this decoder is
/// stateful: the first sample with crank data only establishes a baseline and
/// yields no measurement. Both counters are 16-bit and wrap, which is handled
/// with modular subtraction.
class CyclingSpeedCadenceMeasurementDecoder
    implements SensorMeasurementDecoder {
  static const int _rollover = 0x10000;

  /// One crank event time tick is 1/1024 second; 60 s/min × 1024 ticks/s scales
  /// revolutions-per-tick up to revolutions-per-minute with integer math.
  static const int _ticksPerMinute = 60 * 1024;

  int? _previousCrankRevolutions;
  int? _previousCrankEventTime;

  @override
  List<SensorMeasurement> decode(List<int> data, DateTime timestamp) {
    final crank = CyclingSpeedCadenceMeasurementParser.parseCrank(data);
    if (crank == null) {
      return const <SensorMeasurement>[];
    }

    final previousRevolutions = _previousCrankRevolutions;
    final previousEventTime = _previousCrankEventTime;
    _previousCrankRevolutions = crank.cumulativeCrankRevolutions;
    _previousCrankEventTime = crank.lastCrankEventTime;

    if (previousRevolutions == null || previousEventTime == null) {
      // First crank sample: establish a baseline to difference against.
      return const <SensorMeasurement>[];
    }

    final deltaRevolutions =
        (crank.cumulativeCrankRevolutions - previousRevolutions) % _rollover;
    final deltaTime =
        (crank.lastCrankEventTime - previousEventTime) % _rollover;
    if (deltaTime == 0) {
      // No time elapsed (a duplicate notification, or the rider is coasting and
      // the crank event time has not advanced): no new cadence to report.
      return const <SensorMeasurement>[];
    }

    final rpm = (deltaRevolutions * _ticksPerMinute) ~/ deltaTime;
    return <SensorMeasurement>[
      SensorMeasurement(
        kind: SensorMeasurementKind.cadence,
        value: rpm,
        timestamp: timestamp,
      ),
    ];
  }
}
