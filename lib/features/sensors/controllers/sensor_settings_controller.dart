import 'dart:async';

import 'package:endurain/features/sensors/models/ble_sensor_device.dart';
import 'package:endurain/features/sensors/models/heart_rate_sample.dart';
import 'package:endurain/features/sensors/models/sensor_bluetooth_state.dart';
import 'package:endurain/features/sensors/models/sensor_connection_status.dart';
import 'package:endurain/features/sensors/services/heart_rate_sensor_service.dart';
import 'package:flutter/foundation.dart';

/// Route-scoped controller for the Sensors settings screen.
///
/// Observes the app-lifetime [HeartRateSensorService] and exposes the state the
/// screen renders: Bluetooth availability, discovered devices, connection
/// status, and the live heart rate. It owns only its stream subscriptions and
/// must be disposed with the route; the underlying service is not disposed
/// here.
class SensorSettingsController extends ChangeNotifier {
  SensorSettingsController({required HeartRateSensorService service})
    : _service = service;

  final HeartRateSensorService _service;

  /// How long a manual scan runs before it stops on its own. Kept generous so
  /// slower-advertising heart-rate straps have time to be discovered.
  static const Duration _scanTimeout = Duration(seconds: 30);

  StreamSubscription<SensorBluetoothState>? _bluetoothSubscription;
  StreamSubscription<SensorConnectionStatus>? _statusSubscription;
  StreamSubscription<HeartRateSample>? _sampleSubscription;
  StreamSubscription<List<BleSensorDevice>>? _scanSubscription;

  SensorBluetoothState _bluetoothState = SensorBluetoothState.unknown;
  SensorConnectionStatus _connectionStatus =
      SensorConnectionStatus.disconnected;
  HeartRateSample? _latestSample;
  List<BleSensorDevice> _scanResults = const <BleSensorDevice>[];
  bool _isScanning = false;
  bool _permissionDenied = false;
  bool _isCheckingBluetooth = true;
  BleSensorDevice? _rememberedDevice;
  bool _isDisposed = false;

  SensorBluetoothState get bluetoothState => _bluetoothState;
  SensorConnectionStatus get connectionStatus => _connectionStatus;
  List<BleSensorDevice> get scanResults => _scanResults;
  bool get isScanning => _isScanning;
  bool get permissionDenied => _permissionDenied;

  /// Whether the initial Bluetooth availability check (including the up-front
  /// permission request) is still in progress. While true the screen shows a
  /// spinner instead of a possibly-wrong "Bluetooth is off" message.
  bool get isCheckingBluetooth => _isCheckingBluetooth;

  BleSensorDevice? get rememberedDevice => _rememberedDevice;
  BleSensorDevice? get connectedDevice => _service.connectedDevice;

  /// The latest heart rate in beats per minute, or `null` when not connected or
  /// before the first reading.
  int? get currentBpm => _latestSample?.bpm;

  /// Loads the initial state and begins observing the sensor service.
  ///
  /// Requests the Bluetooth runtime permissions up front so the system prompt
  /// appears when the user opens the Sensors screen, then reads the adapter
  /// state. Ordering matters: on iOS the adapter state is `unknown` until the
  /// central manager finishes initializing, and some Android devices only
  /// report an accurate state once the Bluetooth permission is granted — so
  /// reading before requesting would surface an available adapter as "off".
  Future<void> initialize() async {
    _connectionStatus = _service.status;
    _latestSample = _service.latestSample;
    _rememberedDevice = await _service.rememberedDevice();

    // Subscribe before the permission round-trip so any state change that
    // arrives while the prompt is up is still captured.
    _bluetoothSubscription = _service.bluetoothState.listen((state) {
      _bluetoothState = state;
      _notify();
    });
    _statusSubscription = _service.connectionStatus.listen((status) {
      _connectionStatus = status;
      _notify();
    });
    _sampleSubscription = _service.heartRate.listen((sample) {
      _latestSample = sample;
      _notify();
    });
    _notify();

    await _service.ensurePermissions();
    _bluetoothState = await _service.currentBluetoothState();
    _isCheckingBluetooth = false;
    _notify();
  }

  /// Requests permission if needed, then scans for nearby heart-rate sensors.
  Future<void> startScan() async {
    if (_isScanning) {
      return;
    }
    _permissionDenied = false;
    final granted = await _service.ensurePermissions();
    if (!granted) {
      _permissionDenied = true;
      _notify();
      return;
    }
    _scanResults = const <BleSensorDevice>[];
    _isScanning = true;
    _notify();
    _scanSubscription = _service
        .scan(timeout: _scanTimeout)
        .listen(
          (devices) {
            _scanResults = devices;
            _notify();
          },
          onError: (_) {
            _isScanning = false;
            _notify();
          },
          onDone: () {
            _isScanning = false;
            _notify();
          },
        );
  }

  /// Stops an in-progress scan.
  Future<void> stopScan() async {
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    await _service.stopScan();
    if (_isScanning) {
      _isScanning = false;
      _notify();
    }
  }

  /// Connects to [device] and remembers it. Connection failures surface through
  /// [connectionStatus]; this method does not throw.
  Future<void> connect(BleSensorDevice device) async {
    await stopScan();
    try {
      await _service.connect(device);
      _rememberedDevice = device;
    } catch (_) {
      // The failed status is delivered via the connection-status stream.
    }
    _notify();
  }

  /// Disconnects the active sensor without forgetting it.
  Future<void> disconnect() async {
    await _service.disconnect();
    _notify();
  }

  /// Disconnects and forgets the remembered sensor.
  Future<void> forget() async {
    await _service.forget();
    _rememberedDevice = null;
    _notify();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _bluetoothSubscription?.cancel();
    _statusSubscription?.cancel();
    _sampleSubscription?.cancel();
    _scanSubscription?.cancel();
    unawaited(_service.stopScan());
    super.dispose();
  }

  void _notify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }
}
