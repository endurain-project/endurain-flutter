import 'package:endurain/features/map/controllers/map_heart_rate_controller.dart';
import 'package:endurain/features/sensors/models/ble_sensor_device.dart';
import 'package:endurain/features/sensors/models/heart_rate_sample.dart';
import 'package:endurain/features/sensors/models/sensor_connection_status.dart';
import 'package:endurain/features/sensors/repositories/sensor_preferences_repository.dart';
import 'package:endurain/features/sensors/services/heart_rate_sensor_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_preferences_store.dart';
import '../../sensors/fakes/fake_heart_rate_sensor_adapter.dart';

void main() {
  group('MapHeartRateController', () {
    late FakeHeartRateSensorAdapter adapter;
    late SensorPreferencesRepository preferences;
    late HeartRateSensorService service;
    late MapHeartRateController controller;

    const rememberedDevice = BleSensorDevice(id: 'AA:BB', name: 'Strap');

    setUp(() {
      adapter = FakeHeartRateSensorAdapter();
      preferences = SensorPreferencesRepository(
        preferences: FakePreferencesStore(),
      );
      service = HeartRateSensorService(
        adapter: adapter,
        preferences: preferences,
      );
      controller = MapHeartRateController(service: service);
    });

    tearDown(() async {
      controller.dispose();
      await service.dispose();
    });

    HeartRateSample sample(int bpm) =>
        HeartRateSample(bpm: bpm, timestamp: DateTime(2026, 1, 1, 12));

    test('starts without a reading', () {
      expect(controller.currentBpm, isNull);
    });

    test('surfaces the latest heart-rate sample and notifies', () async {
      var notifications = 0;
      controller.addListener(() => notifications++);

      adapter.emitStatus(SensorConnectionStatus.connected);
      adapter.emitHeartRate(sample(72));
      await Future<void>.delayed(Duration.zero);

      expect(controller.currentBpm, 72);
      expect(notifications, greaterThanOrEqualTo(1));

      adapter.emitHeartRate(sample(81));
      await Future<void>.delayed(Duration.zero);
      expect(controller.currentBpm, 81);
    });

    test('clears the reading when the sensor disconnects', () async {
      adapter.emitStatus(SensorConnectionStatus.connected);
      adapter.emitHeartRate(sample(72));
      await Future<void>.delayed(Duration.zero);
      expect(controller.currentBpm, 72);

      adapter.emitStatus(SensorConnectionStatus.disconnected);
      await Future<void>.delayed(Duration.zero);

      expect(controller.currentBpm, isNull);
    });

    test('keeps the last reading during a transient reconnect', () async {
      adapter.emitStatus(SensorConnectionStatus.connected);
      adapter.emitHeartRate(sample(72));
      await Future<void>.delayed(Duration.zero);

      adapter.emitStatus(SensorConnectionStatus.reconnecting);
      await Future<void>.delayed(Duration.zero);

      // Reconnecting is not a terminal loss; keep showing the last value.
      expect(controller.currentBpm, 72);
    });

    test('status is idle without a remembered sensor', () async {
      await controller.initialize();

      expect(controller.status, MapHeartRateStatus.idle);
      expect(adapter.connectCalls, isEmpty);
    });

    test('auto-connects a remembered sensor and shows searching', () async {
      await preferences.saveRememberedDevice(rememberedDevice);

      await controller.initialize();

      // The remembered sensor triggers Bluetooth activation + reconnect so the
      // user does not have to open the Sensors screen first.
      expect(adapter.ensurePermissionsCalls, greaterThanOrEqualTo(1));
      expect(adapter.connectCalls, isNotEmpty);
      // Connected but no reading yet -> still searching until the first bpm.
      expect(controller.status, MapHeartRateStatus.searching);
    });

    test('becomes connected once the remembered sensor reports', () async {
      await preferences.saveRememberedDevice(rememberedDevice);
      await controller.initialize();

      adapter.emitHeartRate(sample(72));
      await Future<void>.delayed(Duration.zero);

      expect(controller.status, MapHeartRateStatus.connected);
      expect(controller.currentBpm, 72);
    });
  });
}
