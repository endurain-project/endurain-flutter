import 'dart:async';

import 'package:endurain/features/sensors/models/ble_sensor_device.dart';
import 'package:endurain/features/sensors/models/sensor_bluetooth_state.dart';
import 'package:endurain/features/sensors/models/sensor_connection_status.dart';
import 'package:endurain/features/sensors/models/sensor_measurement.dart';
import 'package:endurain/features/sensors/repositories/sensor_preferences_repository.dart';
import 'package:endurain/features/sensors/services/sensor_connection_adapter.dart';

/// App-lifetime coordinator for a single external sensor (a heart-rate strap,
/// power meter, or cadence sensor).
///
/// Wraps a [SensorConnectionAdapter] and adds the small amount of state the rest
/// of the app needs: the latest measurement, the current connection status, the
/// connected device, and a remembered device for reconnecting. One instance is
/// created per measurement (heart rate, power, cadence), each remembering its
/// device under a distinct preferences `rememberedKey`.
///
/// It is owned by `AppServices` so a live connection survives navigation between
/// screens. Route controllers observe it; they must not dispose it.
class SensorService {
  SensorService({
    required SensorConnectionAdapter adapter,
    required SensorPreferencesRepository preferences,
    required String rememberedKey,
    bool Function()? canAutoReconnect,
    int autoReconnectAttempts = 4,
    Duration autoReconnectRetryDelay = const Duration(seconds: 2),
  }) : _adapter = adapter,
       _preferences = preferences,
       _rememberedKey = rememberedKey,
       _canAutoReconnect = canAutoReconnect ?? _alwaysAllowReconnect,
       _autoReconnectAttempts = autoReconnectAttempts,
       _autoReconnectRetryDelay = autoReconnectRetryDelay {
    _statusSubscription = _adapter.connectionStatus.listen(_handleStatus);
    _measurementSubscription = _adapter.measurements.listen(_handleMeasurement);
    _bluetoothSubscription = _adapter.bluetoothState.listen(
      _handleBluetoothState,
    );
  }

  static bool _alwaysAllowReconnect() => true;

  final SensorConnectionAdapter _adapter;
  final SensorPreferencesRepository _preferences;
  final String _rememberedKey;

  /// Gate for automatic reconnection. Returns `false` while another owner (the
  /// native recorder during an Android recording) holds the sensor, so
  /// best-effort reconnect attempts never fight that handoff connection.
  final bool Function() _canAutoReconnect;

  /// Auto-connect retry policy. Right after a cold launch the platform may not
  /// yet expose a previously-paired peripheral (on iOS `retrievePeripherals`
  /// returns empty until the central settles), so a single attempt can fail
  /// where a manual retry a moment later succeeds; a few spaced retries make
  /// reconnection reliable without user interaction.
  final int _autoReconnectAttempts;
  final Duration _autoReconnectRetryDelay;
  bool _autoConnectInProgress = false;

  final StreamController<SensorConnectionStatus> _statusController =
      StreamController<SensorConnectionStatus>.broadcast();
  final StreamController<SensorMeasurement> _measurementController =
      StreamController<SensorMeasurement>.broadcast();
  final StreamController<SensorBluetoothState> _bluetoothController =
      StreamController<SensorBluetoothState>.broadcast();

  StreamSubscription<SensorConnectionStatus>? _statusSubscription;
  StreamSubscription<SensorMeasurement>? _measurementSubscription;
  StreamSubscription<SensorBluetoothState>? _bluetoothSubscription;

  SensorConnectionStatus _status = SensorConnectionStatus.disconnected;
  SensorMeasurement? _latestMeasurement;
  BleSensorDevice? _connectedDevice;
  SensorBluetoothState _bluetoothState = SensorBluetoothState.unknown;
  bool _reconnectInProgress = false;

  /// The most recent connection status.
  SensorConnectionStatus get status => _status;

  /// The most recent measurement, or `null` before the first reading.
  SensorMeasurement? get latestMeasurement => _latestMeasurement;

  /// The device currently connected or being connected to, or `null`.
  BleSensorDevice? get connectedDevice => _connectedDevice;

  /// Whether a sensor is currently connected.
  bool get isConnected => _status == SensorConnectionStatus.connected;

  /// Connection status transitions.
  Stream<SensorConnectionStatus> get connectionStatus =>
      _statusController.stream;

  /// Live measurements from the connected sensor.
  Stream<SensorMeasurement> get measurements => _measurementController.stream;

  /// Host Bluetooth adapter state changes.
  Stream<SensorBluetoothState> get bluetoothState =>
      _bluetoothController.stream;

  /// Resolves the current Bluetooth adapter state once.
  Future<SensorBluetoothState> currentBluetoothState() =>
      _adapter.currentBluetoothState();

  /// Requests the runtime permissions needed to scan and connect.
  Future<bool> ensurePermissions() => _adapter.ensurePermissions();

  /// Scans for nearby sensors of this service's kind.
  Stream<List<BleSensorDevice>> scan({
    Duration timeout = const Duration(seconds: 15),
  }) => _adapter.scanForSensors(timeout: timeout);

