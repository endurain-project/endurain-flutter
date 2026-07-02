import 'dart:ui';

import 'package:endurain/features/settings/repositories/locale_settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_preferences_store.dart';

void main() {
  group('LocaleSettingsRepository', () {
    late FakePreferencesStore preferences;
    late LocaleSettingsRepository repository;

    setUp(() {
      preferences = FakePreferencesStore();
      repository = LocaleSettingsRepository(preferences: preferences);
    });

    test('returns null when no locale is stored', () async {
      expect(await repository.getLocale(), isNull);
    });

    test('persists a locale as a BCP 47 tag and reads it back', () async {
      await repository.setLocale(const Locale('pt'));

      expect(await preferences.read(key: 'app_locale'), 'pt');
      expect(await repository.getLocale(), const Locale('pt'));
    });

    test('stores region subtags as a BCP 47 tag', () async {
      await repository.setLocale(const Locale('pt', 'BR'));

      expect(await preferences.read(key: 'app_locale'), 'pt-BR');
      final loaded = await repository.getLocale();
      expect(loaded?.languageCode, 'pt');
      expect(loaded?.countryCode, 'BR');
    });

    test('clears the stored preference when set to null', () async {
      await repository.setLocale(const Locale('en'));

      await repository.setLocale(null);

      expect(await preferences.read(key: 'app_locale'), isNull);
      expect(await repository.getLocale(), isNull);
    });

    group('localeFromLanguageTag', () {
      test('parses a plain language subtag', () {
        expect(
          LocaleSettingsRepository.localeFromLanguageTag('en'),
          const Locale('en'),
        );
      });

      test('parses a language-region tag', () {
        final locale = LocaleSettingsRepository.localeFromLanguageTag('pt-BR');
        expect(locale?.languageCode, 'pt');
        expect(locale?.countryCode, 'BR');
      });

      test('parses a language-script-region tag', () {
        final locale = LocaleSettingsRepository.localeFromLanguageTag(
          'zh-Hant-TW',
        );
        expect(locale?.languageCode, 'zh');
        expect(locale?.scriptCode, 'Hant');
        expect(locale?.countryCode, 'TW');
      });

      test('returns null for a blank tag', () {
        expect(LocaleSettingsRepository.localeFromLanguageTag('  '), isNull);
      });
    });
  });
}
