import 'dart:async';

import 'package:endurain/features/sensors/models/ble_sensor_device.dart';
import 'package:endurain/features/sensors/models/sensor_bluetooth_state.dart';
import 'package:endurain/features/sensors/models/sensor_connection_status.dart';
import 'package:endurain/features/sensors/models/sensor_measurement.dart';
import 'package:endurain/features/sensors/services/sensor_connection_adapter.dart';

/// A controllable [SensorConnectionAdapter] for unit tests, standing in for the
/// real BLE stack for cycling/running sensors. Tests drive it by setting the
/// configurable fields and pushing events through the `emit*` helpers.
///
/// The event streams use synchronous broadcast controllers so a pushed event is
/// delivered to the service's listener immediately, keeping widget-test timing
/// deterministic (no reliance on the fake-async microtask clock).
class FakeSensorConnectionAdapter implements SensorConnectionAdapter {
  final StreamController<SensorConnectionStatus> _statusController =
      StreamController<SensorConnectionStatus>.broadcast(sync: true);
  final StreamController<SensorMeasurement> _measurementController =
      StreamController<SensorMeasurement>.broadcast(sync: true);
  final StreamController<SensorBluetoothState> _bluetoothController =
      StreamController<SensorBluetoothState>.broadcast(sync: true);

  SensorBluetoothState bluetoothStateValue = SensorBluetoothState.ready;
  bool permissionGranted = true;

  /// When true, [currentBluetoothState] reports [SensorBluetoothState.unknown]
  /// until [ensurePermissions] has been called, mirroring devices that only
  /// expose an accurate adapter state once the Bluetooth permission is granted.
  bool stateHiddenUntilPermission = false;
  bool connectShouldFail = false;

  /// Number of leading [connect] calls that fail before one succeeds. Models a
  /// peripheral that is not yet reachable right after launch.
  int connectFailuresBeforeSuccess = 0;

  /// When set, [connect] emits `connecting` and waits for this to complete
  /// before resolving, letting a test observe the connecting state.
  Completer<void>? connectGate;
  List<BleSensorDevice> scanDevices = const <BleSensorDevice>[];

  /// The timeout requested for the most recent scan.
  Duration? lastScanTimeout;

  final List<BleSensorDevice> connectCalls = <BleSensorDevice>[];
  int disconnectCalls = 0;
  int stopScanCalls = 0;
  int ensurePermissionsCalls = 0;
  bool _permissionRequested = false;
  bool disposed = false;

  void emitStatus(SensorConnectionStatus status) =>
      _statusController.add(status);
  void emitMeasurement(SensorMeasurement measurement) =>
      _measurementController.add(measurement);
  void emitBluetoothState(SensorBluetoothState state) =>
      _bluetoothController.add(state);

  @override
  Stream<SensorConnectionStatus> get connectionStatus =>
      _statusController.stream;

  @override
  Stream<SensorMeasurement> get measurements => _measurementController.stream;

  @override
  Stream<SensorBluetoothState> get bluetoothState =>
      _bluetoothController.stream;

  @override
  Future<SensorBluetoothState> currentBluetoothState() async {
    if (stateHiddenUntilPermission && !_permissionRequested) {
      return SensorBluetoothState.unknown;
    }
    return bluetoothStateValue;
  }

  @override
  Future<bool> ensurePermissions() async {
    ensurePermissionsCalls++;
    _permissionRequested = true;
    return permissionGranted;
  }

  @override
  Stream<List<BleSensorDevice>> scanForSensors({
    Duration timeout = const Duration(seconds: 15),
  }) async* {
    lastScanTimeout = timeout;
    yield scanDevices;
  }

  @override
  Future<void> stopScan() async {
    stopScanCalls++;
  }

  @override
  Future<void> connect(BleSensorDevice device) async {
    connectCalls.add(device);
    if (connectShouldFail ||
        connectCalls.length <= connectFailuresBeforeSuccess) {
      _statusController.add(SensorConnectionStatus.failed);
      throw StateError('connect failed');
    }
    final gate = connectGate;
    if (gate != null) {
      _statusController.add(SensorConnectionStatus.connecting);
      await gate.future;
    }
    _statusController.add(SensorConnectionStatus.connected);
  }

  @override
  Future<void> disconnect() async {
    disconnectCalls++;
    _statusController.add(SensorConnectionStatus.disconnected);
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    await _statusController.close();
    await _measurementController.close();
    await _bluetoothController.close();
  }
}
