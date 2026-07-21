/// The kind of value an external sensor reports. Use this enum inside the
/// sensors/BLE layer.
///
/// All external sensors — heart rate, power, and cadence — flow through the
/// generic sensor pipeline and are decoded into a [SensorMeasurement]. The
/// activity/recording layer deliberately does not depend on this enum; it has
/// its own `RecordedSensorKind`, and the composition root (`ActivityModule`)
/// maps one to the other. Keep the two enums in sync when adding a kind.
enum SensorMeasurementKind {
  /// Instantaneous heart rate in beats per minute (Heart Rate, GATT `0x180D`).
  heartRate,

  /// Instantaneous mechanical power in watts (Cycling Power, GATT `0x1818`).
  power,

  /// Instantaneous cadence — crank revolutions per minute for cycling
  /// (CSC, GATT `0x1816`) or steps per minute for running (RSC, GATT `0x1814`).
  cadence,
}

/// Whether a sensor reports skin/electrode contact for a measurement.
///
/// Mirrors the "Sensor Contact Status" bits of the BLE Heart Rate Measurement
/// characteristic (GATT `0x2A37`). Sensors that do not implement the feature —
/// and every non-heart-rate sensor — report [notSupported].
enum SensorContactStatus { notSupported, notDetected, detected }

/// A single decoded measurement from an external sensor.
///
/// The model stays transport-neutral: the BLE decoders produce it and the rest
/// of the app consumes it without depending on the Bluetooth plugin. [value] is
/// always non-negative (bpm, watts, or revolutions/steps per minute).
///
/// The heart-rate-specific fields ([rrIntervals], [sensorContact], and
/// [energyExpendedKilojoules]) carry the extra data the Heart Rate Measurement
/// characteristic can report. They take their neutral defaults (empty,
/// [SensorContactStatus.notSupported], and `null`) for power and cadence
/// measurements, which never populate them.
class SensorMeasurement {
  const SensorMeasurement({
    required this.kind,
    required this.value,
    required this.timestamp,
    this.rrIntervals = const <Duration>[],
    this.sensorContact = SensorContactStatus.notSupported,
    this.energyExpendedKilojoules,
  }) : assert(value >= 0);

  /// What the measurement represents (heart rate, power, or cadence).
  final SensorMeasurementKind kind;

  /// The measured value: bpm for [SensorMeasurementKind.heartRate], watts for
  /// [SensorMeasurementKind.power], revolutions or steps per minute for
  /// [SensorMeasurementKind.cadence].
  final int value;

  /// When the measurement was received by the app (BLE notifications carry no
  /// timestamp of their own).
  final DateTime timestamp;

  /// RR-intervals (time between successive heartbeats) reported alongside a
  /// heart-rate measurement, when the sensor provides them. Useful for future
  /// HRV features. Always empty for non-heart-rate measurements.
  final List<Duration> rrIntervals;

  /// Whether the sensor currently detects skin contact. Always
  /// [SensorContactStatus.notSupported] for non-heart-rate measurements.
  final SensorContactStatus sensorContact;

  /// Cumulative energy expended in kilojoules, when a heart-rate sensor reports
  /// it. Always `null` for non-heart-rate measurements.
  final double? energyExpendedKilojoules;
}
