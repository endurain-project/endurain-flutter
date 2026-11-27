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

  /// Written once per install. Preferences are cleared when an iOS app is
  /// uninstalled but keychain items are not, so a missing marker next to a
  /// fresh preference store is how a reinstall is told apart from an upgrade.
  static const String _installMarkerKey = 'endurain.install_marker';

  final AppPreferencesBackend _backend;
  final Future<Directory> Function() _supportDirectoryProvider;

  /// The legacy import, shared by concurrent callers. A failed import is
  /// dropped so the next call retries it instead of every call failing until
  /// the app restarts.
  Future<void>? _migration;

  Future<void> _ensureMigrated() {
    return _migration ??= _migrateLegacyPreferences().catchError((
      Object error,
      StackTrace stackTrace,
    ) {
      _migration = null;
      Error.throwWithStackTrace(error, stackTrace);
    });
  }

  /// Returns the stored value for [key], or `null` when absent.
  Future<String?> read({required String key}) async {
    await _ensureMigrated();
    return _backend.read(key);
  }

  /// Persists [value] for [key].
  Future<void> write({required String key, required String value}) async {
    await _ensureMigrated();
    await _backend.write(key, value);
  }

  /// Reads a boolean written by [writeBool]: `true` only for the stored text
  /// `true`, [defaultValue] when nothing is stored.
  Future<bool> readBool({
    required String key,
    bool defaultValue = false,
  }) async {
    final stored = await read(key: key);
    return stored == null ? defaultValue : stored == 'true';
  }

  /// Persists [value] as `true` / `false` text.
  Future<void> writeBool({required String key, required bool value}) {
    return write(key: key, value: value ? 'true' : 'false');
  }

  /// Reads an integer clamped to [min]..[max]; [defaultValue] when nothing
  /// valid is stored (absent or malformed).
  Future<int> readClampedInt({
    required String key,
    required int defaultValue,
    required int min,
    required int max,
  }) async {
    final stored = int.tryParse(await read(key: key) ?? '');
    return stored == null ? defaultValue : stored.clamp(min, max);
  }

  /// Persists [value], or removes [key] when [value] is `null`.
  Future<void> writeOrDelete({required String key, String? value}) {
    return value == null ? delete(key: key) : write(key: key, value: value);
  }

  /// Whether this launch is the first of a new install rather than an
  /// upgrade, judged before anything else touches the store.
  ///
  /// `false` when the install marker exists. Without it, an existing install
  /// still shows other state: every version since 0.3 records the legacy
  /// import flag on its first preference access, and older ones left the
  /// legacy JSON file behind. Only a store with none of these is fresh.
  /// Does not write anything; call [markInstalled] once the decision has been
  /// acted on.
  Future<bool> isFreshInstall() async {
    if (await _backend.read(_installMarkerKey) != null) {
      return false;
    }
    if (await _backend.read(_migrationKey) != null) {
      return false;
    }
    return (await _loadLegacyValues()).isEmpty;
  }

  /// Records that this install has been seen, so later launches never treat
  /// it as fresh.
  Future<void> markInstalled() async {
    await _backend.write(_installMarkerKey, 'true');
  }

  /// Removes [key] from the store. Silently succeeds when absent.
  Future<void> delete({required String key}) async {
    await _ensureMigrated();
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
    : _injected = preferences;

  final SharedPreferencesAsync? _injected;

  /// Resolved on first use rather than at construction.
  ///
  /// `SharedPreferencesAsync()` asserts that the platform implementation is
  /// registered, so building it eagerly makes merely *constructing* the
  /// composition root depend on plugin registration. Deferring it keeps
  /// unrelated widgets (which only read an in-memory preference value) working
  /// in tests and previews that never touch preference storage.
  late final SharedPreferencesAsync _preferences =
      _injected ?? SharedPreferencesAsync();

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
