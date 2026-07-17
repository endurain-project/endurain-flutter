import 'package:endurain/features/sensors/models/ble_sensor_device.dart';
import 'package:endurain/features/sensors/repositories/sensor_preferences_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_preferences_store.dart';

void main() {
  group('SensorPreferencesRepository', () {
    late FakePreferencesStore store;
    late SensorPreferencesRepository repository;

    setUp(() {
      store = FakePreferencesStore();
      repository = SensorPreferencesRepository(preferences: store);
    });

    test('returns null when no device is stored', () async {
      expect(await repository.getRememberedDevice(), isNull);
    });

    test('saves and reads a remembered device', () async {
      await repository.saveRememberedDevice(
        const BleSensorDevice(id: 'AA:BB:CC', name: 'Polar H10'),
      );

      final device = await repository.getRememberedDevice();

      expect(device, isNotNull);
      expect(device!.id, 'AA:BB:CC');
      expect(device.name, 'Polar H10');
    });

    test('clears the remembered device', () async {
      await repository.saveRememberedDevice(
        const BleSensorDevice(id: 'AA:BB:CC', name: 'Polar H10'),
      );

      await repository.clearRememberedDevice();

      expect(await repository.getRememberedDevice(), isNull);
    });

    test('returns null when the stored value is malformed', () async {
      await store.write(key: 'remembered_heart_rate_sensor', value: 'not-json');

      expect(await repository.getRememberedDevice(), isNull);
    });

    test('returns null when the stored id is missing', () async {
      await store.write(
        key: 'remembered_heart_rate_sensor',
        value: '{"name":"No id"}',
      );

      expect(await repository.getRememberedDevice(), isNull);
    });
  });
}
