import 'dart:async';
import 'dart:typed_data';

import 'package:endurain/features/sensors/models/ble_sensor_device.dart';
import 'package:endurain/features/sensors/models/heart_rate_sample.dart';
import 'package:endurain/features/sensors/models/sensor_bluetooth_state.dart';
import 'package:endurain/features/sensors/models/sensor_connection_status.dart';
import 'package:endurain/features/sensors/services/heart_rate_measurement_parser.dart';
import 'package:endurain/features/sensors/services/heart_rate_sensor_adapter.dart';
import 'package:universal_ble/universal_ble.dart';

/// [HeartRateSensorAdapter] backed by `universal_ble` (BSD-3-Clause, no Google
/// Play Services, F-Droid compatible).
///
/// This is the concrete BLE boundary. It keeps all plugin types contained here
/// so nothing else in the app imports the Bluetooth stack, and it requests the
/// runtime BLE permissions itself (universal_ble handles the platform
/// differences), so no separate permission plugin is needed.
class UniversalBleHeartRateSensorAdapter implements HeartRateSensorAdapter {
  UniversalBleHeartRateSensorAdapter();

  /// GATT Heart Rate Service (`0x180D`).
  static const String _heartRateService = '180D';

  /// GATT Heart Rate Measurement characteristic (`0x2A37`).
  static const String _heartRateMeasurement = '2A37';

  static const Duration _connectTimeout = Duration(seconds: 20);

  final StreamController<SensorConnectionStatus> _statusController =
      StreamController<SensorConnectionStatus>.broadcast();
  final StreamController<HeartRateSample> _heartRateController =
      StreamController<HeartRateSample>.broadcast();

  String? _deviceId;
  String? _serviceUuid;
  String? _characteristicUuid;
  StreamSubscription<bool>? _connectionSubscription;
  StreamSubscription<Uint8List>? _valueSubscription;

  @override
  Stream<SensorConnectionStatus> get connectionStatus =>
      _statusController.stream;

  @override
  Stream<HeartRateSample> get heartRate => _heartRateController.stream;

  @override
  Stream<SensorBluetoothState> get bluetoothState =>
      UniversalBle.availabilityStream.map(_mapAvailability);

  @override
  Future<SensorBluetoothState> currentBluetoothState() async {
    return _mapAvailability(await UniversalBle.getBluetoothAvailabilityState());
  }

