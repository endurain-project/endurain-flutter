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
}
