/// Neutral view of the host Bluetooth adapter, independent of the BLE plugin.
///
/// The UI uses this to decide whether scanning is possible and what guidance
/// to show (enable Bluetooth, grant permission, unsupported device).
enum SensorBluetoothState {
  /// State not yet determined.
  unknown,

  /// The device has no Bluetooth LE hardware or the platform is unsupported.
  unsupported,

  /// The app lacks the Bluetooth permission required to scan or connect.
  unauthorized,

  /// Bluetooth is supported and permitted but currently turned off.
  off,

  /// Bluetooth is on, permitted, and ready to scan.
  ready,
}
