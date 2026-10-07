import 'package:endurain/core/services/app_preferences_store.dart';
import 'package:endurain/features/activity/services/movement_auto_pause_detector.dart';

/// Persists the user's auto-pause preference in [AppPreferencesStore].
///
/// Auto-pause is a non-secret recording preference, so it lives in shared
/// preferences alongside the other display/behavior settings rather than in
/// secure storage. Missing values fall back to sensible defaults so a first
/// launch behaves reasonably without the user configuring anything:
/// enabled by default, with a 5 second stillness delay.
class AutoPauseSettingsRepository {
  const AutoPauseSettingsRepository({required this.preferences});

  static const String enabledKey = 'activity_auto_pause_enabled';
  static const String delaySecondsKey = 'activity_auto_pause_delay_seconds';

  /// Inclusive bounds for the configurable stillness delay.
  static const bool defaultEnabled = true;
  static const int minDelaySeconds = 5;
  static const int maxDelaySeconds = 60;
  static const int defaultDelaySeconds = 5;

  final AppPreferencesStore preferences;

  /// Whether auto-pause is enabled. Defaults to `true` when unset.
  Future<bool> isEnabled() async {
    final stored = await preferences.read(key: enabledKey);
    if (stored == null) {
      return defaultEnabled;
    }
    return stored == 'true';
  }

  Future<void> setEnabled(bool enabled) {
    return preferences.write(
      key: enabledKey,
      value: enabled ? 'true' : 'false',
    );
  }

  /// The configured stillness delay in seconds, clamped to
  /// [minDelaySeconds]..[maxDelaySeconds]. Defaults to [defaultDelaySeconds]
  /// when unset or when the stored value is malformed.
  Future<int> getDelaySeconds() async {
    final raw = await preferences.read(key: delaySecondsKey);
    final stored = raw == null ? null : int.tryParse(raw);
    if (stored == null) {
      return defaultDelaySeconds;
    }
    return clampDelaySeconds(stored);
  }

  /// Persists [seconds], clamped to the supported range.
  Future<void> setDelaySeconds(int seconds) {
    return preferences.write(
      key: delaySecondsKey,
      value: clampDelaySeconds(seconds).toString(),
    );
  }

  /// Clamps [seconds] to [minDelaySeconds]..[maxDelaySeconds].
  static int clampDelaySeconds(int seconds) {
    if (seconds < minDelaySeconds) {
      return minDelaySeconds;
    }
    if (seconds > maxDelaySeconds) {
      return maxDelaySeconds;
    }
    return seconds;
  }

  /// Reads both preferences and builds the resulting detector configuration.
  Future<MovementAutoPauseConfig> getConfig() async {
    final enabled = await isEnabled();
    final delaySeconds = await getDelaySeconds();
    return MovementAutoPauseConfig(
      enabled: enabled,
      pauseDelay: Duration(seconds: delaySeconds),
    );
  }
}
