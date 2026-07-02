import 'dart:ui';

import 'package:endurain/core/services/app_preferences_store.dart';

/// Persists the user's selected app language as a BCP 47 language tag
/// (e.g. `en`, `pt`, `pt-BR`) in [AppPreferencesStore].
///
/// The BCP 47 representation mirrors what the Endurain backend and web client
/// use, so a language chosen here can round-trip across the stack. A missing
/// value means "follow the system locale".
class LocaleSettingsRepository {
  const LocaleSettingsRepository({required AppPreferencesStore preferences})
    : _preferences = preferences;

  static const _localeTagKey = 'app_locale';

  final AppPreferencesStore _preferences;

  /// Reads the persisted language as a [Locale], or `null` to follow the
  /// system locale (no stored preference).
  Future<Locale?> getLocale() async {
    final tag = await _preferences.read(key: _localeTagKey);
    if (tag == null) {
      return null;
    }
    return localeFromLanguageTag(tag);
  }

  /// Persists [locale] as a BCP 47 tag, or clears the preference (falling back
  /// to the system locale) when [locale] is `null`.
  Future<void> setLocale(Locale? locale) {
    if (locale == null) {
      return _preferences.delete(key: _localeTagKey);
    }
    return _preferences.write(
      key: _localeTagKey,
      value: locale.toLanguageTag(),
    );
  }

  /// Parses a BCP 47 language [tag] into a [Locale].
  ///
  /// Handles the `language`, `language-REGION`, and `language-Script-REGION`
  /// shapes produced by [Locale.toLanguageTag]. Returns `null` for a blank tag.
  static Locale? localeFromLanguageTag(String tag) {
    final subtags = tag.trim().split('-');
    final language = subtags.first;
    if (language.isEmpty) {
      return null;
    }
    String? script;
    String? region;
    for (final subtag in subtags.skip(1)) {
      if (subtag.length == 4) {
        // ISO 15924 script subtag, e.g. `Hant`.
        script = subtag;
      } else if (subtag.length == 2 || subtag.length == 3) {
        // ISO 3166-1 alpha-2 or UN M.49 region subtag, e.g. `BR` / `419`.
        region = subtag.toUpperCase();
      }
    }
    return Locale.fromSubtags(
      languageCode: language,
      scriptCode: script,
      countryCode: region,
    );
  }
}
