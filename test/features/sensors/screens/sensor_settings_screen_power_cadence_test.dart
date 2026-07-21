import 'dart:async';

import 'package:endurain/core/utils/platform_utils.dart';
import 'package:endurain/features/sensors/controllers/sensor_section_controller.dart';
import 'package:endurain/features/sensors/models/ble_sensor_device.dart';
import 'package:endurain/features/sensors/models/sensor_bluetooth_state.dart';
import 'package:endurain/features/sensors/models/sensor_measurement.dart';
import 'package:endurain/features/sensors/repositories/sensor_preferences_repository.dart';
import 'package:endurain/features/sensors/screens/sensor_settings_screen.dart';
import 'package:endurain/features/sensors/services/sensor_service.dart';
import 'package:endurain/l10n/app_localizations_en.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_preferences_store.dart';
import '../../../helpers/widget_test_app.dart';
import '../fakes/fake_sensor_connection_adapter.dart';

void main() {
  final l10n = AppLocalizationsEn();

  late FakeSensorConnectionAdapter heartRateAdapter;
  late SensorService heartRateService;
  late SensorSectionController heartRateController;

  late FakeSensorConnectionAdapter powerAdapter;
  late SensorService powerService;
  late SensorSectionController powerController;

  late FakeSensorConnectionAdapter cadenceAdapter;
  late SensorService cadenceService;
  late SensorSectionController cadenceController;

  SensorPreferencesRepository prefs() =>
      SensorPreferencesRepository(preferences: FakePreferencesStore());

  setUp(() {
    PlatformUtils.debugIsApplePlatformOverride = false;

    // Keep the heart-rate section quiet (Bluetooth off) so the assertions below
    // target the power and cadence sections.
    heartRateAdapter = FakeSensorConnectionAdapter()
      ..bluetoothStateValue = SensorBluetoothState.off;
    heartRateService = SensorService(
      adapter: heartRateAdapter,
      preferences: prefs(),
      rememberedKey: SensorPreferencesRepository.rememberedHeartRateSensorKey,
    );
    heartRateController = SensorSectionController(service: heartRateService);

    powerAdapter = FakeSensorConnectionAdapter()
      ..bluetoothStateValue = SensorBluetoothState.ready;
    powerService = SensorService(
      adapter: powerAdapter,
      preferences: prefs(),
      rememberedKey: SensorPreferencesRepository.rememberedPowerSensorKey,
    );
    powerController = SensorSectionController(service: powerService);

    cadenceAdapter = FakeSensorConnectionAdapter()
      ..bluetoothStateValue = SensorBluetoothState.ready;
    cadenceService = SensorService(
      adapter: cadenceAdapter,
      preferences: prefs(),
      rememberedKey: SensorPreferencesRepository.rememberedCadenceSensorKey,
    );
    cadenceController = SensorSectionController(service: cadenceService);
  });

  tearDown(() async {
    heartRateController.dispose();
    powerController.dispose();
    cadenceController.dispose();
    await heartRateService.dispose();
    await powerService.dispose();
    await cadenceService.dispose();
    PlatformUtils.debugResetOverrides();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      AdaptiveApp(
        title: 'Test',
        home: TestAppScope(
          child: SensorSettingsScreen(
            controller: heartRateController,
            powerController: powerController,
            cadenceController: cadenceController,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('renders the power and cadence sections', (tester) async {
    await pumpScreen(tester);

    expect(find.text(l10n.sensorsPowerSection), findsOneWidget);
    expect(find.text(l10n.sensorsPowerHelp), findsOneWidget);
    expect(find.text(l10n.sensorsCadenceSection), findsOneWidget);
    expect(find.text(l10n.sensorsCadenceHelp), findsOneWidget);
  });

  testWidgets('shows live power in watts when a power meter is connected', (
    tester,
  ) async {
    const device = BleSensorDevice(id: 'P1', name: 'Assioma');
    // Prime the connected state and latest measurement synchronously so the
    // section controller reads them on init (the fake delivers events sync).
    unawaited(powerService.connect(device));
    powerAdapter.emitMeasurement(
      SensorMeasurement(
        kind: SensorMeasurementKind.power,
        value: 250,
        timestamp: DateTime.utc(2026),
      ),
    );

    await pumpScreen(tester);

    expect(find.text('Assioma'), findsOneWidget);
    expect(find.text(l10n.sensorsWatts('250')), findsOneWidget);
  });

  testWidgets('shows live cadence in rpm when a cadence sensor is connected', (
    tester,
  ) async {
    const device = BleSensorDevice(id: 'C1', name: 'Wahoo RPM');
    unawaited(cadenceService.connect(device));
    cadenceAdapter.emitMeasurement(
      SensorMeasurement(
        kind: SensorMeasurementKind.cadence,
        value: 88,
        timestamp: DateTime.utc(2026),
      ),
    );

    await pumpScreen(tester);

    expect(find.text('Wahoo RPM'), findsOneWidget);
    expect(find.text(l10n.sensorsRpm('88')), findsOneWidget);
  });
}
