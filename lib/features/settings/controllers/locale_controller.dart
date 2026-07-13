import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'package:endurain/features/settings/repositories/locale_settings_repository.dart';

/// App-wide selected [Locale], persisted as a BCP 47 tag.
///
/// A `null` [locale] means "follow the system locale". Owned by `AppServices`
/// so the root `App` can listen and rebuild the localized widget tree when the
/// user changes languages in Settings.
class LocaleController extends ChangeNotifier {
  LocaleController({required this._repository});

  final LocaleSettingsRepository _repository;

  Locale? _locale;
  bool _isLoaded = false;

  /// The selected locale, or `null` to follow the system locale.
  Locale? get locale => _locale;

  /// Whether the persisted preference has been read yet.
  bool get isLoaded => _isLoaded;

  /// Loads the persisted locale once at startup. On any read error the app
  /// silently falls back to the system locale.
  Future<void> load() async {
    try {
      _locale = await _repository.getLocale();
    } catch (_) {
      _locale = null;
    }
    _isLoaded = true;
    notifyListeners();
  }

  /// Selects [locale] (or `null` for the system default), notifies listeners
  /// immediately, then persists the choice.
  Future<void> setLocale(Locale? locale) async {
    if (_locale == locale) {
      return;
    }
    _locale = locale;
    notifyListeners();
    await _repository.setLocale(locale);
  }
}
