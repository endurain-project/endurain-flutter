import 'dart:async';

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
  group('SensorService', () {
    late FakeSensorConnectionAdapter adapter;
    late SensorPreferencesRepository preferences;
    late SensorService service;

    const key = SensorPreferencesRepository.rememberedPowerSensorKey;
    const device = BleSensorDevice(id: 'P1', name: 'Power Meter');

    setUp(() {
      adapter = FakeSensorConnectionAdapter();
      preferences = SensorPreferencesRepository(
        preferences: FakePreferencesStore(),
      );
      service = SensorService(
        adapter: adapter,
        preferences: preferences,
        rememberedKey: key,
      );
    });

    tearDown(() async {
      await service.dispose();
    });

    test('connect sets the device, status, and remembers it', () async {
      await service.connect(device);
      await Future<void>.delayed(Duration.zero);

      expect(service.isConnected, isTrue);
      expect(service.connectedDevice, device);
      expect(await service.rememberedDevice(), device);
    });

    test('connect failure clears the device and rethrows', () async {
      adapter.connectShouldFail = true;

      await expectLater(service.connect(device), throwsA(isA<StateError>()));
      expect(service.connectedDevice, isNull);
      expect(await service.hasRememberedDevice(), isFalse);
    });

    test('latest measurement updates from the stream', () async {
      await service.connect(device);
      adapter.emitMeasurement(
        SensorMeasurement(
          kind: SensorMeasurementKind.power,
          value: 240,
          timestamp: DateTime.utc(2026),
        ),
      );

      expect(service.latestMeasurement?.value, 240);
    });

    test('measurement is cleared when the sensor disconnects', () async {
      await service.connect(device);
      adapter.emitMeasurement(
        SensorMeasurement(
          kind: SensorMeasurementKind.power,
          value: 240,
          timestamp: DateTime.utc(2026),
        ),
      );

      await service.disconnect();
      await Future<void>.delayed(Duration.zero);

      expect(service.latestMeasurement, isNull);
      expect(service.connectedDevice, isNull);
    });

    test('forget clears the remembered device', () async {
      await service.connect(device);
      await Future<void>.delayed(Duration.zero);

      await service.forget();

      expect(await service.hasRememberedDevice(), isFalse);
    });

    test('tryReconnectRemembered connects when ready and remembered', () async {
      await preferences.saveRemembered(key: key, device: device);
      adapter.bluetoothStateValue = SensorBluetoothState.ready;

      final attempted = await service.tryReconnectRemembered();
      await Future<void>.delayed(Duration.zero);

      expect(attempted, isTrue);
      expect(service.isConnected, isTrue);
    });

    test('tryReconnectRemembered no-ops when nothing is remembered', () async {
      adapter.bluetoothStateValue = SensorBluetoothState.ready;

      expect(await service.tryReconnectRemembered(), isFalse);
    });

    test('tryReconnectRemembered no-ops when Bluetooth is not ready', () async {
      await preferences.saveRemembered(key: key, device: device);
      adapter.bluetoothStateValue = SensorBluetoothState.off;

      expect(await service.tryReconnectRemembered(), isFalse);
    });

    test('reconnects when Bluetooth transitions to ready', () async {
      await preferences.saveRemembered(key: key, device: device);
      adapter.bluetoothStateValue = SensorBluetoothState.ready;

      adapter.emitBluetoothState(SensorBluetoothState.ready);
      await Future<void>.delayed(Duration.zero);

      expect(service.isConnected, isTrue);
    });

    test('re-broadcasts Bluetooth state changes', () async {
      final states = <SensorBluetoothState>[];
      service.bluetoothState.listen(states.add);

      adapter.emitBluetoothState(SensorBluetoothState.off);
      await Future<void>.delayed(Duration.zero);

      expect(states, contains(SensorBluetoothState.off));
    });

    test('scan forwards the requested timeout to the adapter', () async {
      await service.scan(timeout: const Duration(seconds: 42)).first;

      expect(adapter.lastScanTimeout, const Duration(seconds: 42));
    });

    test('exposes connection status transitions', () async {
      final statuses = <SensorConnectionStatus>[];
      service.connectionStatus.listen(statuses.add);

      await service.connect(device);
      await Future<void>.delayed(Duration.zero);

      expect(statuses, contains(SensorConnectionStatus.connected));
    });

    test('autoConnectRemembered activates permissions then reconnects', () async {
      await preferences.saveRemembered(key: key, device: device);
      adapter.bluetoothStateValue = SensorBluetoothState.ready;

      await service.autoConnectRemembered();

      // Activates the Bluetooth stack (what iOS needs to reach ready) and then
      // reconnects the remembered sensor without visiting the Sensors screen.
      expect(adapter.ensurePermissionsCalls, greaterThanOrEqualTo(1));
      expect(adapter.connectCalls, [device]);
    });

    test('autoConnectRemembered no-ops without a remembered device', () async {
      await service.autoConnectRemembered();

      expect(adapter.ensurePermissionsCalls, 0);
      expect(adapter.connectCalls, isEmpty);
    });

    test('autoConnectRemembered retries until the sensor connects', () async {
      final retryAdapter = FakeSensorConnectionAdapter()
        ..bluetoothStateValue = SensorBluetoothState.ready
        ..connectFailuresBeforeSuccess = 2;
      final retryPreferences = SensorPreferencesRepository(
        preferences: FakePreferencesStore(),
      );
      await retryPreferences.saveRemembered(key: key, device: device);
      final retryService = SensorService(
        adapter: retryAdapter,
        preferences: retryPreferences,
        rememberedKey: key,
        autoReconnectRetryDelay: Duration.zero,
      );
      addTearDown(retryService.dispose);

      await retryService.autoConnectRemembered();

      // The first two attempts fail; a later one connects, no user interaction.
      expect(retryAdapter.connectCalls.length, greaterThanOrEqualTo(3));
      expect(retryService.isConnected, isTrue);
    });

    test('concurrent tryReconnectRemembered calls share one attempt', () async {
      await preferences.saveRemembered(key: key, device: device);
      adapter
        ..bluetoothStateValue = SensorBluetoothState.ready
        ..connectGate = Completer<void>();

      // Both start before either has awaited anything (cold launch: the
      // launch reconnect and the Bluetooth-ready reconnect race).
      final first = service.tryReconnectRemembered();
      final second = service.tryReconnectRemembered();
      await pumpEventQueue();
      adapter.connectGate!.complete();

      expect(await Future.wait([first, second]), [true, true]);
      expect(adapter.connectCalls, [device]);
      expect(service.isConnected, isTrue);
    });

    test('concurrent autoConnectRemembered calls share one run', () async {
      await preferences.saveRemembered(key: key, device: device);
      adapter
        ..bluetoothStateValue = SensorBluetoothState.ready
        ..connectGate = Completer<void>();

      final first = service.autoConnectRemembered();
      final second = service.autoConnectRemembered();
      await pumpEventQueue();
      adapter.connectGate!.complete();
      await Future.wait([first, second]);

      expect(adapter.ensurePermissionsCalls, 1);
      expect(adapter.connectCalls, [device]);
      expect(service.isConnected, isTrue);
    });

    group('after an unexpected link loss', () {
      late SensorService backoffService;

      setUp(() {
        backoffService = SensorService(
          adapter: adapter,
          preferences: preferences,
          rememberedKey: key,
          linkLossRetryDelays: const [
            Duration(milliseconds: 10),
            Duration(milliseconds: 20),
          ],
        );
        adapter.bluetoothStateValue = SensorBluetoothState.ready;
      });

      tearDown(() => backoffService.dispose());

      test('reconnects the remembered sensor', () async {
        await backoffService.connect(device);

        adapter.emitStatus(SensorConnectionStatus.disconnected);
        expect(backoffService.isConnected, isFalse);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(adapter.connectCalls, [device, device]);
        expect(backoffService.isConnected, isTrue);
      });

      test('keeps retrying with backoff until the sensor is back', () async {
        await backoffService.connect(device);
        adapter.connectShouldFail = true;

        adapter.emitStatus(SensorConnectionStatus.disconnected);
        await Future<void>.delayed(const Duration(milliseconds: 80));
        final failedAttempts = adapter.connectCalls.length - 1;
        expect(failedAttempts, greaterThanOrEqualTo(2));

        adapter.connectShouldFail = false;
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(backoffService.isConnected, isTrue);
        // Connected again: no further attempts.
        final calls = adapter.connectCalls.length;
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(adapter.connectCalls.length, calls);
      });

      test('does not reconnect after the user disconnects', () async {
        await backoffService.connect(device);

        await backoffService.disconnect();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(adapter.connectCalls, [device]);
        expect(backoffService.isConnected, isFalse);
      });

      test('stops retrying once the sensor is forgotten', () async {
        await backoffService.connect(device);
        adapter.connectShouldFail = true;
        adapter.emitStatus(SensorConnectionStatus.disconnected);
        await Future<void>.delayed(const Duration(milliseconds: 15));

        await backoffService.forget();
        final calls = adapter.connectCalls.length;
        await Future<void>.delayed(const Duration(milliseconds: 60));

        expect(adapter.connectCalls.length, calls);
      });

      test('does not reconnect while suppressed by canAutoReconnect', () async {
        var allowed = true;
        final gated = SensorService(
          adapter: adapter,
          preferences: preferences,
          rememberedKey: key,
          canAutoReconnect: () => allowed,
          linkLossRetryDelays: const [Duration(milliseconds: 10)],
        );
        addTearDown(gated.dispose);
        await gated.connect(device);
        final calls = adapter.connectCalls.length;

        allowed = false;
        adapter.emitStatus(SensorConnectionStatus.disconnected);
        await Future<void>.delayed(const Duration(milliseconds: 40));

        expect(adapter.connectCalls.length, calls);
      });
    });

    test(
      'does not auto-reconnect while suppressed by canAutoReconnect',
      () async {
        final suppressed = SensorService(
          adapter: adapter,
          preferences: preferences,
          rememberedKey: key,
          canAutoReconnect: () => false,
        );
        addTearDown(suppressed.dispose);
        await preferences.saveRemembered(key: key, device: device);
        adapter.bluetoothStateValue = SensorBluetoothState.ready;

        final attempted = await suppressed.tryReconnectRemembered();

        expect(attempted, isFalse);
        expect(adapter.connectCalls, isEmpty);
      },
    );
  });
}
