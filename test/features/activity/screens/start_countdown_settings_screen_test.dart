import 'package:endurain/features/activity/controllers/start_countdown_settings_controller.dart';
import 'package:endurain/features/activity/repositories/start_countdown_settings_repository.dart';
import 'package:endurain/features/activity/screens/start_countdown_settings_screen.dart';
import 'package:endurain/l10n/app_localizations_en.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/fake_preferences_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final l10n = AppLocalizationsEn();
  late StartCountdownSettingsRepository repository;
  late StartCountdownSettingsController controller;

  setUp(() {
    repository = StartCountdownSettingsRepository(
      preferences: FakePreferencesStore(),
    );
    controller = StartCountdownSettingsController(repository: repository);
  });

  tearDown(() => controller.dispose());

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      AdaptiveApp(
        title: 'Test',
        locale: const Locale('en'),
        home: StartCountdownSettingsScreen(controller: controller),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('is off by default and hides the options', (tester) async {
    await pumpScreen(tester);

    expect(find.text(l10n.startCountdownToggleLabel), findsOneWidget);
    expect(find.text(l10n.startCountdownDurationOptionLabel(10)), findsNothing);
    expect(find.text(l10n.startCountdownVoiceLabel), findsNothing);
  });

  testWidgets('turning it on shows the options and saves a choice', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.text(l10n.startCountdownToggleLabel));
    await tester.pumpAndSettle();

    expect(find.text(l10n.startCountdownVoiceLabel), findsOneWidget);
    for (final seconds in [3, 5, 10, 15, 30]) {
      expect(
        find.text(l10n.startCountdownDurationOptionLabel(seconds)),
        findsOneWidget,
      );
    }

    await tester.tap(find.text(l10n.startCountdownDurationOptionLabel(5)));
    await tester.pumpAndSettle();

    final config = await repository.getConfig();
    expect(config.enabled, isTrue);
    expect(config.seconds, 5);
  });
}
