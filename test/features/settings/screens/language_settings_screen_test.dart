import 'package:endurain/core/utils/platform_utils.dart';
import 'package:endurain/features/settings/controllers/locale_controller.dart';
import 'package:endurain/features/settings/repositories/locale_settings_repository.dart';
import 'package:endurain/features/settings/screens/language_settings_screen.dart';
import 'package:endurain/l10n/app_localizations_en.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_preferences_store.dart';

void main() {
  final l10n = AppLocalizationsEn();

  setUp(() {
    PlatformUtils.debugIsApplePlatformOverride = false;
  });

  tearDown(PlatformUtils.debugResetOverrides);

  LocaleController buildController() => LocaleController(
    repository: LocaleSettingsRepository(preferences: FakePreferencesStore()),
  );

  testWidgets('lists the system default and every supported language', (
    tester,
  ) async {
    final controller = buildController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      AdaptiveApp(
        title: 'Test',
        home: LanguageSettingsScreen(localeController: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.languageSystemDefault), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Português'), findsOneWidget);
  });

  testWidgets('marks the active language with a single checkmark', (
    tester,
  ) async {
    final controller = buildController();
    addTearDown(controller.dispose);
    await controller.setLocale(const Locale('pt'));

    await tester.pumpWidget(
      AdaptiveApp(
        title: 'Test',
        home: LanguageSettingsScreen(localeController: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('selecting a language updates the controller and pops', (
    tester,
  ) async {
    final controller = buildController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      AdaptiveApp(
        title: 'Test',
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      LanguageSettingsScreen(localeController: controller),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Português'));
    await tester.pumpAndSettle();

    expect(controller.locale?.languageCode, 'pt');
    expect(controller.locale?.countryCode, 'PT');
    // The picker popped back to the host route.
    expect(find.text('Português'), findsNothing);
  });

  test('languageDisplayName returns autonyms and falls back to the tag', () {
    expect(languageDisplayName(const Locale('en')), 'English');
    expect(languageDisplayName(const Locale('pt')), 'Português');
    expect(languageDisplayName(const Locale('fr')), 'fr');
  });
}
