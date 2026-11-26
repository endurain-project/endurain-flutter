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
/// It is owned by the composition root so a live connection survives navigation between
/// screens. Route controllers observe it; they must not dispose it.
class SensorService {
  SensorService({
    required SensorConnectionAdapter adapter,
    required SensorPreferencesRepository preferences,
    required String rememberedKey,
    bool Function()? canAutoReconnect,
    int autoReconnectAttempts = 4,
    Duration autoReconnectRetryDelay = const Duration(seconds: 2),
    List<Duration> linkLossRetryDelays = defaultLinkLossRetryDelays,
  }) : assert(linkLossRetryDelays.isNotEmpty),
       _adapter = adapter,
       _preferences = preferences,
       _rememberedKey = rememberedKey,
       _canAutoReconnect = canAutoReconnect ?? _alwaysAllowReconnect,
       _autoReconnectAttempts = autoReconnectAttempts,
       _autoReconnectRetryDelay = autoReconnectRetryDelay,
       _linkLossRetryDelays = linkLossRetryDelays {
    _statusSubscription = _adapter.connectionStatus.listen(_handleStatus);
    _measurementSubscription = _adapter.measurements.listen(_handleMeasurement);
    _bluetoothSubscription = _adapter.bluetoothState.listen(
      _handleBluetoothState,
    );
  }

  static bool _alwaysAllowReconnect() => true;

  /// Waits between reconnect attempts after the link drops unexpectedly. The
  /// last delay repeats until the sensor is back, the user disconnects or
  /// forgets it, or the service is disposed.
  static const List<Duration> defaultLinkLossRetryDelays = [
    Duration(seconds: 2),
    Duration(seconds: 5),
    Duration(seconds: 10),
    Duration(seconds: 30),
  ];

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
  final List<Duration> _linkLossRetryDelays;

  /// The in-flight [autoConnectRemembered] / [tryReconnectRemembered] runs.
  /// Set synchronously, before the first await, so concurrent callers (cold
  /// launch, resume, Bluetooth becoming ready) join one attempt instead of
  /// tearing down each other's connection.
  Future<void>? _autoConnectFuture;
  Future<bool>? _reconnectFuture;

