import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A simple file-backed key/value store for non-secret application preferences.
///
/// Values are persisted with the platform preference store. Existing values from
/// the pre-0.3 JSON file are imported once on first access.
///
/// Unlike `SecureStorageService`, this store does not use the platform keychain
/// and is suitable for display settings (map tile URL, attribution, color) that
/// do not require hardware-backed encryption. Secret credentials (tokens,
/// passwords) must remain in `SecureStorageService`.
class AppPreferencesStore {
  AppPreferencesStore({
    AppPreferencesBackend? backend,
    Future<Directory> Function()? supportDirectoryProvider,
  }) : _backend = backend ?? SharedPreferencesAsyncBackend(),
       _supportDirectoryProvider =
           supportDirectoryProvider ?? getApplicationSupportDirectory;

  static const String _fileName = 'preferences.json';
  static const String _migrationKey =
      'endurain.preferences_json_migration_complete';

  final AppPreferencesBackend _backend;
  final Future<Directory> Function() _supportDirectoryProvider;
  late final Future<void> _migration = _migrateLegacyPreferences();

  /// Returns the stored value for [key], or `null` when absent.
  Future<String?> read({required String key}) async {
    await _migration;
    return _backend.read(key);
  }

  /// Persists [value] for [key].
  Future<void> write({required String key, required String value}) async {
    await _migration;
    await _backend.write(key, value);
  }

  /// Removes [key] from the store. Silently succeeds when absent.
  Future<void> delete({required String key}) async {
    await _migration;
    await _backend.delete(key);
  }

  Future<void> _migrateLegacyPreferences() async {
    if (await _backend.read(_migrationKey) != null) {
      return;
    }

    final legacyValues = await _loadLegacyValues();
    for (final entry in legacyValues.entries) {
      if (await _backend.read(entry.key) == null) {
        await _backend.write(entry.key, entry.value);
      }
    }
    await _backend.write(_migrationKey, 'true');
  }

  Future<File> _file() async {
    final dir = await _supportDirectoryProvider();
    return File('${dir.path}${Platform.pathSeparator}$_fileName');
  }

  Future<Map<String, String>> _loadLegacyValues() async {
    try {
      final file = await _file();
      if (!file.existsSync()) {
        return {};
      }
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is Map) {
        return Map<String, String>.fromEntries(
          decoded.entries
              .where((e) => e.key is String && e.value is String)
              .map((e) => MapEntry(e.key as String, e.value as String)),
        );
      }
    } catch (_) {
      // An unavailable or corrupted legacy file must not block startup.
    }
    return {};
  }
}

/// Boundary around non-secret platform preference storage.
abstract interface class AppPreferencesBackend {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}

/// [AppPreferencesBackend] backed by the official asynchronous plugin API.
final class SharedPreferencesAsyncBackend implements AppPreferencesBackend {
  SharedPreferencesAsyncBackend({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> read(String key) => _preferences.getString(key);

  @override
  Future<void> write(String key, String value) {
    return _preferences.setString(key, value);
  }

  @override
  Future<void> delete(String key) {
    return _preferences.remove(key);
  }
}
