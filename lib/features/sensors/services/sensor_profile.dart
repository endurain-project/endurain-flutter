import 'package:endurain/features/sensors/models/sensor_measurement.dart';
import 'package:endurain/features/sensors/services/sensor_measurement_decoder.dart';

/// Describes a BLE GATT sensor profile: which service to scan for and discover,
/// which characteristic carries its measurement, what kind of value it yields,
/// and how to decode its notifications.
///
/// [createDecoder] returns a fresh decoder per connection so stateful profiles
/// (cycling cadence) keep isolated state.
class SensorProfile {
  const SensorProfile({
    required this.serviceUuid,
    required this.measurementCharacteristicUuid,
    required this.kind,
    required this.createDecoder,
  });

  /// The 16-bit GATT service UUID advertised by the sensor (e.g. `1818`).
  final String serviceUuid;

  /// The 16-bit GATT characteristic UUID carrying measurements (e.g. `2A63`).
  final String measurementCharacteristicUuid;

  /// The kind of value this profile produces.
  final SensorMeasurementKind kind;

  /// Builds a fresh decoder for a new connection to this profile.
  final SensorMeasurementDecoder Function() createDecoder;
}

/// The external sensor profiles the app supports, grouped by the measurement
/// they feed on the Sensors screen.
abstract final class SensorProfiles {
  /// Heart Rate (service `0x180D`, Heart Rate Measurement `0x2A37`).
  static const SensorProfile heartRateMonitor = SensorProfile(
    serviceUuid: '180D',
    measurementCharacteristicUuid: '2A37',
    kind: SensorMeasurementKind.heartRate,
    createDecoder: HeartRateMeasurementDecoder.new,
  );

  /// Cycling Power (service `0x1818`, Cycling Power Measurement `0x2A63`).
  static const SensorProfile cyclingPower = SensorProfile(
    serviceUuid: '1818',
    measurementCharacteristicUuid: '2A63',
    kind: SensorMeasurementKind.power,
    createDecoder: CyclingPowerMeasurementDecoder.new,
  );

  /// Cycling Speed and Cadence (service `0x1816`, CSC Measurement `0x2A5B`).
  static const SensorProfile cyclingSpeedCadence = SensorProfile(
    serviceUuid: '1816',
    measurementCharacteristicUuid: '2A5B',
    kind: SensorMeasurementKind.cadence,
    createDecoder: CyclingSpeedCadenceMeasurementDecoder.new,
  );

  /// Running Speed and Cadence (service `0x1814`, RSC Measurement `0x2A53`).
  static const SensorProfile runningSpeedCadence = SensorProfile(
    serviceUuid: '1814',
    measurementCharacteristicUuid: '2A53',
    kind: SensorMeasurementKind.cadence,
    createDecoder: RunningSpeedCadenceMeasurementDecoder.new,
  );

  /// Profiles offered under the "Heart rate" section. A heart-rate strap
  /// advertises the Heart Rate service; there is a single supported profile.
  static const List<SensorProfile> heartRate = <SensorProfile>[
    heartRateMonitor,
  ];

  /// Profiles offered under the "Power" section.
  static const List<SensorProfile> power = <SensorProfile>[cyclingPower];

  /// Profiles offered under the "Cadence" section. A cadence sensor advertises
  /// either the cycling (CSC) or running (RSC) service; the adapter picks
  /// whichever the connected device exposes.
  static const List<SensorProfile> cadence = <SensorProfile>[
    cyclingSpeedCadence,
    runningSpeedCadence,
  ];
}
