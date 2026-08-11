import 'dart:async';

import 'package:endurain/features/sensors/controllers/sensor_section_view.dart';
import 'package:endurain/features/sensors/models/ble_sensor_device.dart';
import 'package:endurain/features/sensors/models/sensor_bluetooth_state.dart';
import 'package:endurain/features/sensors/models/sensor_connection_status.dart';
import 'package:endurain/features/sensors/models/sensor_measurement.dart';
import 'package:endurain/features/sensors/services/sensor_service.dart';
import 'package:endurain/shared/state/safe_notifier.dart';

/// Route-scoped controller for one measurement section (heart rate, power, or
/// cadence) of the Sensors settings screen.
///
/// Observes an app-lifetime [SensorService] and exposes the state the section
/// renders: Bluetooth availability, discovered devices, connection status, and
/// the live value. One instance drives each section, differing only in the
/// [SensorService] it wraps. It owns only its stream subscriptions and must be
/// disposed with the route; the underlying service is not disposed here.
class SensorSectionController extends SafeNotifier
    implements SensorSectionView {
  SensorSectionController({required SensorService service})
    : _service = service;

  final SensorService _service;

  /// How long a manual scan runs before it stops on its own. Kept generous so
  /// slower-advertising sensors have time to be discovered.
  static const Duration _scanTimeout = Duration(seconds: 30);

  StreamSubscription<SensorBluetoothState>? _bluetoothSubscription;
  StreamSubscription<SensorConnectionStatus>? _statusSubscription;
  StreamSubscription<SensorMeasurement>? _measurementSubscription;
  StreamSubscription<List<BleSensorDevice>>? _scanSubscription;

  SensorBluetoothState _bluetoothState = SensorBluetoothState.unknown;
  SensorConnectionStatus _connectionStatus =
      SensorConnectionStatus.disconnected;
  SensorMeasurement? _latestMeasurement;
  List<BleSensorDevice> _scanResults = const <BleSensorDevice>[];
  bool _isScanning = false;
  bool _permissionDenied = false;
  bool _isCheckingBluetooth = true;
  BleSensorDevice? _rememberedDevice;

  @override
  SensorBluetoothState get bluetoothState => _bluetoothState;
  @override
  SensorConnectionStatus get connectionStatus => _connectionStatus;
  @override
  List<BleSensorDevice> get scanResults => _scanResults;
  @override
  bool get isScanning => _isScanning;
  @override
  bool get permissionDenied => _permissionDenied;
  @override
  bool get isCheckingBluetooth => _isCheckingBluetooth;
  @override
  BleSensorDevice? get rememberedDevice => _rememberedDevice;
  @override
  BleSensorDevice? get connectedDevice => _service.connectedDevice;

  /// The latest measurement value (watts or rpm), or `null` when not connected
  /// or before the first reading.
  @override
  int? get currentValue => _latestMeasurement?.value;

  /// Loads the initial state and begins observing the sensor service.
  ///
  /// Requests the Bluetooth runtime permissions up front so the system prompt
  /// appears when the user opens the Sensors screen, then reads the adapter
  /// state. Ordering mirrors the heart-rate section: some platforms only report
  /// an accurate adapter state once the Bluetooth permission is granted.
  Future<void> initialize() async {
    _connectionStatus = _service.status;
    _latestMeasurement = _service.latestMeasurement;
    _rememberedDevice = await _service.rememberedDevice();

    _bluetoothSubscription = _service.bluetoothState.listen((state) {
      _bluetoothState = state;
      notify();
    });
    _statusSubscription = _service.connectionStatus.listen((status) {
      _connectionStatus = status;
      notify();
    });
    _measurementSubscription = _service.measurements.listen((measurement) {
      _latestMeasurement = measurement;
      notify();
    });
    notify();

    await _service.ensurePermissions();
    _bluetoothState = await _service.currentBluetoothState();
    _isCheckingBluetooth = false;
    notify();
  }

  /// Requests permission if needed, then scans for nearby sensors.
  @override
  Future<void> startScan() async {
    if (_isScanning) {
      return;
    }
    _permissionDenied = false;
    final granted = await _service.ensurePermissions();
    if (!granted) {
      _permissionDenied = true;
      notify();
      return;
    }
    _scanResults = const <BleSensorDevice>[];
    _isScanning = true;
    notify();
    _scanSubscription = _service
        .scan(timeout: _scanTimeout)
        .listen(
          (devices) {
            _scanResults = devices;
            notify();
          },
          onError: (_) {
            _isScanning = false;
            notify();
          },
          onDone: () {
            _isScanning = false;
            notify();
          },
        );
  }

  /// Stops an in-progress scan.
  @override
  Future<void> stopScan() async {
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    await _service.stopScan();
    if (_isScanning) {
      _isScanning = false;
      notify();
    }
  }

  /// Connects to [device] and remembers it. Connection failures surface through
  /// [connectionStatus]; this method does not throw.
  @override
  Future<void> connect(BleSensorDevice device) async {
    await stopScan();
    try {
      await _service.connect(device);
      _rememberedDevice = device;
    } catch (_) {
      // The failed status is delivered via the connection-status stream.
    }
    notify();
  }

  /// Disconnects the active sensor without forgetting it.
  @override
  Future<void> disconnect() async {
    await _service.disconnect();
    notify();
  }

  /// Disconnects and forgets the remembered sensor.
  @override
  Future<void> forget() async {
    await _service.forget();
    _rememberedDevice = null;
    notify();
  }

  @override
  void dispose() {
    _bluetoothSubscription?.cancel();
    _statusSubscription?.cancel();
    _measurementSubscription?.cancel();
    _scanSubscription?.cancel();
    unawaited(_service.stopScan());
    super.dispose();
  }
}
