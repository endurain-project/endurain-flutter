/// A discovered BLE sensor peripheral.
///
/// [id] is the platform device identifier (a MAC-style address on Android, an
/// opaque UUID on iOS/macOS) and is stable enough to persist for reconnecting
/// to a remembered sensor. [name] is the advertised device name and may be
/// empty for sensors that do not advertise one.
class BleSensorDevice {
  const BleSensorDevice({required this.id, required this.name, this.rssi});

  final String id;
  final String name;

  /// Advertised signal strength in dBm, used to sort scan results by proximity.
  /// `null` when the platform does not report it.
  final int? rssi;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is BleSensorDevice && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
