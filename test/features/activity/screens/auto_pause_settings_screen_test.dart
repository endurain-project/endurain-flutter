import 'package:endurain/features/activity/controllers/auto_pause_settings_controller.dart';
import 'package:endurain/features/activity/repositories/auto_pause_settings_repository.dart';
import 'package:endurain/features/activity/screens/auto_pause_settings_screen.dart';
import 'package:endurain/l10n/app_localizations_en.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/fake_preferences_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final l10n = AppLocalizationsEn();
  late AutoPauseSettingsRepository repository;
  late AutoPauseSettingsController controller;

  setUp(() {
    repository = AutoPauseSettingsRepository(
      preferences: FakePreferencesStore(),
    );
    controller = AutoPauseSettingsController(repository: repository);
  });

  tearDown(() => controller.dispose());

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      AdaptiveApp(
        title: 'Test',
        locale: const Locale('en'),
        home: AutoPauseSettingsScreen(controller: controller),
      ),
    );
  }

  testWidgets('shows the toggle enabled by default with delay options', (
    tester,
  ) async {
    await pumpScreen(tester);
    await tester.pumpAndSettle();

    expect(find.text(l10n.activityAutoPauseToggleLabel), findsOneWidget);
    expect(
      find.text(l10n.activityAutoPauseDelayOptionLabel(5)),
      findsOneWidget,
    );
    expect(
      find.text(l10n.activityAutoPauseDelayOptionLabel(60)),
      findsOneWidget,
    );
  });

  testWidgets('hides the delay options when auto-pause is disabled', (
    tester,
  ) async {
    await repository.setEnabled(false);
    await pumpScreen(tester);
    await tester.pumpAndSettle();

    expect(find.text(l10n.activityAutoPauseDelayOptionLabel(5)), findsNothing);
  });

  testWidgets('toggling the switch persists the preference', (tester) async {
    await pumpScreen(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.activityAutoPauseToggleLabel));
    await tester.pumpAndSettle();

    expect(controller.enabled, isFalse);
    expect(await repository.isEnabled(), isFalse);
    expect(find.text(l10n.activityAutoPauseDelayOptionLabel(5)), findsNothing);
  });

  testWidgets('selecting a delay preset persists it', (tester) async {
    await pumpScreen(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.activityAutoPauseDelayOptionLabel(30)));
    await tester.pumpAndSettle();

    expect(controller.delaySeconds, 30);
    expect(await repository.getDelaySeconds(), 30);
    expect(find.byIcon(Icons.check), findsOneWidget);
  });
}
