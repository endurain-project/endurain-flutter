/// Whether the sensor reports skin/electrode contact for a measurement.
///
/// Mirrors the "Sensor Contact Status" bits of the BLE Heart Rate Measurement
/// characteristic (GATT `0x2A37`). Straps that do not implement the feature
/// report [notSupported].
enum SensorContactStatus { notSupported, notDetected, detected }

/// A single heart-rate measurement decoded from a BLE Heart Rate Measurement
/// characteristic (GATT `0x2A37`).
///
/// The model stays transport-neutral: the BLE parser produces it and the rest
/// of the app consumes it without depending on the Bluetooth plugin.
class HeartRateSample {
  const HeartRateSample({
    required this.bpm,
    required this.timestamp,
    this.energyExpendedKilojoules,
    this.rrIntervals = const <Duration>[],
    this.sensorContact = SensorContactStatus.notSupported,
  }) : assert(bpm >= 0);

  /// Instantaneous heart rate in beats per minute.
  final int bpm;

  /// When the measurement was received by the app (BLE notifications carry no
  /// timestamp of their own).
  final DateTime timestamp;

  /// Cumulative energy expended in kilojoules, when the sensor reports it.
  final double? energyExpendedKilojoules;

  /// RR-intervals (time between successive heartbeats) for the measurement,
  /// when the sensor reports them. Useful for future HRV features.
  final List<Duration> rrIntervals;

  /// Whether the sensor currently detects skin contact.
  final SensorContactStatus sensorContact;
}
