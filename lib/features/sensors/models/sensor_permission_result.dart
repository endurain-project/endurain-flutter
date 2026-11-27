import 'package:endurain/features/sensors/models/sensor_bluetooth_state.dart';

/// Outcome of asking for the runtime permissions needed to scan and connect.
///
/// Distinguishes a user decision the app can help reverse ([denied], via the
/// system settings) from a device that cannot scan at all ([unavailable]).
enum SensorPermissionResult {
  /// Scanning is permitted.
  granted,

  /// The user (or policy) refused Bluetooth access; only the system settings
  /// can change that once the prompt has been dismissed.
  denied,

  /// Bluetooth LE is unsupported, or the permission request itself failed.
  unavailable;

  /// Maps the adapter state observed right after a permission request.
  ///
  /// An indeterminate [SensorBluetoothState.unknown] counts as [granted]
  /// because some platforms only report an accurate state once scanning
  /// starts; a scan failure then surfaces through the scan stream.
  static SensorPermissionResult fromBluetoothState(SensorBluetoothState state) {
    return switch (state) {
      SensorBluetoothState.unauthorized => denied,
      SensorBluetoothState.unsupported => unavailable,
      SensorBluetoothState.unknown ||
      SensorBluetoothState.off ||
      SensorBluetoothState.ready => granted,
    };
  }

  /// Whether scanning may proceed.
  bool get isGranted => this == granted;
}
