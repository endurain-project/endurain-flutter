import 'package:endurain/core/localization/app_locales.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('appSupportedLocales', () {
    test('advertises English and European Portuguese', () {
      expect(appSupportedLocales, contains(const Locale('en')));
      expect(appSupportedLocales, contains(const Locale('pt', 'PT')));
    });

    test('advertises Simplified and Traditional Chinese distinctly', () {
      expect(
        appSupportedLocales,
        contains(
          const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
        ),
      );
      expect(
        appSupportedLocales,
        contains(
          const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
        ),
      );
    });

    test('Portuguese is region-qualified as pt-PT (BCP 47)', () {
      final portuguese = appSupportedLocales.firstWhere(
        (locale) => locale.languageCode == 'pt',
      );

      expect(portuguese.countryCode, 'PT');
      expect(portuguese.toLanguageTag(), 'pt-PT');
    });

    test('language subtags stay in sync with generated supportedLocales', () {
      Set<String> languageCodes(Iterable<Locale> locales) =>
          locales.map((locale) => locale.languageCode).toSet();

      // The app advertises canonical BCP 47 identities (e.g. pt-PT) while
      // string resources are generated from the base language ARBs. Guard
      // against the two lists drifting apart when a language is added.
      expect(
        languageCodes(appSupportedLocales),
        languageCodes(AppLocalizations.supportedLocales),
      );
    });
  });

  group('appLocaleListResolution', () {
    Locale resolve(List<Locale>? preferred) =>
        appLocaleListResolution(preferred, appSupportedLocales);

    test('maps unqualified Portuguese to pt-PT', () {
      expect(resolve(const [Locale('pt')]), const Locale('pt', 'PT'));
    });

    test('maps Brazilian Portuguese to pt-PT', () {
      expect(resolve(const [Locale('pt', 'BR')]), const Locale('pt', 'PT'));
    });

    test('keeps European Portuguese as pt-PT', () {
      expect(resolve(const [Locale('pt', 'PT')]), const Locale('pt', 'PT'));
    });

    test('serves Portuguese when it leads the preference list', () {
      expect(
        resolve(const [Locale('pt', 'BR'), Locale('en')]),
        const Locale('pt', 'PT'),
      );
    });

    test('respects an English-first preference over Portuguese', () {
      expect(
        resolve(const [Locale('en', 'US'), Locale('pt', 'BR')]),
        const Locale('en'),
      );
    });

    test('serves Simplified Chinese for its BCP 47 identity', () {
      expect(
        resolve(const [
          Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
        ]),
        const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
      );
    });

    test('serves Traditional Chinese for its BCP 47 identity', () {
      expect(
        resolve(const [
          Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
        ]),
        const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
      );
    });

    test('falls back to the first supported locale for other languages', () {
      expect(resolve(const [Locale('ja')]), const Locale('en'));
    });

    test('falls back to the first supported locale when none is provided', () {
      expect(resolve(null), const Locale('en'));
      expect(resolve(const []), const Locale('en'));
    });
  });
}
