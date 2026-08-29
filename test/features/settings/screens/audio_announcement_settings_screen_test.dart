import 'package:endurain/core/utils/platform_utils.dart';
import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/models/audio_announcement_settings.dart';
import 'package:endurain/features/activity/repositories/audio_announcement_settings_repository.dart';
import 'package:endurain/features/activity/widgets/activity_type_label.dart';
import 'package:endurain/features/settings/controllers/audio_announcement_settings_controller.dart';
import 'package:endurain/features/settings/controllers/measurement_system_controller.dart';
import 'package:endurain/features/settings/repositories/measurement_settings_repository.dart';
import 'package:endurain/features/settings/screens/audio_announcement_settings_screen.dart';
import 'package:endurain/l10n/app_localizations_en.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/fake_preferences_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final l10n = AppLocalizationsEn();
  late AudioAnnouncementSettingsController controller;
  late MeasurementSystemController measurementController;

  setUp(() {
    PlatformUtils.debugIsApplePlatformOverride = false;
    controller = AudioAnnouncementSettingsController(
      repository: AudioAnnouncementSettingsRepository(
        preferences: FakePreferencesStore(),
      ),
    );
    measurementController = MeasurementSystemController(
      repository: MeasurementSettingsRepository(
        preferences: FakePreferencesStore(),
      ),
    );
  });

  tearDown(() {
    PlatformUtils.debugResetOverrides();
    controller.dispose();
    measurementController.dispose();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      AdaptiveApp(
        title: 'Test',
        locale: const Locale('en'),
        home: AudioAnnouncementSettingsScreen(
          controller: controller,
          measurementSystemController: measurementController,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the master switch off and ducking on by default', (
    tester,
  ) async {
    await pumpScreen(tester);

    final masterSwitch = tester.widget<AdaptiveSwitchListTile>(
      find.widgetWithText(AdaptiveSwitchListTile, l10n.audioAnnouncementsMasterSwitch),
    );
    final duckSwitch = tester.widget<AdaptiveSwitchListTile>(
      find.widgetWithText(AdaptiveSwitchListTile, l10n.audioAnnouncementsDuckSwitch),
    );

    expect(masterSwitch.value, isFalse);
    expect(duckSwitch.value, isTrue);
  });

  testWidgets('shows one interval card per activity type', (tester) async {
    await pumpScreen(tester);

    for (final type in ActivityType.values) {
      expect(find.text(type.localizedLabel(l10n)), findsOneWidget);
    }
  });

  testWidgets('toggling the master switch updates the controller', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(
      find.widgetWithText(AdaptiveSwitchListTile, l10n.audioAnnouncementsMasterSwitch),
    );
    await tester.pumpAndSettle();

    expect(controller.settings.masterEnabled, isTrue);
  });

  testWidgets('shows the default 1.0 km interval for running', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(
      find.text(l10n.audioAnnouncementsIntervalDistance('1.0', 'km')),
      findsWidgets,
    );
  });

  testWidgets('increasing the interval steps by half a kilometre', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.byIcon(Icons.add_circle_outline).first);
    await tester.pumpAndSettle();

    expect(
      controller.settings.intervalFor(ActivityType.run).distanceMeters,
      1500,
    );
  });

  testWidgets('switching to time updates the subtitle', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text(l10n.audioAnnouncementsByTime).first);
    await tester.pumpAndSettle();

    expect(
      controller.settings.intervalFor(ActivityType.run).unit,
      AudioAnnouncementIntervalUnit.time,
    );
    expect(
      find.text(l10n.audioAnnouncementsIntervalTime('5')),
      findsOneWidget,
    );
  });
}
