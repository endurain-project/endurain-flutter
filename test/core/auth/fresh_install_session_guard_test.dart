import 'package:endurain/core/auth/fresh_install_session_guard.dart';
import 'package:endurain/core/auth/secure_storage_service.dart';
import 'package:endurain/core/services/app_preferences_store.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryBackend implements AppPreferencesBackend {
  _MemoryBackend([Map<String, String>? initial]) : values = {...?initial};

  final Map<String, String> values;

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

void main() {
  const migrationKey = 'endurain.preferences_json_migration_complete';
  const markerKey = 'endurain.install_marker';

  late AppPreferencesStore preferences;
  late _MemoryBackend backend;
  late SecureStorageService secureStorage;

  Future<void> setUpStores(Map<String, String> prefs) async {
    FlutterSecureStorage.setMockInitialValues({'auth_session_v2': 'session'});
    backend = _MemoryBackend(prefs);
    preferences = AppPreferencesStore(backend: backend);
    secureStorage = SecureStorageService(preferences: preferences);
  }

  FreshInstallSessionGuard guard(TargetPlatform platform) {
    return FreshInstallSessionGuard(
      preferences: preferences,
      secureStorage: secureStorage,
      platform: platform,
    );
  }

  test('wipes secure storage on a fresh iOS install and marks it', () async {
    await setUpStores({});

    expect(await guard(TargetPlatform.iOS).run(), isTrue);

    expect(await secureStorage.getAuthSession(), isNull);
    expect(backend.values[markerKey], 'true');
  });

  test('keeps the session of an upgrading iOS install', () async {
    await setUpStores({migrationKey: 'true'});

    expect(await guard(TargetPlatform.iOS).run(), isFalse);

    expect(await secureStorage.getAuthSession(), 'session');
    expect(backend.values[markerKey], 'true');
  });

  test('does not wipe again once the marker exists', () async {
    await setUpStores({});
    await guard(TargetPlatform.iOS).run();
    await secureStorage.setAuthSession('new-session');
    // The first preference access after the wipe records the legacy flag too.
    await preferences.read(key: 'anything');

    expect(await guard(TargetPlatform.iOS).run(), isFalse);

    expect(await secureStorage.getAuthSession(), 'new-session');
  });

  test('does nothing on other platforms', () async {
    await setUpStores({});

    expect(await guard(TargetPlatform.android).run(), isFalse);

    expect(await secureStorage.getAuthSession(), 'session');
    expect(backend.values.containsKey(markerKey), isFalse);
  });
}
