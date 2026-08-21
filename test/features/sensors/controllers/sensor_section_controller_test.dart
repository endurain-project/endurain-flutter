import 'package:endurain/features/sensors/controllers/sensor_section_controller.dart';
import 'package:endurain/features/sensors/models/ble_sensor_device.dart';
import 'package:endurain/features/sensors/models/sensor_bluetooth_state.dart';
import 'package:endurain/features/sensors/models/sensor_connection_status.dart';
import 'package:endurain/features/sensors/models/sensor_measurement.dart';
import 'package:endurain/features/sensors/repositories/sensor_preferences_repository.dart';
import 'package:endurain/features/sensors/services/sensor_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_preferences_store.dart';
import '../fakes/fake_sensor_connection_adapter.dart';

void main() {
  group('SensorSectionController', () {
    late FakeSensorConnectionAdapter adapter;
    late SensorService service;
    late SensorSectionController controller;

    const device = BleSensorDevice(id: 'C1', name: 'Cadence');

    setUp(() {
      adapter = FakeSensorConnectionAdapter();
      service = SensorService(
        adapter: adapter,
        preferences: SensorPreferencesRepository(
          preferences: FakePreferencesStore(),
        ),
        rememberedKey: SensorPreferencesRepository.rememberedCadenceSensorKey,
      );
      controller = SensorSectionController(service: service);
    });

    tearDown(() async {
      controller.dispose();
      await service.dispose();
    });

    test('initialize loads the current Bluetooth state', () async {
      adapter.bluetoothStateValue = SensorBluetoothState.ready;

      await controller.initialize();

      expect(controller.bluetoothState, SensorBluetoothState.ready);
      expect(controller.isCheckingBluetooth, isFalse);
    });

    test('initialize requests permission before reading Bluetooth state', () async {
      // Mirror a device that only reports an accurate adapter state once the
      // Bluetooth permission has been granted. Reading before requesting would
      // surface the ready adapter as `unknown` (which the UI renders as off).
      adapter.stateHiddenUntilPermission = true;
      adapter.bluetoothStateValue = SensorBluetoothState.ready;

      await controller.initialize();

      expect(adapter.ensurePermissionsCalls, 1);
      expect(controller.bluetoothState, SensorBluetoothState.ready);
    });

    test('startScan flags permission denial without scanning', () async {
      adapter.permissionGranted = false;
      await controller.initialize();

      await controller.startScan();

      expect(controller.permissionDenied, isTrue);
      expect(controller.isScanning, isFalse);
    });

    test('startScan collects discovered devices then stops', () async {
      adapter.scanDevices = const [
        BleSensorDevice(id: '1', name: 'A'),
        BleSensorDevice(id: '2', name: 'B'),
      ];
      await controller.initialize();

      await controller.startScan();
      await Future<void>.delayed(Duration.zero);

      expect(controller.scanResults, hasLength(2));
      expect(controller.isScanning, isFalse);
    });

    test('startScan uses a longer scan window', () async {
      await controller.initialize();

      await controller.startScan();
      await Future<void>.delayed(Duration.zero);

      expect(adapter.lastScanTimeout, const Duration(seconds: 30));
    });

    test('connect updates status and remembers the device', () async {
      await controller.initialize();

      await controller.connect(device);
      await Future<void>.delayed(Duration.zero);

      expect(controller.connectionStatus, SensorConnectionStatus.connected);
      expect(controller.rememberedDevice, device);
    });

    test('currentValue reflects the latest measurement', () async {
      await controller.initialize();
      await controller.connect(device);

      adapter.emitMeasurement(
        SensorMeasurement(
          kind: SensorMeasurementKind.cadence,
          value: 88,
          timestamp: DateTime.utc(2026),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(controller.currentValue, 88);
    });

    test('disconnect resets the connection status', () async {
      await controller.initialize();
      await controller.connect(device);
      await Future<void>.delayed(Duration.zero);

      await controller.disconnect();
      await Future<void>.delayed(Duration.zero);

      expect(controller.connectionStatus, SensorConnectionStatus.disconnected);
    });

    test('forget clears the remembered device', () async {
      await controller.initialize();
      await controller.connect(device);
      await Future<void>.delayed(Duration.zero);

      await controller.forget();

      expect(controller.rememberedDevice, isNull);
    });
  });
}
