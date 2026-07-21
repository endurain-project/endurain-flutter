import 'package:endurain/features/sensors/models/ble_sensor_device.dart';
import 'package:endurain/features/sensors/repositories/sensor_preferences_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_preferences_store.dart';

void main() {
  group('SensorPreferencesRepository', () {
    late FakePreferencesStore store;
    late SensorPreferencesRepository repository;

    const hrKey = SensorPreferencesRepository.rememberedHeartRateSensorKey;

    setUp(() {
      store = FakePreferencesStore();
      repository = SensorPreferencesRepository(preferences: store);
    });

    test('returns null when no device is stored', () async {
      expect(await repository.getRemembered(key: hrKey), isNull);
    });

    test('saves and reads a remembered device', () async {
      await repository.saveRemembered(
        key: hrKey,
        device: const BleSensorDevice(id: 'AA:BB:CC', name: 'Polar H10'),
      );

      final device = await repository.getRemembered(key: hrKey);

      expect(device, isNotNull);
      expect(device!.id, 'AA:BB:CC');
      expect(device.name, 'Polar H10');
    });

    test('clears the remembered device', () async {
      await repository.saveRemembered(
        key: hrKey,
        device: const BleSensorDevice(id: 'AA:BB:CC', name: 'Polar H10'),
      );

      await repository.clearRemembered(key: hrKey);

      expect(await repository.getRemembered(key: hrKey), isNull);
    });

    test('returns null when the stored value is malformed', () async {
      await store.write(key: 'remembered_heart_rate_sensor', value: 'not-json');

      expect(await repository.getRemembered(key: hrKey), isNull);
    });

    test('returns null when the stored id is missing', () async {
      await store.write(
        key: 'remembered_heart_rate_sensor',
        value: '{"name":"No id"}',
      );

      expect(await repository.getRemembered(key: hrKey), isNull);
    });

    test('remembers power and cadence sensors under distinct keys', () async {
      const power = BleSensorDevice(id: 'PWR-1', name: 'Power Meter');
      const cadence = BleSensorDevice(id: 'CAD-1', name: 'Cadence');

      await repository.saveRemembered(
        key: SensorPreferencesRepository.rememberedPowerSensorKey,
        device: power,
      );
      await repository.saveRemembered(
        key: SensorPreferencesRepository.rememberedCadenceSensorKey,
        device: cadence,
      );

      final storedPower = await repository.getRemembered(
        key: SensorPreferencesRepository.rememberedPowerSensorKey,
      );
      final storedCadence = await repository.getRemembered(
        key: SensorPreferencesRepository.rememberedCadenceSensorKey,
      );

      expect(storedPower?.id, 'PWR-1');
      expect(storedCadence?.id, 'CAD-1');
      // Neither overwrote the heart-rate sensor slot.
      expect(await repository.getRemembered(key: hrKey), isNull);

      await repository.clearRemembered(
        key: SensorPreferencesRepository.rememberedPowerSensorKey,
      );

      expect(
        await repository.getRemembered(
          key: SensorPreferencesRepository.rememberedPowerSensorKey,
        ),
        isNull,
      );
      expect(
        await repository.getRemembered(
          key: SensorPreferencesRepository.rememberedCadenceSensorKey,
        ),
        isNotNull,
      );
    });
  });
}