  /// Stops an in-progress scan.
  Future<void> stopScan() => _adapter.stopScan();

  /// Connects to [device] and remembers it for future reconnects.
  ///
  /// Rethrows if the connection attempt fails, in which case the device is not
  /// remembered.
  Future<void> connect(BleSensorDevice device) async {
    _connectedDevice = device;
    try {
      await _adapter.connect(device);
    } catch (_) {
      _connectedDevice = null;
      rethrow;
    }
    await _preferences.saveRemembered(key: _rememberedKey, device: device);
  }

  /// Disconnects the active sensor without forgetting it.
  Future<void> disconnect() async {
    await _adapter.disconnect();
    _connectedDevice = null;
  }

  /// Returns the remembered sensor, if any.
  Future<BleSensorDevice?> rememberedDevice() =>
      _preferences.getRemembered(key: _rememberedKey);

  /// Whether a sensor has been paired and remembered.
  Future<bool> hasRememberedDevice() async =>
      await _preferences.getRemembered(key: _rememberedKey) != null;

  /// Disconnects and clears the remembered sensor.
  Future<void> forget() async {
    await disconnect();
    await _preferences.clearRemembered(key: _rememberedKey);
  }

  /// Attempts to reconnect to the remembered sensor when Bluetooth is ready.
  ///
  /// Returns `true` when a reconnect was attempted. No-ops (returning `false`)
  /// when an attempt is already in flight, a sensor is already
  /// connected/connecting, nothing is remembered, or Bluetooth is not ready.
  /// Failures are swallowed: automatic reconnection is best-effort.
  Future<bool> tryReconnectRemembered() async {
    if (!_canAutoReconnect() ||
        _reconnectInProgress ||
        _status == SensorConnectionStatus.connected ||
        _status == SensorConnectionStatus.connecting) {
      return false;
    }
    final remembered = await _preferences.getRemembered(key: _rememberedKey);
    if (remembered == null) {
      return false;
    }
    if (await _adapter.currentBluetoothState() != SensorBluetoothState.ready) {
      return false;
    }
    _reconnectInProgress = true;
    try {
      await connect(remembered);
    } catch (_) {
      // Best-effort reconnect.
    } finally {
      _reconnectInProgress = false;
    }
    return true;
  }

  /// Best-effort automatic reconnect for app/screen open.
  ///
  /// Activates the Bluetooth stack — requesting permission is a no-op when it
  /// was already granted for a previously-paired sensor — and reconnects the
  /// remembered sensor. Unlike [tryReconnectRemembered] it does not require the
  /// adapter to already report ready: activating the stack is what transitions
  /// iOS to ready, after which the ready-triggered reconnect (or the immediate
  /// attempt below) establishes the link without the user visiting the Sensors
  /// screen. A no-op when nothing is remembered or a link already exists.
  Future<void> autoConnectRemembered() async {
    if (_autoConnectInProgress ||
        !_canAutoReconnect() ||
        _reconnectInProgress ||
        _status == SensorConnectionStatus.connected ||
        _status == SensorConnectionStatus.connecting) {
      return;
    }
    if (await _preferences.getRemembered(key: _rememberedKey) == null) {
      return;
    }
    _autoConnectInProgress = true;
    try {
      try {
        await _adapter.ensurePermissions();
      } catch (_) {
        // Best-effort activation; the reconnect attempts below still run.
      }
      for (var attempt = 0; attempt < _autoReconnectAttempts; attempt++) {
        if (isConnected) {
          return;
        }
        await tryReconnectRemembered();
        if (isConnected || attempt == _autoReconnectAttempts - 1) {
          return;
        }
        // Give the platform a moment to expose the peripheral before retrying.
        await Future<void>.delayed(_autoReconnectRetryDelay);
      }
    } finally {
      _autoConnectInProgress = false;
    }
  }

  Future<void> dispose() async {
    await _statusSubscription?.cancel();
    await _measurementSubscription?.cancel();
    await _bluetoothSubscription?.cancel();
    await _statusController.close();
    await _measurementController.close();
    await _bluetoothController.close();
    await _adapter.dispose();
  }

  void _handleStatus(SensorConnectionStatus status) {
    _status = status;
    if (status == SensorConnectionStatus.disconnected ||
        status == SensorConnectionStatus.failed) {
      _latestMeasurement = null;
    }
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }

  void _handleMeasurement(SensorMeasurement measurement) {
    _latestMeasurement = measurement;
    if (!_measurementController.isClosed) {
      _measurementController.add(measurement);
    }
  }

  void _handleBluetoothState(SensorBluetoothState state) {
    final previous = _bluetoothState;
    _bluetoothState = state;
    if (!_bluetoothController.isClosed) {
      _bluetoothController.add(state);
    }
    // Re-establish a remembered connection as soon as Bluetooth becomes ready
    // again (the user re-enabled it, or it powered up shortly after launch).
    if (state == SensorBluetoothState.ready &&
        previous != SensorBluetoothState.ready) {
      unawaited(tryReconnectRemembered());
    }
  }
}
