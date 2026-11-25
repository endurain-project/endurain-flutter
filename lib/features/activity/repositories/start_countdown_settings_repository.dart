import 'package:endurain/core/services/app_preferences_store.dart';

/// The start-countdown preferences read when the user taps Start.
class StartCountdownConfig {
  const StartCountdownConfig({
    required this.enabled,
    required this.seconds,
    required this.voiceEnabled,
  });

  /// Whether tapping Start shows a countdown before recording begins.
  final bool enabled;

  /// Countdown length in seconds.
  final int seconds;

  /// Whether the last seconds and the start are spoken aloud.
  final bool voiceEnabled;

  static const StartCountdownConfig defaults = StartCountdownConfig(
    enabled: StartCountdownSettingsRepository.defaultEnabled,
    seconds: StartCountdownSettingsRepository.defaultSeconds,
    voiceEnabled: StartCountdownSettingsRepository.defaultVoiceEnabled,
  );
}

/// Persists the start-countdown preferences in [AppPreferencesStore].
///
/// Off by default so tapping Start keeps recording immediately until the user
/// opts in. Missing or malformed values fall back to the defaults.
class StartCountdownSettingsRepository {
  const StartCountdownSettingsRepository({required this.preferences});

  static const String enabledKey = 'activity_start_countdown_enabled';
  static const String secondsKey = 'activity_start_countdown_seconds';
  static const String voiceEnabledKey =
      'activity_start_countdown_voice_enabled';

  static const bool defaultEnabled = false;
  static const int defaultSeconds = 10;
  static const bool defaultVoiceEnabled = true;

  /// Inclusive bounds for the configurable countdown length.
  static const int minSeconds = 3;
  static const int maxSeconds = 60;

  final AppPreferencesStore preferences;

  Future<bool> isEnabled() => _readBool(enabledKey, defaultEnabled);

  Future<void> setEnabled(bool enabled) => _writeBool(enabledKey, enabled);

  Future<bool> isVoiceEnabled() =>
      _readBool(voiceEnabledKey, defaultVoiceEnabled);

  Future<void> setVoiceEnabled(bool enabled) =>
      _writeBool(voiceEnabledKey, enabled);

  /// The configured countdown length, clamped to [minSeconds]..[maxSeconds].
  Future<int> getSeconds() async {
    final raw = await preferences.read(key: secondsKey);
    final stored = raw == null ? null : int.tryParse(raw);
    if (stored == null) {
      return defaultSeconds;
    }
    return clampSeconds(stored);
  }

  Future<void> setSeconds(int seconds) {
    return preferences.write(
      key: secondsKey,
      value: clampSeconds(seconds).toString(),
    );
  }

  static int clampSeconds(int seconds) {
    if (seconds < minSeconds) {
      return minSeconds;
    }
    if (seconds > maxSeconds) {
      return maxSeconds;
    }
    return seconds;
  }

  /// Reads every preference at once, falling back to the defaults on a read
  /// failure so a storage problem never blocks starting a recording.
  Future<StartCountdownConfig> getConfig() async {
    try {
      return StartCountdownConfig(
        enabled: await isEnabled(),
        seconds: await getSeconds(),
        voiceEnabled: await isVoiceEnabled(),
      );
    } catch (_) {
      return StartCountdownConfig.defaults;
    }
  }

  Future<bool> _readBool(String key, bool fallback) async {
    final stored = await preferences.read(key: key);
    if (stored == null) {
      return fallback;
    }
    return stored == 'true';
  }

  Future<void> _writeBool(String key, bool value) {
    return preferences.write(key: key, value: value ? 'true' : 'false');
  }
}