  /// Whether the user wants the sensor linked: set by a successful [connect],
  /// cleared by [disconnect], [forget] and [dispose]. Only then is a dropped
  /// link reconnected automatically.
  bool _keepLinked = false;
  Timer? _linkLossTimer;
  int _linkLossAttempt = 0;
  bool _disposed = false;

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
    _keepLinked = true;
    _cancelLinkLossReconnect();
    await _preferences.saveRemembered(key: _rememberedKey, device: device);
  }

  /// Disconnects the active sensor without forgetting it.
  Future<void> disconnect() async {
    // Before the adapter reports `disconnected`, so this is not mistaken for a
    // dropped link.
    _keepLinked = false;
    _cancelLinkLossReconnect();
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
  /// Returns `true` when a reconnect was attempted. A call made while an
  /// attempt is already in flight joins it and returns its result. No-ops
  /// (returning `false`) when a sensor is already connected/connecting,
  /// nothing is remembered, or Bluetooth is not ready. Failures are swallowed:
  /// automatic reconnection is best-effort.
  Future<bool> tryReconnectRemembered() {
    final inFlight = _reconnectFuture;
    if (inFlight != null) {
      return inFlight;
    }
    if (!_canAutoReconnect() ||
        _status == SensorConnectionStatus.connected ||
        _status == SensorConnectionStatus.connecting) {
      return Future<bool>.value(false);
    }
    final attempt = _reconnectRemembered();
    _reconnectFuture = attempt;
    return attempt.whenComplete(() {
      if (identical(_reconnectFuture, attempt)) {
        _reconnectFuture = null;
      }
    });
  }

  Future<bool> _reconnectRemembered() async {
    final BleSensorDevice? remembered;
    try {
      remembered = await _preferences.getRemembered(key: _rememberedKey);
      if (remembered == null ||
          await _adapter.currentBluetoothState() !=
              SensorBluetoothState.ready) {
        return false;
      }
    } catch (_) {
      // Storage or adapter unavailable: nothing to reconnect right now.
      return false;
    }
    try {
      await connect(remembered);
    } catch (_) {
      // Best-effort reconnect.
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
  ///
  /// A call made while a run is already in flight joins it.
  Future<void> autoConnectRemembered() {
    final inFlight = _autoConnectFuture;
    if (inFlight != null) {
      return inFlight;
    }
    if (!_canAutoReconnect() ||
        _status == SensorConnectionStatus.connected ||
        _status == SensorConnectionStatus.connecting) {
      return Future<void>.value();
    }
    final run = _autoConnectRemembered();
    _autoConnectFuture = run;
    return run.whenComplete(() {
      if (identical(_autoConnectFuture, run)) {
        _autoConnectFuture = null;
      }
    });
  }

  Future<void> _autoConnectRemembered() async {
    if (await _preferences.getRemembered(key: _rememberedKey) == null) {
      return;
    }
    try {
      await _adapter.ensurePermissions();
    } catch (_) {
      // Best-effort activation; the reconnect attempts below still run.
    }
    for (var attempt = 0; attempt < _autoReconnectAttempts; attempt++) {
      if (isConnected || _disposed) {
        return;
      }
      // Joins an attempt already in flight (e.g. one triggered by Bluetooth
      // becoming ready) rather than starting a competing connection.
      await tryReconnectRemembered();
      if (isConnected || attempt == _autoReconnectAttempts - 1) {
        return;
      }
      // Give the platform a moment to expose the peripheral before retrying.
      await Future<void>.delayed(_autoReconnectRetryDelay);
    }
  }

  /// Schedules the next reconnect attempt after an unexpected link loss,
  /// backing off through [_linkLossRetryDelays].
  void _scheduleLinkLossReconnect() {
    _linkLossTimer?.cancel();
    _linkLossTimer = null;
    if (_disposed || !_keepLinked || !_canAutoReconnect()) {
      return;
    }
    final index = _linkLossAttempt < _linkLossRetryDelays.length
        ? _linkLossAttempt
        : _linkLossRetryDelays.length - 1;
    _linkLossAttempt++;
    _linkLossTimer = Timer(
      _linkLossRetryDelays[index],
      () => unawaited(_retryAfterLinkLoss()),
    );
  }

  Future<void> _retryAfterLinkLoss() async {
    _linkLossTimer = null;
    if (_disposed || !_keepLinked || isConnected) {
      return;
    }
    await tryReconnectRemembered();
    if (!isConnected && _linkLossTimer == null) {
      _scheduleLinkLossReconnect();
    }
  }

  void _cancelLinkLossReconnect() {
    _linkLossTimer?.cancel();
    _linkLossTimer = null;
    _linkLossAttempt = 0;
  }

  Future<void> dispose() async {
    _disposed = true;
    _keepLinked = false;
    _cancelLinkLossReconnect();
    await _statusSubscription?.cancel();
    await _measurementSubscription?.cancel();
    await _bluetoothSubscription?.cancel();
    await _statusController.close();
    await _measurementController.close();
    await _bluetoothController.close();
    await _adapter.dispose();
  }

  void _handleStatus(SensorConnectionStatus status) {
    final previous = _status;
    _status = status;
    if (status == SensorConnectionStatus.disconnected ||
        status == SensorConnectionStatus.failed) {
      _latestMeasurement = null;
    }
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
    // A link the user did not end (out of range, sensor slept, radio glitch):
    // the adapter only reports it, so reconnect here with a bounded backoff.
    if (status == SensorConnectionStatus.disconnected &&
        previous == SensorConnectionStatus.connected &&
        _keepLinked) {
      _linkLossAttempt = 0;
      _scheduleLinkLossReconnect();
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
