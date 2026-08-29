import 'package:endurain/core/services/app_preferences_store.dart';
import 'package:endurain/features/activity/models/audio_announcement_settings.dart';

/// Persists [AudioAnnouncementSettings] in [AppPreferencesStore].
///
/// This is a non-secret display/behavior preference (like the measurement
/// system and locale choices), so it lives in shared preferences rather than
/// secure storage.
class AudioAnnouncementSettingsRepository {
  const AudioAnnouncementSettingsRepository({required AppPreferencesStore preferences})
    : _preferences = preferences;

  static const String _settingsKey = 'audio_announcement_settings_v1';

  final AppPreferencesStore _preferences;

  Future<AudioAnnouncementSettings> getSettings() async {
    final stored = await _preferences.read(key: _settingsKey);
    return AudioAnnouncementSettings.fromJsonString(stored);
  }

  Future<void> setSettings(AudioAnnouncementSettings settings) {
    return _preferences.write(
      key: _settingsKey,
      value: settings.toJsonString(),
    );
  }
}
