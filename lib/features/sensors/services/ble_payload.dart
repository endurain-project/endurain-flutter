/// Whether every element of [data] is a valid unsigned byte (`0..255`).
///
/// BLE notification payloads arrive from the platform as `List<int>`, which the
/// type system does not constrain to byte range. Every GATT parser rejects an
/// out-of-range payload rather than decoding it into a garbage reading, so the
/// check lives here once instead of in each parser.
bool isByteValuedPayload(List<int> data) {
  for (final byte in data) {
    if (byte < 0 || byte > 0xFF) {
      return false;
    }
  }
  return true;
}
