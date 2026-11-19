import 'package:endurain/features/sensors/services/ble_payload.dart';

/// Decodes the BLE RSC Measurement characteristic (GATT `0x2A53`, Running Speed
/// and Cadence).
///
/// The wire format is defined by the Bluetooth SIG:
/// - octet 0 is a flags byte,
/// - octets 1-2 are the Instantaneous Speed (UINT16, units of 1/256 m/s),
/// - octet 3 is the Instantaneous Cadence (UINT8, in steps per minute).
///
/// Cadence is reported directly (unlike cycling cadence, which must be derived
/// from revolution counters), so parsing is pure and stateless. Malformed or
/// truncated payloads return `null` rather than throwing.
class RunningSpeedCadenceMeasurementParser {
  const RunningSpeedCadenceMeasurementParser._();

  /// Parses [data] into the instantaneous cadence in steps per minute, or
  /// returns `null` when the payload is truncated or not byte-valued.
  static int? parseInstantaneousCadenceSpm(List<int> data) {
    if (data.length < 4) {
      return null;
    }
    if (!isByteValuedPayload(data)) {
      return null;
    }
    return data[3];
  }
}
