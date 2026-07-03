import 'package:endurain/core/localization/app_locales.dart';
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
    for (final locale in languagePickerLocales) {
      expect(find.text(languageDisplayName(locale)), findsOneWidget);
    }
  });

  test('languagePickerLocales contains every locale in alphabetical order', () {
    expect(languagePickerLocales.toSet(), appSupportedLocales.toSet());
    expect(
      languagePickerLocales.map(languageDisplayName),
      orderedEquals([
        'Català',
        'Čeština',
        'Dansk',
        'Deutsch',
        'Eesti',
        'English',
        'Español',
        'Français',
        'Galego',
        'Hrvatski',
        'Italiano',
        'Latviešu',
        'Lietuvių',
        'Magyar',
        'Nederlands',
        'Norsk bokmål',
        'Polski',
        'Português',
        'Română',
        'Slovenčina',
        'Slovenščina',
        'Suomi',
        'Svenska',
        'Türkçe',
        'Ελληνικά',
        'Български',
        'Српски',
        'Українська',
        '简体中文',
        '繁體中文',
      ]),
    );
  });

  testWidgets('marks the active language with a single checkmark', (
    tester,
  ) async {
    final controller = buildController();
    addTearDown(controller.dispose);
    await controller.setLocale(const Locale('pt', 'PT'));

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

    await tester.drag(find.byType(ListView), const Offset(0, -700));
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
    expect(languageDisplayName(const Locale('pt', 'PT')), 'Português');
    expect(
      languageDisplayName(
        const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
      ),
      '繁體中文',
    );
    expect(languageDisplayName(const Locale('xx')), 'xx');
  });
}
