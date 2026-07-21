import 'package:endurain/features/sensors/models/ble_sensor_device.dart';
import 'package:endurain/features/sensors/models/sensor_bluetooth_state.dart';
import 'package:endurain/features/sensors/models/sensor_connection_status.dart';
import 'package:flutter/foundation.dart';

/// The read/observe surface a Sensors-screen section needs from its controller.
///
/// Every section — heart rate, power, and cadence — is driven by a
/// `SensorSectionController` that implements this surface, so the screen renders
/// each section with one shared builder regardless of measurement kind. It
/// extends [Listenable] so the screen can merge sections into a single rebuild
/// signal.
abstract class SensorSectionView implements Listenable {
  /// Host Bluetooth adapter availability.
  SensorBluetoothState get bluetoothState;

  /// Whether the initial Bluetooth availability check is still in progress.
  bool get isCheckingBluetooth;

  /// The current connection status for this section's sensor.
  SensorConnectionStatus get connectionStatus;

  /// Devices discovered by the most recent scan.
  List<BleSensorDevice> get scanResults;

  /// Whether a scan is currently running.
  bool get isScanning;

  /// Whether the last scan attempt was blocked by a denied permission.
  bool get permissionDenied;

  /// The remembered sensor for this section, or `null`.
  BleSensorDevice? get rememberedDevice;

  /// The connected (or connecting) sensor for this section, or `null`.
  BleSensorDevice? get connectedDevice;

  /// The latest measurement value (bpm, watts, or rpm), or `null`.
  int? get currentValue;

  /// Requests permission if needed, then scans for nearby sensors.
  Future<void> startScan();

  /// Stops an in-progress scan.
  Future<void> stopScan();

  /// Connects to [device] and remembers it.
  Future<void> connect(BleSensorDevice device);

  /// Disconnects the active sensor without forgetting it.
  Future<void> disconnect();

  /// Disconnects and forgets the remembered sensor.
  Future<void> forget();
}
