import 'package:endurain/core/models/measurement_system.dart';
import 'package:endurain/core/services/platform/device_measurement_system_service.dart';
import 'package:endurain/core/utils/platform_utils.dart';
import 'package:endurain/features/settings/controllers/measurement_system_controller.dart';
import 'package:endurain/features/settings/repositories/measurement_settings_repository.dart';
import 'package:endurain/features/settings/screens/units_settings_screen.dart';
import 'package:endurain/l10n/app_localizations_en.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_preferences_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final l10n = AppLocalizationsEn();
  late MeasurementSystemController controller;

  setUp(() {
    PlatformUtils.debugIsApplePlatformOverride = false;
    controller = MeasurementSystemController(
      repository: MeasurementSettingsRepository(
        preferences: FakePreferencesStore(),
      ),
    );
  });

  tearDown(() {
    PlatformUtils.debugResetOverrides();
    controller.dispose();
  });

  /// Pumps the screen with [deviceLocale] reported as the *platform* locale.
  ///
  /// The region default is derived from the device locale, not the app's
  /// resolved (language-only) locale, so the test must set the platform value.
  Future<void> pumpScreen(WidgetTester tester, {Locale? deviceLocale}) async {
    if (deviceLocale != null) {
      tester.platformDispatcher.localeTestValue = deviceLocale;
      tester.platformDispatcher.localesTestValue = [deviceLocale];
      addTearDown(tester.platformDispatcher.clearLocaleTestValue);
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    }
    await tester.pumpWidget(
      AdaptiveApp(
        title: 'Test',
        locale: const Locale('en'),
        home: UnitsSettingsScreen(controller: controller),
      ),
    );
  }

  testWidgets('shows the three unit options', (tester) async {
    await pumpScreen(tester);
    await tester.pumpAndSettle();

    expect(find.text(l10n.unitsSystemDefault), findsOneWidget);
    expect(find.text(l10n.unitsMetric), findsWidgets);
    expect(find.text(l10n.unitsImperial), findsWidgets);
  });

  testWidgets('marks follow-device-region as selected by default', (
    tester,
  ) async {
    await pumpScreen(tester);
    await tester.pumpAndSettle();

    // Exactly one option carries the selected checkmark.
    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(controller.preference, isNull);
  });

  testWidgets('describes the device default for a US locale', (tester) async {
    await pumpScreen(tester, deviceLocale: const Locale('en', 'US'));
    await tester.pumpAndSettle();

    // The follow-device row shows what that currently resolves to (imperial),
    // and the standalone Imperial option is also present.
    expect(find.text(l10n.unitsImperial), findsNWidgets(2));
  });

  testWidgets('describes the device default for a metric locale', (
    tester,
  ) async {
    await pumpScreen(tester, deviceLocale: const Locale('en', 'AU'));
    await tester.pumpAndSettle();

    expect(find.text(l10n.unitsMetric), findsNWidgets(2));
  });

  testWidgets('uses the device unit setting ahead of its region', (
    tester,
  ) async {
    controller.dispose();
    controller = MeasurementSystemController(
      repository: MeasurementSettingsRepository(
        preferences: FakePreferencesStore(),
      ),
      deviceMeasurementSystem: const _FakeDeviceMeasurementSystemService(
        MeasurementSystem.metric,
      ),
    );
    await controller.load();

    await pumpScreen(tester, deviceLocale: const Locale('en', 'US'));
    await tester.pumpAndSettle();

    expect(find.text(l10n.unitsMetric), findsNWidgets(2));
    expect(find.text(l10n.unitsImperial), findsOneWidget);
  });

  testWidgets('selecting imperial persists and updates the checkmark', (
    tester,
  ) async {
    await pumpScreen(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.unitsImperial).last);
    await tester.pumpAndSettle();

    expect(controller.preference, MeasurementSystem.imperial);
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('selecting follow-device clears the explicit preference', (
    tester,
  ) async {
    await controller.setPreference(MeasurementSystem.metric);
    await pumpScreen(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.unitsSystemDefault));
    await tester.pumpAndSettle();

    expect(controller.preference, isNull);
  });
}

class _FakeDeviceMeasurementSystemService
    implements DeviceMeasurementSystemService {
  const _FakeDeviceMeasurementSystemService(this.system);

  final MeasurementSystem system;

  @override
  Future<MeasurementSystem?> getMeasurementSystem() async => system;
}
