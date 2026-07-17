import 'dart:async';

import 'package:endurain/features/sensors/models/ble_sensor_device.dart';
import 'package:endurain/features/sensors/models/heart_rate_sample.dart';
import 'package:endurain/features/sensors/models/sensor_bluetooth_state.dart';
import 'package:endurain/features/sensors/models/sensor_connection_status.dart';
import 'package:endurain/features/sensors/repositories/sensor_preferences_repository.dart';
import 'package:endurain/features/sensors/services/heart_rate_sensor_adapter.dart';

/// App-lifetime coordinator for the external heart-rate sensor.
///
/// Wraps the [HeartRateSensorAdapter] boundary and adds the small amount of
/// state the rest of the app needs: the latest sample, the current connection
/// status, the connected device, and a remembered device for reconnecting.
///
/// It is owned by `AppServices` so a live sensor connection survives navigation
/// between screens and is available to the recording pipeline later. Route
/// controllers observe it; they must not dispose it.
class HeartRateSensorService {
  HeartRateSensorService({
    required HeartRateSensorAdapter adapter,
    required SensorPreferencesRepository preferences,
    bool Function()? canAutoReconnect,
    int autoReconnectAttempts = 4,
    Duration autoReconnectRetryDelay = const Duration(seconds: 2),
  }) : _adapter = adapter,
       _preferences = preferences,
       _canAutoReconnect = canAutoReconnect ?? _alwaysAllowReconnect,
       _autoReconnectAttempts = autoReconnectAttempts,
       _autoReconnectRetryDelay = autoReconnectRetryDelay {
    _statusSubscription = _adapter.connectionStatus.listen(_handleStatus);
    _sampleSubscription = _adapter.heartRate.listen(_handleSample);
    _bluetoothSubscription = _adapter.bluetoothState.listen(
      _handleBluetoothState,
    );
  }

  static bool _alwaysAllowReconnect() => true;

  final HeartRateSensorAdapter _adapter;
  final SensorPreferencesRepository _preferences;

  /// Gate for automatic reconnection. Returns `false` while another owner (the
  /// native recorder during a recording) holds the sensor, so best-effort
  /// reconnect attempts never fight that handoff connection.
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
  final StreamController<HeartRateSample> _sampleController =
      StreamController<HeartRateSample>.broadcast();
  final StreamController<SensorBluetoothState> _bluetoothController =
      StreamController<SensorBluetoothState>.broadcast();

  StreamSubscription<SensorConnectionStatus>? _statusSubscription;
  StreamSubscription<HeartRateSample>? _sampleSubscription;
  StreamSubscription<SensorBluetoothState>? _bluetoothSubscription;

  SensorConnectionStatus _status = SensorConnectionStatus.disconnected;
  HeartRateSample? _latestSample;
  BleSensorDevice? _connectedDevice;
  SensorBluetoothState _bluetoothState = SensorBluetoothState.unknown;
  bool _reconnectInProgress = false;

  /// The most recent connection status.
  SensorConnectionStatus get status => _status;

  /// The most recent heart-rate sample, or `null` before the first reading.
  HeartRateSample? get latestSample => _latestSample;

  /// The device currently connected or being connected to, or `null`.
  BleSensorDevice? get connectedDevice => _connectedDevice;

  /// Whether a sensor is currently connected.
  bool get isConnected => _status == SensorConnectionStatus.connected;

  /// Connection status transitions.
  Stream<SensorConnectionStatus> get connectionStatus =>
      _statusController.stream;

  /// Live heart-rate measurements from the connected sensor.
  Stream<HeartRateSample> get heartRate => _sampleController.stream;

  /// Host Bluetooth adapter state changes.
  Stream<SensorBluetoothState> get bluetoothState =>
      _bluetoothController.stream;

  /// Resolves the current Bluetooth adapter state once.
  Future<SensorBluetoothState> currentBluetoothState() =>
      _adapter.currentBluetoothState();

  /// Requests the runtime permissions needed to scan and connect.
  Future<bool> ensurePermissions() => _adapter.ensurePermissions();

  /// Scans for nearby heart-rate sensors.
  Stream<List<BleSensorDevice>> scan({
    Duration timeout = const Duration(seconds: 15),
  }) => _adapter.scanForHeartRateSensors(timeout: timeout);

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
    await _preferences.saveRememberedDevice(device);
  }

  /// Disconnects the active sensor without forgetting it.
  Future<void> disconnect() async {
    await _adapter.disconnect();
    _connectedDevice = null;
  }

  /// Returns the remembered heart-rate sensor, if any.
  Future<BleSensorDevice?> rememberedDevice() =>
      _preferences.getRememberedDevice();

  /// Disconnects and clears the remembered sensor.
  Future<void> forget() async {
    await disconnect();
    await _preferences.clearRememberedDevice();
  }

  /// Attempts to reconnect to the remembered sensor when Bluetooth is ready.
  ///
  /// Returns `true` when a reconnect was attempted. No-ops (returning `false`)
  /// when reconnection is currently suppressed (see [_canAutoReconnect]), an
  /// attempt is already in flight, a sensor is already connected/connecting,
  /// nothing is remembered, or Bluetooth is not ready. Failures are swallowed:
  /// automatic reconnection is best-effort and must not surface errors.
  Future<bool> tryReconnectRemembered() async {
    if (!_canAutoReconnect() ||
        _reconnectInProgress ||
        _status == SensorConnectionStatus.connected ||
        _status == SensorConnectionStatus.connecting) {
      return false;
    }
    final remembered = await _preferences.getRememberedDevice();
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

  /// Whether a heart-rate sensor has been paired and remembered.
  Future<bool> hasRememberedDevice() async =>
      await _preferences.getRememberedDevice() != null;

  /// Best-effort automatic reconnect for app/map open.
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
    if (await _preferences.getRememberedDevice() == null) {
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
    await _sampleSubscription?.cancel();
    await _bluetoothSubscription?.cancel();
    await _statusController.close();
    await _sampleController.close();
    await _bluetoothController.close();
    await _adapter.dispose();
  }

  void _handleStatus(SensorConnectionStatus status) {
    _status = status;
    if (status == SensorConnectionStatus.disconnected ||
        status == SensorConnectionStatus.failed) {
      _latestSample = null;
    }
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }

  void _handleSample(HeartRateSample sample) {
    _latestSample = sample;
    if (!_sampleController.isClosed) {
      _sampleController.add(sample);
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
    // Guarded inside [tryReconnectRemembered] so it never runs during a
    // recording handoff.
    if (state == SensorBluetoothState.ready &&
        previous != SensorBluetoothState.ready) {
      unawaited(tryReconnectRemembered());
    }
  }
}
