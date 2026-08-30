import 'package:endurain/core/services/app_preferences_store.dart';

/// Whether an activity's GPX file is kept on the device after a successful
/// upload.
///
/// A feature toggle rather than a credential, so it is persisted in
/// [AppPreferencesStore] rather than the platform keychain.
class ActivityRetentionSettingsRepository {
  const ActivityRetentionSettingsRepository({required this._preferences});

  static const String retainUploadedGpxKey = 'activity_retain_uploaded_gpx';

  final AppPreferencesStore _preferences;

  Future<bool> isRetainUploadedGpxEnabled() async {
    final value = await _preferences.read(key: retainUploadedGpxKey);
    return value == null || value == 'true';
  }

  Future<void> setRetainUploadedGpxEnabled(bool enabled) {
    return _preferences.write(
      key: retainUploadedGpxKey,
      value: enabled ? 'true' : 'false',
    );
  }
}
