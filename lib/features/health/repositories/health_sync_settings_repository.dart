import 'package:endurain/core/auth/secure_storage_service.dart';
import 'package:endurain/core/services/app_preferences_store.dart';
import 'package:endurain/core/utils/scoped_storage_key.dart';

/// User-facing settings and sync state for the health sync feature.
///
/// Auto-sync is a portable preference stored in [AppPreferencesStore]. The
/// connected marker (device-local platform authorization) and the workout
/// changes token (which only the health store of this device can read) stay
/// in [SecureStorageService], whose Apple items do not migrate in backups.
class HealthSyncSettingsRepository {
  const HealthSyncSettingsRepository({
    required AppPreferencesStore preferences,
    required SecureStorageService storage,
  }) : _preferences = preferences,
       _storage = storage;

  /// Named before auto-sync also ran in the background; kept so the setting
  /// users already chose still applies.
  static const String _keyAutoSync = 'health_auto_sync_on_resume';
  static const String _keyConnected = 'health_connected';
  static const String _keyWorkoutChangesToken = 'health_workout_changes_token';

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

  /// Whether new workouts are imported automatically: when the app returns to
  /// the foreground and, where the platform allows, in the background.
  ///
  /// Defaults to `false` — manual import is the default experience. The user
  /// opts in by granting platform health authorization and enabling this
  /// toggle on the health sync screen.
  Future<bool> isAutoSyncEnabled(String profileId) {
    return _preferences.readBool(key: _autoSyncKey(profileId));
  }

  Future<void> setAutoSyncEnabled(String profileId, bool enabled) {
    return _preferences.writeBool(key: _autoSyncKey(profileId), value: enabled);
  }

  /// The token the next automatic import reads workout changes from, or
  /// `null` before the first one.
  Future<String?> workoutChangesToken(String profileId) {
    return _storage.read(key: _changesTokenKey(profileId));
  }

  Future<void> setWorkoutChangesToken(String profileId, String token) {
    return _storage.write(key: _changesTokenKey(profileId), value: token);
  }

  Future<void> clearForProfile(String profileId) {
    return Future.wait([
      _preferences.delete(key: _autoSyncKey(profileId)),
      _storage.delete(key: scopedStorageKey(_keyConnected, profileId)),
      _storage.delete(key: _changesTokenKey(profileId)),
    ]);
  }

  /// Moves both settings of [fromProfileId] onto [toProfileId], used when an
  /// account changes its profile id (the integer-to-UUID switch of Endurain
  /// v0.21). A value [toProfileId] already has is kept.
  Future<void> moveProfile({
    required String fromProfileId,
    required String toProfileId,
  }) async {
    if (fromProfileId == toProfileId) {
      return;
    }
    final fromConnected = scopedStorageKey(_keyConnected, fromProfileId);
    final connected = await _storage.read(key: fromConnected);
    if (connected != null) {
      final toConnected = scopedStorageKey(_keyConnected, toProfileId);
      if (await _storage.read(key: toConnected) == null) {
        await _storage.write(key: toConnected, value: connected);
      }
      await _storage.delete(key: fromConnected);
    }

    final fromAutoSync = _autoSyncKey(fromProfileId);
    final autoSync = await _preferences.read(key: fromAutoSync);
    if (autoSync != null) {
      final toAutoSync = _autoSyncKey(toProfileId);
      if (await _preferences.read(key: toAutoSync) == null) {
        await _preferences.write(key: toAutoSync, value: autoSync);
      }
      await _preferences.delete(key: fromAutoSync);
    }
  }

  String _autoSyncKey(String profileId) {
    return scopedStorageKey(_keyAutoSync, profileId);
  }

  String _changesTokenKey(String profileId) {
    return scopedStorageKey(_keyWorkoutChangesToken, profileId);
  }
}
