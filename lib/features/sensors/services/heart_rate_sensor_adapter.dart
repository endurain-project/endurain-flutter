import 'package:endurain/features/sensors/models/ble_sensor_device.dart';
import 'package:endurain/features/sensors/models/heart_rate_sample.dart';
import 'package:endurain/features/sensors/models/sensor_bluetooth_state.dart';
import 'package:endurain/features/sensors/models/sensor_connection_status.dart';

/// Injectable boundary over the platform BLE stack for external heart-rate
/// sensors.
///
/// This is the single seam that touches the Bluetooth plugin. Everything above
/// it (service, controller, UI) depends only on the neutral sensor models, so
/// the rest of the app is testable with a fake adapter and the plugin can be
/// swapped without ripples.
///
/// Implementations manage at most one active connection at a time, which is the
/// common case for a wearable heart-rate strap.
abstract class HeartRateSensorAdapter {
  /// Emits the host Bluetooth adapter state as it changes.
  Stream<SensorBluetoothState> get bluetoothState;

  /// Resolves the current Bluetooth adapter state once.
  Future<SensorBluetoothState> currentBluetoothState();

  /// Requests the runtime permissions needed to scan and connect (Android 12+
  /// `BLUETOOTH_SCAN`/`BLUETOOTH_CONNECT`; iOS Bluetooth authorization).
  ///
  /// Returns `true` when scanning is permitted.
  Future<bool> ensurePermissions();

  /// Starts a scan and emits the cumulative list of discovered heart-rate
  /// sensors (advertising GATT service `0x180D`), strongest signal first.
  ///
  /// The scan stops when the returned stream's subscription is cancelled or
  /// [timeout] elapses.
  Stream<List<BleSensorDevice>> scanForHeartRateSensors({
    Duration timeout = const Duration(seconds: 15),
  });

  /// Stops any in-progress scan.
  Future<void> stopScan();

  /// Emits connection lifecycle transitions for the active device.
  Stream<SensorConnectionStatus> get connectionStatus;

  /// Emits decoded heart-rate measurements from the connected sensor.
  Stream<HeartRateSample> get heartRate;

  /// Connects to [device] and begins streaming heart-rate measurements.
  Future<void> connect(BleSensorDevice device);

  /// Disconnects the active device, if any.
  Future<void> disconnect();

  /// Releases all resources and closes the streams.
  Future<void> dispose();
}

/// A no-op [HeartRateSensorAdapter] for platforms without BLE support (the host
/// test runtime, desktop, web). It reports Bluetooth as unsupported and never
/// emits samples, so the sensor feature degrades gracefully off Android/iOS.
class UnsupportedHeartRateSensorAdapter implements HeartRateSensorAdapter {
  const UnsupportedHeartRateSensorAdapter();

  @override
  Stream<SensorBluetoothState> get bluetoothState =>
      Stream<SensorBluetoothState>.value(SensorBluetoothState.unsupported);

  @override
  Future<SensorBluetoothState> currentBluetoothState() async =>
      SensorBluetoothState.unsupported;

  @override
  Future<bool> ensurePermissions() async => false;

  @override
  Stream<List<BleSensorDevice>> scanForHeartRateSensors({
    Duration timeout = const Duration(seconds: 15),
  }) => const Stream<List<BleSensorDevice>>.empty();

  @override
  Future<void> stopScan() async {}

  @override
  Stream<SensorConnectionStatus> get connectionStatus =>
      const Stream<SensorConnectionStatus>.empty();

  @override
  Stream<HeartRateSample> get heartRate =>
      const Stream<HeartRateSample>.empty();

  @override
  Future<void> connect(BleSensorDevice device) async {}

  @override
  Future<void> disconnect() async {}

  @override
  Future<void> dispose() async {}
}
