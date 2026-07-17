import 'package:endurain/features/sensors/models/ble_sensor_device.dart';
import 'package:endurain/features/sensors/models/heart_rate_sample.dart';
import 'package:endurain/features/sensors/models/sensor_bluetooth_state.dart';
import 'package:endurain/features/sensors/models/sensor_connection_status.dart';
import 'package:endurain/features/sensors/repositories/sensor_preferences_repository.dart';
import 'package:endurain/features/sensors/services/heart_rate_sensor_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_preferences_store.dart';
import '../fakes/fake_heart_rate_sensor_adapter.dart';

void main() {
  group('HeartRateSensorService', () {
    late FakeHeartRateSensorAdapter adapter;
    late SensorPreferencesRepository preferences;
    late HeartRateSensorService service;

    const device = BleSensorDevice(id: 'AA:BB:CC', name: 'Wahoo TICKR');

    setUp(() {
      adapter = FakeHeartRateSensorAdapter();
      preferences = SensorPreferencesRepository(
        preferences: FakePreferencesStore(),
      );
      service = HeartRateSensorService(
        adapter: adapter,
        preferences: preferences,
      );
    });

    tearDown(() => service.dispose());

    test('connect remembers the device and updates status', () async {
      await service.connect(device);
      await Future<void>.delayed(Duration.zero);

      expect(service.status, SensorConnectionStatus.connected);
      expect(service.isConnected, isTrue);
      expect(service.connectedDevice, device);
      expect(adapter.connectCalls, [device]);
      final remembered = await service.rememberedDevice();
      expect(remembered?.id, device.id);
    });

    test('a failed connect does not remember the device', () async {
      adapter.connectShouldFail = true;

      await expectLater(service.connect(device), throwsA(isA<StateError>()));

      expect(service.connectedDevice, isNull);
      expect(await service.rememberedDevice(), isNull);
    });

    test('re-broadcasts and caches heart-rate samples', () async {
      final sample = HeartRateSample(bpm: 88, timestamp: DateTime.utc(2026));
      final received = service.heartRate.first;

      adapter.emitHeartRate(sample);

      expect((await received).bpm, 88);
      expect(service.latestSample?.bpm, 88);
    });

    test('clears the cached sample when the sensor disconnects', () async {
      adapter.emitHeartRate(
        HeartRateSample(bpm: 90, timestamp: DateTime.utc(2026)),
      );
      await Future<void>.delayed(Duration.zero);
      expect(service.latestSample, isNotNull);

      adapter.emitStatus(SensorConnectionStatus.disconnected);
      await Future<void>.delayed(Duration.zero);

      expect(service.latestSample, isNull);
    });

    test('forget disconnects and clears the remembered device', () async {
      await service.connect(device);
      await Future<void>.delayed(Duration.zero);

      await service.forget();

      expect(adapter.disconnectCalls, greaterThan(0));
      expect(service.connectedDevice, isNull);
      expect(await service.rememberedDevice(), isNull);
    });

    test('tryReconnectRemembered connects when ready and remembered', () async {
      await preferences.saveRememberedDevice(device);
      adapter.bluetoothStateValue = SensorBluetoothState.ready;

      final attempted = await service.tryReconnectRemembered();

      expect(attempted, isTrue);
      expect(adapter.connectCalls, [device]);
    });

    test('tryReconnectRemembered no-ops without a remembered device', () async {
      final attempted = await service.tryReconnectRemembered();

      expect(attempted, isFalse);
      expect(adapter.connectCalls, isEmpty);
    });

    test('tryReconnectRemembered no-ops when Bluetooth is not ready', () async {
      await preferences.saveRememberedDevice(device);
      adapter.bluetoothStateValue = SensorBluetoothState.off;

      final attempted = await service.tryReconnectRemembered();

      expect(attempted, isFalse);
      expect(adapter.connectCalls, isEmpty);
    });

    test('hasRememberedDevice reflects stored state', () async {
      expect(await service.hasRememberedDevice(), isFalse);

      await preferences.saveRememberedDevice(device);

      expect(await service.hasRememberedDevice(), isTrue);
    });

    test(
      'autoConnectRemembered activates permissions then reconnects',
      () async {
        await preferences.saveRememberedDevice(device);
        adapter.bluetoothStateValue = SensorBluetoothState.ready;

        await service.autoConnectRemembered();

        // Activates the Bluetooth stack (what iOS needs to reach ready) and then
        // reconnects the remembered sensor without visiting the Sensors screen.
        expect(adapter.ensurePermissionsCalls, greaterThanOrEqualTo(1));
        expect(adapter.connectCalls, [device]);
      },
    );

    test('autoConnectRemembered no-ops without a remembered device', () async {
      await service.autoConnectRemembered();

      expect(adapter.ensurePermissionsCalls, 0);
      expect(adapter.connectCalls, isEmpty);
    });

    test('autoConnectRemembered retries until the sensor connects', () async {
      final retryAdapter = FakeHeartRateSensorAdapter()
        ..bluetoothStateValue = SensorBluetoothState.ready
        ..connectFailuresBeforeSuccess = 2;
      final retryPreferences = SensorPreferencesRepository(
        preferences: FakePreferencesStore(),
      );
      await retryPreferences.saveRememberedDevice(device);
      final retryService = HeartRateSensorService(
        adapter: retryAdapter,
        preferences: retryPreferences,
        autoReconnectRetryDelay: Duration.zero,
      );
      addTearDown(retryService.dispose);

      await retryService.autoConnectRemembered();

      // The first two attempts fail; a later one connects, no user interaction.
      expect(retryAdapter.connectCalls.length, greaterThanOrEqualTo(3));
      expect(retryService.isConnected, isTrue);
    });

    test('auto-reconnects when Bluetooth transitions to ready', () async {
      await preferences.saveRememberedDevice(device);
      adapter.bluetoothStateValue = SensorBluetoothState.ready;
      final connected = service.connectionStatus.firstWhere(
        (status) => status == SensorConnectionStatus.connected,
      );

      adapter.emitBluetoothState(SensorBluetoothState.ready);
      await connected;

      expect(adapter.connectCalls, [device]);
    });

    test(
      'does not auto-reconnect on a non-ready Bluetooth transition',
      () async {
        await preferences.saveRememberedDevice(device);
        adapter.bluetoothStateValue = SensorBluetoothState.off;

        adapter.emitBluetoothState(SensorBluetoothState.off);
        await Future<void>.delayed(Duration.zero);

        expect(adapter.connectCalls, isEmpty);
      },
    );

    test('re-broadcasts Bluetooth adapter state changes', () async {
      final received = service.bluetoothState.first;

      adapter.emitBluetoothState(SensorBluetoothState.off);

      expect(await received, SensorBluetoothState.off);
    });

    test(
      'does not auto-reconnect while suppressed by canAutoReconnect',
      () async {
        final suppressed = HeartRateSensorService(
          adapter: adapter,
          preferences: preferences,
          canAutoReconnect: () => false,
        );
        addTearDown(suppressed.dispose);
        await preferences.saveRememberedDevice(device);
        adapter.bluetoothStateValue = SensorBluetoothState.ready;

        final attempted = await suppressed.tryReconnectRemembered();

        expect(attempted, isFalse);
        expect(adapter.connectCalls, isEmpty);
      },
    );
  });
}