  @override
  Future<bool> ensurePermissions() async {
    try {
      await UniversalBle.requestPermissions();
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Stream<List<BleSensorDevice>> scanForHeartRateSensors({
    Duration timeout = const Duration(seconds: 15),
  }) {
    late final StreamController<List<BleSensorDevice>> controller;
    StreamSubscription<BleDevice>? scanSubscription;
    Timer? timeoutTimer;
    final discovered = <String, BleSensorDevice>{};

    Future<void> beginScan() async {
      scanSubscription = UniversalBle.scanStream.listen((device) {
        if (controller.isClosed) {
          return;
        }
        discovered[device.deviceId] = BleSensorDevice(
          id: device.deviceId,
          name: device.name ?? '',
          rssi: device.rssi,
        );
        final devices = discovered.values.toList(growable: false)
          ..sort((a, b) => (b.rssi ?? -1000).compareTo(a.rssi ?? -1000));
        controller.add(devices);
      }, onError: controller.addError);
      try {
        await UniversalBle.startScan(
          scanFilter: ScanFilter(withServices: [_heartRateService]),
        );
      } catch (error, stackTrace) {
        if (!controller.isClosed) {
          controller.addError(error, stackTrace);
          await controller.close();
        }
        return;
      }
      // universal_ble scans until stopped, so end the stream after [timeout] so
      // listeners can reset their "scanning" state.
      timeoutTimer = Timer(timeout, () {
        if (!controller.isClosed) {
          controller.close();
        }
      });
    }

    controller = StreamController<List<BleSensorDevice>>(
      onListen: beginScan,
      onCancel: () async {
        timeoutTimer?.cancel();
        await scanSubscription?.cancel();
        await stopScan();
      },
    );
    return controller.stream;
  }

  @override
  Future<void> stopScan() async {
    if (await UniversalBle.isScanning()) {
      await UniversalBle.stopScan();
    }
  }

  @override
  Future<void> connect(BleSensorDevice device) async {
    await _teardownConnection();
    final deviceId = device.id;
    _deviceId = deviceId;
    _emitStatus(SensorConnectionStatus.connecting);

    _connectionSubscription = UniversalBle.connectionStream(deviceId).listen((
      isConnected,
    ) {
      if (!isConnected && _deviceId == deviceId && _valueSubscription != null) {
        // The link dropped after we had subscribed; surface the loss.
        _emitStatus(SensorConnectionStatus.disconnected);
      }
    });

    try {
      await UniversalBle.connect(deviceId, timeout: _connectTimeout);
      await _subscribeToHeartRate(deviceId);
      _emitStatus(SensorConnectionStatus.connected);
    } catch (error) {
      _emitStatus(SensorConnectionStatus.failed);
      await _teardownConnection();
      rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    await _teardownConnection();
    _emitStatus(SensorConnectionStatus.disconnected);
  }

  @override
  Future<void> dispose() async {
    await _teardownConnection();
    await _statusController.close();
    await _heartRateController.close();
  }

  Future<void> _subscribeToHeartRate(String deviceId) async {
    final services = await UniversalBle.discoverServices(deviceId);
    final service = _firstOrNull(
      services,
      (candidate) => _uuidEquals(candidate.uuid, _heartRateService),
    );
    if (service == null) {
      throw StateError('Heart Rate service not found on device');
    }
    final characteristic = _firstOrNull(
      service.characteristics,
      (candidate) => _uuidEquals(candidate.uuid, _heartRateMeasurement),
    );
    if (characteristic == null) {
      throw StateError('Heart Rate Measurement characteristic not found');
    }

    _serviceUuid = service.uuid;
    _characteristicUuid = characteristic.uuid;

    _valueSubscription =
        UniversalBle.characteristicValueStream(
          deviceId,
          characteristic.uuid,
        ).listen((data) {
          final sample = HeartRateMeasurementParser.parse(
            data,
            timestamp: DateTime.now(),
          );
          if (sample != null && !_heartRateController.isClosed) {
            _heartRateController.add(sample);
          }
        });

    await UniversalBle.subscribeNotifications(
      deviceId,
      service.uuid,
      characteristic.uuid,
    );
  }

  Future<void> _teardownConnection() async {
    await _valueSubscription?.cancel();
    _valueSubscription = null;
    await _connectionSubscription?.cancel();
    _connectionSubscription = null;

    final deviceId = _deviceId;
    final serviceUuid = _serviceUuid;
    final characteristicUuid = _characteristicUuid;
    _deviceId = null;
    _serviceUuid = null;
    _characteristicUuid = null;

    if (deviceId != null) {
      if (serviceUuid != null && characteristicUuid != null) {
        try {
          await UniversalBle.unsubscribe(
            deviceId,
            serviceUuid,
            characteristicUuid,
          );
        } catch (_) {
          // Best-effort: a device that is already gone must not throw out of
          // teardown/dispose.
        }
      }
      try {
        await UniversalBle.disconnect(deviceId);
      } catch (_) {
        // Best-effort teardown.
      }
    }
  }

  void _emitStatus(SensorConnectionStatus status) {
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }

  SensorBluetoothState _mapAvailability(AvailabilityState state) {
    switch (state) {
      case AvailabilityState.poweredOn:
        return SensorBluetoothState.ready;
      case AvailabilityState.poweredOff:
      case AvailabilityState.resetting:
        return SensorBluetoothState.off;
      case AvailabilityState.unauthorized:
        return SensorBluetoothState.unauthorized;
      case AvailabilityState.unsupported:
        return SensorBluetoothState.unsupported;
      case AvailabilityState.unknown:
        return SensorBluetoothState.unknown;
    }
  }

  /// Compares two BLE UUIDs regardless of short (16-bit) vs long (128-bit) form.
  static bool _uuidEquals(String a, String b) =>
      BleUuidParser.string(a) == BleUuidParser.string(b);

  static T? _firstOrNull<T>(Iterable<T> items, bool Function(T) test) {
    for (final item in items) {
      if (test(item)) {
        return item;
      }
    }
    return null;
  }
}
