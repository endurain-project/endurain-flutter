import 'dart:io';

import 'package:endurain/core/services/app_preferences_store.dart';

/// An in-memory [AppPreferencesStore] for use in widget tests.
///
/// Overrides all I/O methods to use a plain [Map], avoiding real file
/// operations that do not complete under `testWidgets`'s controlled event
/// loop.
class FakePreferencesStore extends AppPreferencesStore {
  FakePreferencesStore()
    : super(supportDirectoryProvider: _unsupported);

  static Future<Directory> _unsupported() {
    throw UnsupportedError(
      'FakePreferencesStore does not use the file system',
    );
  }

  final Map<String, String> _map = {};

  @override
  Future<String?> read({required String key}) async => _map[key];

  @override
  Future<void> write({required String key, required String value}) async {
    _map[key] = value;
  }

  @override
  Future<void> delete({required String key}) async {
    _map.remove(key);
  }
}
