import 'package:endurain/features/sensors/models/heart_rate_sample.dart';

/// Decodes the BLE Heart Rate Measurement characteristic (GATT `0x2A37`).
///
/// The wire format is defined by the Bluetooth SIG:
/// - octet 0 is a flags byte,
/// - the heart-rate value is UINT8 or UINT16 (little-endian) per flag bit 0,
/// - optional energy-expended (UINT16, kJ) and RR-interval fields follow.
///
/// Parsing is pure and side-effect free so it is fully unit testable without a
/// Bluetooth stack. Malformed or truncated payloads return `null` rather than
/// throwing, so a single bad notification never crashes the sensor pipeline.
class HeartRateMeasurementParser {
  const HeartRateMeasurementParser._();

  static const int _flagValueIs16Bit = 0x01;
  static const int _flagContactDetected = 0x02;
  static const int _flagContactSupported = 0x04;
  static const int _flagEnergyPresent = 0x08;
  static const int _flagRrPresent = 0x10;

  /// Parses [data] (the raw characteristic bytes) into a [HeartRateSample], or
  /// returns `null` when the payload is empty, truncated, or not byte-valued.
  static HeartRateSample? parse(List<int> data, {DateTime? timestamp}) {
    if (data.isEmpty) {
      return null;
    }
    for (final byte in data) {
      if (byte < 0 || byte > 0xFF) {
        return null;
      }
    }

    final flags = data[0];
    final is16Bit = (flags & _flagValueIs16Bit) != 0;
    final contactSupported = (flags & _flagContactSupported) != 0;
    final contactDetected = (flags & _flagContactDetected) != 0;
    final hasEnergy = (flags & _flagEnergyPresent) != 0;
    final hasRr = (flags & _flagRrPresent) != 0;

    var offset = 1;

    final int bpm;
    if (is16Bit) {
      if (data.length < offset + 2) {
        return null;
      }
      bpm = data[offset] | (data[offset + 1] << 8);
      offset += 2;
    } else {
      if (data.length < offset + 1) {
        return null;
      }
      bpm = data[offset];
      offset += 1;
    }

    double? energyKilojoules;
    if (hasEnergy) {
      if (data.length < offset + 2) {
        return null;
      }
      energyKilojoules = (data[offset] | (data[offset + 1] << 8)).toDouble();
      offset += 2;
    }

    final rrIntervals = <Duration>[];
    if (hasRr) {
      while (offset + 2 <= data.length) {
        final raw = data[offset] | (data[offset + 1] << 8);
        // RR-intervals are expressed in units of 1/1024 second. Convert to
        // microseconds with integer math to avoid floating-point drift.
        rrIntervals.add(Duration(microseconds: (raw * 1000000) ~/ 1024));
        offset += 2;
      }
    }

    final contact = contactSupported
        ? (contactDetected
              ? SensorContactStatus.detected
              : SensorContactStatus.notDetected)
        : SensorContactStatus.notSupported;

    return HeartRateSample(
      bpm: bpm,
      timestamp: timestamp ?? DateTime.now(),
      energyExpendedKilojoules: energyKilojoules,
      rrIntervals: rrIntervals,
      sensorContact: contact,
    );
  }
}
