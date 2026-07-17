import 'dart:async';

import 'package:endurain/core/utils/platform_utils.dart';
import 'package:endurain/features/sensors/controllers/sensor_settings_controller.dart';
import 'package:endurain/features/sensors/models/ble_sensor_device.dart';
import 'package:endurain/features/sensors/models/heart_rate_sample.dart';
import 'package:endurain/features/sensors/models/sensor_bluetooth_state.dart';
import 'package:endurain/features/sensors/repositories/sensor_preferences_repository.dart';
import 'package:endurain/features/sensors/screens/sensor_settings_screen.dart';
import 'package:endurain/features/sensors/services/heart_rate_sensor_service.dart';
import 'package:endurain/l10n/app_localizations_en.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_preferences_store.dart';
import '../fakes/fake_heart_rate_sensor_adapter.dart';

void main() {
  final l10n = AppLocalizationsEn();

  late FakeHeartRateSensorAdapter adapter;
  late SensorPreferencesRepository preferences;
  late HeartRateSensorService service;
  late SensorSettingsController controller;

  setUp(() {
    // Force Material rendering so ListTile hit-testing is deterministic on the
    // (Apple) host test runner.
    PlatformUtils.debugIsApplePlatformOverride = false;
    adapter = FakeHeartRateSensorAdapter();
    preferences = SensorPreferencesRepository(
      preferences: FakePreferencesStore(),
    );
    service = HeartRateSensorService(
      adapter: adapter,
      preferences: preferences,
    );
    controller = SensorSettingsController(service: service);
  });

  tearDown(() async {
    controller.dispose();
    await service.dispose();
    PlatformUtils.debugResetOverrides();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      AdaptiveApp(
        title: 'Test',
        home: SensorSettingsScreen(controller: controller),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('shows the scan control when Bluetooth is ready', (tester) async {
    adapter.bluetoothStateValue = SensorBluetoothState.ready;

    await pumpScreen(tester);

    expect(find.text(l10n.sensorsHeartRateHelp), findsOneWidget);
    expect(find.text(l10n.sensorsScan), findsOneWidget);
  });

  testWidgets('explains when Bluetooth is off', (tester) async {
    adapter.bluetoothStateValue = SensorBluetoothState.off;

    await pumpScreen(tester);

    expect(find.text(l10n.sensorsBluetoothOff), findsOneWidget);
    expect(find.text(l10n.sensorsScan), findsNothing);
  });

  testWidgets('requests Bluetooth permission when opened', (tester) async {
    adapter.bluetoothStateValue = SensorBluetoothState.ready;

    await pumpScreen(tester);

    expect(adapter.ensurePermissionsCalls, greaterThanOrEqualTo(1));
  });

  testWidgets('guides the user to allow access when the state is unknown', (
    tester,
  ) async {
    adapter.bluetoothStateValue = SensorBluetoothState.unknown;

    await pumpScreen(tester);

    expect(find.text(l10n.sensorsBluetoothUnauthorized), findsOneWidget);
    expect(find.text(l10n.sensorsScan), findsNothing);
  });

  testWidgets('lists discovered sensors while scanning', (tester) async {
    adapter.bluetoothStateValue = SensorBluetoothState.ready;
    adapter.scanDevices = const [BleSensorDevice(id: '1', name: 'Polar H10')];

    await pumpScreen(tester);

    await tester.tap(find.text(l10n.sensorsScan));
    await tester.pump();
    await tester.pump();

    expect(find.text(l10n.sensorsAvailableSection), findsOneWidget);
    expect(find.text('Polar H10'), findsOneWidget);
  });

  testWidgets('shows a connecting hint on the sensor being connected', (
    tester,
  ) async {
    const device = BleSensorDevice(id: '1', name: 'Polar H10');
    adapter.bluetoothStateValue = SensorBluetoothState.ready;
    adapter.scanDevices = const [device];
    // Hold the connect open so the connecting state stays observable.
    adapter.connectGate = Completer<void>();

    await pumpScreen(tester);

    // Scan to surface the sensor as an available result.
    await tester.tap(find.text(l10n.sensorsScan));
    await tester.pump();
    await tester.pump();
    expect(find.text('Polar H10'), findsOneWidget);

    // Start connecting (what tapping the result does) and let the service
    // forward the "connecting" status to the controller. runAsync flushes the
    // real microtask that the service's broadcast delivery relies on.
    await tester.runAsync(() async {
      unawaited(service.connect(device));
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pump();

    expect(find.text(l10n.sensorsConnecting), findsOneWidget);

    // Release the held connect so the pending future resolves before teardown.
    adapter.connectGate!.complete();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
  });

  testWidgets('shows the live heart rate when a sensor is connected', (
    tester,
  ) async {
    const device = BleSensorDevice(id: '1', name: 'Polar H10');
    adapter.bluetoothStateValue = SensorBluetoothState.ready;

    // The fake delivers events synchronously, so priming the service here caches
    // the connected state and latest sample that the screen reads on init.
    unawaited(service.connect(device));
    adapter.emitHeartRate(
      HeartRateSample(bpm: 72, timestamp: DateTime.utc(2026)),
    );

    await pumpScreen(tester);

    expect(find.text(l10n.sensorsConnected), findsOneWidget);
    expect(find.text('Polar H10'), findsOneWidget);
    expect(find.text(l10n.sensorsBpm('72')), findsOneWidget);
    expect(find.text(l10n.sensorsDisconnect), findsOneWidget);
  });
}
