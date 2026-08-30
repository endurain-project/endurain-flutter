import 'package:endurain/core/services/app_preferences_store.dart';
import 'package:endurain/core/services/secure_storage_service.dart';
import 'package:endurain/core/utils/scoped_storage_key.dart';

/// User-facing settings for the health sync feature.
///
/// Auto-sync is a portable preference stored in [AppPreferencesStore]. The
/// connected marker represents device-local platform authorization and stays
/// in [SecureStorageService], whose Apple items do not migrate in backups.
class HealthSyncSettingsRepository {
  const HealthSyncSettingsRepository({
    required AppPreferencesStore preferences,
    required SecureStorageService storage,
  }) : _preferences = preferences,
       _storage = storage;

  static const String _keyAutoSyncOnResume = 'health_auto_sync_on_resume';
  static const String _keyConnected = 'health_connected';

  final AppPreferencesStore _preferences;
  final SecureStorageService _storage;

  /// Whether the user has completed the health authorization flow at least
  /// once.
  ///
  /// iOS HealthKit never reports read-permission status (`hasPermissions`
  /// returns `null` even after a grant, by Apple privacy design), so this flag
  /// is the only durable signal that the user has connected. It is set after a
  /// successful authorization request and used to skip the connect screen on
  /// subsequent launches.
  Future<bool> isConnected(String profileId) async {
    final value = await _storage.read(
      key: scopedStorageKey(_keyConnected, profileId),
    );
    return value == 'true';
  }

  Future<void> setConnected(String profileId, bool connected) {
    return _storage.write(
      key: scopedStorageKey(_keyConnected, profileId),
      value: connected ? 'true' : 'false',
    );
  }

  /// Whether new workouts should be imported automatically when the app
  /// returns to the foreground.
  ///
  /// Defaults to `false` — manual import is the default experience. The user
  /// opts in by granting platform health authorization and enabling this
  /// toggle on the health sync screen.
  Future<bool> isAutoSyncOnResumeEnabled(String profileId) async {
    final value = await _preferences.read(key: _autoSyncKey(profileId));
    return value == 'true';
  }

  Future<void> setAutoSyncOnResumeEnabled(String profileId, bool enabled) {
    return _preferences.write(
      key: _autoSyncKey(profileId),
      value: enabled ? 'true' : 'false',
    );
  }

  Future<void> clearForProfile(String profileId) {
    return Future.wait([
      _preferences.delete(key: _autoSyncKey(profileId)),
      _storage.delete(key: scopedStorageKey(_keyConnected, profileId)),
    ]);
  }

  String _autoSyncKey(String profileId) {
    return scopedStorageKey(_keyAutoSyncOnResume, profileId);
  }
}
