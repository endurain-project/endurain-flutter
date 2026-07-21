import 'package:endurain/features/map/controllers/map_sensor_controller.dart';
import 'package:endurain/features/sensors/models/ble_sensor_device.dart';
import 'package:endurain/features/sensors/models/sensor_connection_status.dart';
import 'package:endurain/features/sensors/models/sensor_measurement.dart';
import 'package:endurain/features/sensors/repositories/sensor_preferences_repository.dart';
import 'package:endurain/features/sensors/services/sensor_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_preferences_store.dart';
import '../../sensors/fakes/fake_sensor_connection_adapter.dart';

void main() {
  group('MapSensorController', () {
    late FakeSensorConnectionAdapter adapter;
    late SensorPreferencesRepository preferences;
    late SensorService service;
    late MapSensorController controller;

    const rememberedKey =
        SensorPreferencesRepository.rememberedHeartRateSensorKey;
    const rememberedDevice = BleSensorDevice(id: 'AA:BB', name: 'Strap');

    setUp(() {
      adapter = FakeSensorConnectionAdapter();
      preferences = SensorPreferencesRepository(
        preferences: FakePreferencesStore(),
      );
      service = SensorService(
        adapter: adapter,
        preferences: preferences,
        rememberedKey: rememberedKey,
      );
      controller = MapSensorController(
        service: service,
        kind: SensorMeasurementKind.heartRate,
      );
    });

    tearDown(() async {
      controller.dispose();
      await service.dispose();
    });

    SensorMeasurement sample(int bpm) => SensorMeasurement(
      kind: SensorMeasurementKind.heartRate,
      value: bpm,
      timestamp: DateTime(2026, 1, 1, 12),
    );

    test('exposes its sensor kind', () {
      expect(controller.kind, SensorMeasurementKind.heartRate);
    });

    test('starts without a reading', () {
      expect(controller.currentValue, isNull);
    });

    test('surfaces the latest sample and notifies', () async {
      var notifications = 0;
      controller.addListener(() => notifications++);

      adapter.emitStatus(SensorConnectionStatus.connected);
      adapter.emitMeasurement(sample(72));
      await Future<void>.delayed(Duration.zero);

      expect(controller.currentValue, 72);
      expect(notifications, greaterThanOrEqualTo(1));

      adapter.emitMeasurement(sample(81));
      await Future<void>.delayed(Duration.zero);
      expect(controller.currentValue, 81);
    });

    test('clears the reading when the sensor disconnects', () async {
      adapter.emitStatus(SensorConnectionStatus.connected);
      adapter.emitMeasurement(sample(72));
      await Future<void>.delayed(Duration.zero);
      expect(controller.currentValue, 72);

      adapter.emitStatus(SensorConnectionStatus.disconnected);
      await Future<void>.delayed(Duration.zero);

      expect(controller.currentValue, isNull);
    });

    test('keeps the last reading during a transient reconnect', () async {
      adapter.emitStatus(SensorConnectionStatus.connected);
      adapter.emitMeasurement(sample(72));
      await Future<void>.delayed(Duration.zero);

      adapter.emitStatus(SensorConnectionStatus.reconnecting);
      await Future<void>.delayed(Duration.zero);

      // Reconnecting is not a terminal loss; keep showing the last value.
      expect(controller.currentValue, 72);
    });

    test('status is idle without a remembered sensor', () async {
      await controller.initialize();

      expect(controller.status, MapSensorStatus.idle);
      expect(adapter.connectCalls, isEmpty);
    });

    test('auto-connects a remembered sensor and shows searching', () async {
      await preferences.saveRemembered(
        key: rememberedKey,
        device: rememberedDevice,
      );

      await controller.initialize();

      // The remembered sensor triggers Bluetooth activation + reconnect so the
      // user does not have to open the Sensors screen first.
      expect(adapter.ensurePermissionsCalls, greaterThanOrEqualTo(1));
      expect(adapter.connectCalls, isNotEmpty);
      // Connected but no reading yet -> still searching until the first value.
      expect(controller.status, MapSensorStatus.searching);
    });

    test('becomes connected once the remembered sensor reports', () async {
      await preferences.saveRemembered(
        key: rememberedKey,
        device: rememberedDevice,
      );
      await controller.initialize();

      adapter.emitMeasurement(sample(72));
      await Future<void>.delayed(Duration.zero);

      expect(controller.status, MapSensorStatus.connected);
      expect(controller.currentValue, 72);
    });

    test('drives a power indicator from the same generic wiring', () async {
      final powerController = MapSensorController(
        service: service,
        kind: SensorMeasurementKind.power,
      );
      addTearDown(powerController.dispose);

      expect(powerController.kind, SensorMeasurementKind.power);

      adapter.emitStatus(SensorConnectionStatus.connected);
      adapter.emitMeasurement(
        SensorMeasurement(
          kind: SensorMeasurementKind.power,
          value: 240,
          timestamp: DateTime(2026, 1, 1, 12),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(powerController.status, MapSensorStatus.connected);
      expect(powerController.currentValue, 240);
    });
  });
}
