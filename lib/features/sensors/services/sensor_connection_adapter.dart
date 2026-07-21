import 'package:endurain/features/sensors/models/ble_sensor_device.dart';
import 'package:endurain/features/sensors/models/sensor_bluetooth_state.dart';
import 'package:endurain/features/sensors/models/sensor_connection_status.dart';
import 'package:endurain/features/sensors/models/sensor_measurement.dart';

/// Injectable boundary over the platform BLE stack for a single external
/// cycling/running sensor (power meter or cadence sensor).
///
/// This mirrors the heart-rate adapter seam but is profile-driven: an instance
/// is created for a set of `SensorProfile`s (e.g. the power profiles, or the
/// cadence profiles) and manages at most one connection at a time. Two adapter
/// instances therefore back two simultaneous connections (a power meter and a
/// cadence sensor), while everything above the seam depends only on the neutral
/// sensor models and is testable with a fake.
abstract class SensorConnectionAdapter {
  /// Emits the host Bluetooth adapter state as it changes.
  Stream<SensorBluetoothState> get bluetoothState;

  /// Resolves the current Bluetooth adapter state once.
  Future<SensorBluetoothState> currentBluetoothState();

  /// Requests the runtime permissions needed to scan and connect.
  ///
  /// Returns `true` when scanning is permitted.
  Future<bool> ensurePermissions();

  /// Starts a scan and emits the cumulative list of discovered sensors
  /// advertising any of this adapter's profiles' services, strongest signal
  /// first. The scan stops when the returned stream's subscription is cancelled
  /// or [timeout] elapses.
  Stream<List<BleSensorDevice>> scanForSensors({
    Duration timeout = const Duration(seconds: 15),
  });

  /// Stops any in-progress scan.
  Future<void> stopScan();

  /// Emits connection lifecycle transitions for the active device.
  Stream<SensorConnectionStatus> get connectionStatus;

  /// Emits decoded measurements from the connected sensor.
  Stream<SensorMeasurement> get measurements;

  /// Connects to [device], discovers which supported profile it exposes, and
  /// begins streaming its measurements.
  Future<void> connect(BleSensorDevice device);

  /// Disconnects the active device, if any.
  Future<void> disconnect();

  /// Releases all resources and closes the streams.
  Future<void> dispose();
}

/// A no-op [SensorConnectionAdapter] for platforms without BLE support (the host
/// test runtime, desktop, web). It reports Bluetooth as unsupported and never
/// emits measurements, so the sensor feature degrades gracefully off
/// Android/iOS.
class UnsupportedSensorConnectionAdapter implements SensorConnectionAdapter {
  const UnsupportedSensorConnectionAdapter();

  @override
  Stream<SensorBluetoothState> get bluetoothState =>
      Stream<SensorBluetoothState>.value(SensorBluetoothState.unsupported);

  @override
  Future<SensorBluetoothState> currentBluetoothState() async =>
      SensorBluetoothState.unsupported;

  @override
  Future<bool> ensurePermissions() async => false;

  @override
  Stream<List<BleSensorDevice>> scanForSensors({
    Duration timeout = const Duration(seconds: 15),
  }) => const Stream<List<BleSensorDevice>>.empty();

  @override
  Future<void> stopScan() async {}

  @override
  Stream<SensorConnectionStatus> get connectionStatus =>
      const Stream<SensorConnectionStatus>.empty();

  @override
  Stream<SensorMeasurement> get measurements =>
      const Stream<SensorMeasurement>.empty();

  @override
  Future<void> connect(BleSensorDevice device) async {}

  @override
  Future<void> disconnect() async {}

  @override
  Future<void> dispose() async {}
}
