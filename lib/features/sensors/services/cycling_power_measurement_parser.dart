/// Decodes the BLE Cycling Power Measurement characteristic (GATT `0x2A63`).
///
/// The wire format is defined by the Bluetooth SIG:
/// - octets 0-1 are a UINT16 flags field (little-endian),
/// - octets 2-3 are the Instantaneous Power as a SINT16 in watts (little-endian).
///
/// Optional fields (pedal power balance, accumulated torque, wheel/crank
/// revolution data) follow the mandatory power value and are not needed to read
/// instantaneous power, so they are ignored here.
///
/// Parsing is pure and side-effect free so it is fully unit testable without a
/// Bluetooth stack. Malformed or truncated payloads return `null` rather than
/// throwing, so a single bad notification never crashes the sensor pipeline.
class CyclingPowerMeasurementParser {
  const CyclingPowerMeasurementParser._();

  /// Parses [data] (the raw characteristic bytes) into the instantaneous power
  /// in watts, or returns `null` when the payload is truncated or not
  /// byte-valued.
  ///
  /// The value is signed on the wire (trainers can report negative power while
  /// coasting); callers clamp as needed.
  static int? parseInstantaneousPowerWatts(List<int> data) {
    if (data.length < 4) {
      return null;
    }
    for (final byte in data) {
      if (byte < 0 || byte > 0xFF) {
        return null;
      }
    }
    final raw = data[2] | (data[3] << 8);
    return _toSigned16(raw);
  }

  static int _toSigned16(int value) =>
      (value & 0x8000) != 0 ? value - 0x10000 : value;
}
