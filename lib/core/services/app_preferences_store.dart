import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// A simple file-backed key/value store for non-secret application preferences.
///
/// Values are persisted as a JSON object in app-private support storage:
/// ```
/// <app-support>/preferences.json
/// ```
///
/// Unlike [SecureStorageService], this store does not use the platform keychain
/// and is suitable for display settings (map tile URL, attribution, color) that
/// do not require hardware-backed encryption. Secret credentials (tokens,
/// passwords) must remain in [SecureStorageService].
class AppPreferencesStore {
  AppPreferencesStore({Future<Directory> Function()? supportDirectoryProvider})
    : _supportDirectoryProvider =
          supportDirectoryProvider ?? getApplicationSupportDirectory;

  static const String _fileName = 'preferences.json';

  final Future<Directory> Function() _supportDirectoryProvider;

  /// Returns the stored value for [key], or `null` when absent.
  Future<String?> read({required String key}) async {
    final map = await _load();
    return map[key];
  }

  /// Persists [value] for [key], creating the file if necessary.
  Future<void> write({required String key, required String value}) async {
    final map = await _load();
    map[key] = value;
    await _save(map);
  }

  /// Removes [key] from the store. Silently succeeds when absent.
  Future<void> delete({required String key}) async {
    final map = await _load();
    if (map.remove(key) != null) {
      await _save(map);
    }
  }

  // ---------------------------------------------------------------------------

  Future<File> _file() async {
    final dir = await _supportDirectoryProvider();
    return File('${dir.path}${Platform.pathSeparator}$_fileName');
  }

  Future<Map<String, String>> _load() async {
    final file = await _file();
    if (!file.existsSync()) {
      return {};
    }
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is Map) {
        return Map<String, String>.fromEntries(
          decoded.entries
              .where((e) => e.key is String && e.value is String)
              .map((e) => MapEntry(e.key as String, e.value as String)),
        );
      }
    } catch (_) {
      // Corrupted file: treat as empty rather than crashing.
    }
    return {};
  }

  Future<void> _save(Map<String, String> map) async {
    final file = await _file();
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(map),
      flush: true,
    );
  }
}
