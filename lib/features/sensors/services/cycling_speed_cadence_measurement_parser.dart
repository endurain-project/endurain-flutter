/// The crank-revolution fields decoded from a CSC Measurement notification.
///
/// Cadence is not carried directly by the CSC (Cycling Speed and Cadence)
/// characteristic; it must be derived by differencing the cumulative crank
/// revolution counter and the last crank event time between two consecutive
/// notifications (see `CyclingSpeedCadenceMeasurementDecoder`).
class CscCrankMeasurement {
  const CscCrankMeasurement({
    required this.cumulativeCrankRevolutions,
    required this.lastCrankEventTime,
  });

  /// Cumulative crank revolutions since the sensor powered on (UINT16, wraps).
  final int cumulativeCrankRevolutions;

  /// Time of the last crank event, in units of 1/1024 second (UINT16, wraps).
  final int lastCrankEventTime;
}

/// Decodes the BLE CSC Measurement characteristic (GATT `0x2A5B`, Cycling Speed
/// and Cadence).
///
/// The wire format is defined by the Bluetooth SIG:
/// - octet 0 is a flags byte (bit 0 = wheel data present, bit 1 = crank data
///   present),
/// - optional Wheel Revolution Data (UINT32 revolutions + UINT16 event time),
/// - optional Crank Revolution Data (UINT16 revolutions + UINT16 event time).
///
/// This parser extracts only the crank fields needed for cadence. It is pure
/// and side-effect free; the stateful crank-to-RPM derivation lives in
/// `CyclingSpeedCadenceMeasurementDecoder`. Malformed or truncated payloads
/// return `null` rather than throwing.
class CyclingSpeedCadenceMeasurementParser {
  const CyclingSpeedCadenceMeasurementParser._();

  static const int _flagWheelDataPresent = 0x01;
  static const int _flagCrankDataPresent = 0x02;

  /// Parses [data] into the crank-revolution fields, or returns `null` when the
  /// payload is truncated, not byte-valued, or carries no crank data.
  static CscCrankMeasurement? parseCrank(List<int> data) {
    if (data.isEmpty) {
      return null;
    }
    for (final byte in data) {
      if (byte < 0 || byte > 0xFF) {
        return null;
      }
    }

    final flags = data[0];
    final hasWheel = (flags & _flagWheelDataPresent) != 0;
    final hasCrank = (flags & _flagCrankDataPresent) != 0;
    if (!hasCrank) {
      return null;
    }

    var offset = 1;
    if (hasWheel) {
      // UINT32 cumulative wheel revolutions + UINT16 last wheel event time.
      offset += 6;
    }
    if (data.length < offset + 4) {
      return null;
    }

    final crankRevolutions = data[offset] | (data[offset + 1] << 8);
    final crankEventTime = data[offset + 2] | (data[offset + 3] << 8);
    return CscCrankMeasurement(
      cumulativeCrankRevolutions: crankRevolutions,
      lastCrankEventTime: crankEventTime,
    );
  }
}
