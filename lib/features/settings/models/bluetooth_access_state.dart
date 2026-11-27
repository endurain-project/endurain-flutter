/// Neutral view of the app's Bluetooth access, as the Device access screen
/// shows it.
///
/// The settings feature does not depend on the sensors feature; the
/// composition root maps the sensors' Bluetooth state onto this.
enum BluetoothAccessState {
  /// Allowed and the adapter is on.
  ready,

  /// Allowed, but Bluetooth is turned off.
  off,

  /// The permission has not been decided yet; asking can show the prompt.
  notDetermined,

  /// The user refused the permission; only system settings can change that.
  blocked,

  /// The device has no Bluetooth Low Energy support.
  unavailable,
}
