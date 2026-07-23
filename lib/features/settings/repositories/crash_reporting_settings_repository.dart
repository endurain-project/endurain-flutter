import 'package:endurain/core/services/app_preferences_store.dart';

/// Persists the user's opt-in choice for remote crash reporting.
///
/// Stored in the non-secret [AppPreferencesStore]: the enabled flag is a
/// display preference. This is deliberately separate from — and independent
/// of — the local diagnostics opt-in, so the user can enable neither, either,
/// or both. The reporting target is always Endurain's managed diagnostics
/// endpoint (`AppConfig.crashReportingDsn`); users do not configure a DSN.
class CrashReportingSettingsRepository {
  const CrashReportingSettingsRepository({
    required AppPreferencesStore preferences,
  }) : _preferences = preferences;

  static const String _enabledKey = 'crash_reporting_enabled';

  final AppPreferencesStore _preferences;

  /// Whether the user has opted in to remote crash reporting. Defaults to
  /// `false` — nothing is transmitted until the user turns this on.
  Future<bool> isEnabled() async =>
      await _preferences.read(key: _enabledKey) == 'true';

  Future<void> setEnabled(bool enabled) =>
      _preferences.write(key: _enabledKey, value: enabled ? 'true' : 'false');
}
