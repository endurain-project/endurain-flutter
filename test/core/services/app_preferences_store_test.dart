import 'dart:convert';
import 'dart:io';

import 'package:endurain/core/services/app_preferences_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late _InMemoryPreferencesBackend backend;
  late AppPreferencesStore store;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('app_preferences_test_');
    backend = _InMemoryPreferencesBackend();
    store = AppPreferencesStore(
      backend: backend,
      supportDirectoryProvider: () async => tempDir,
    );
  });

  tearDown(() => tempDir.delete(recursive: true));

  test('reads, writes, and deletes non-secret string preferences', () async {
    await store.write(key: 'theme', value: 'dark');

    expect(await store.read(key: 'theme'), 'dark');

    await store.delete(key: 'theme');

    expect(await store.read(key: 'theme'), isNull);
  });

  test(
    'imports legacy JSON preferences once without overwriting new values',
    () async {
      await File(
        '${tempDir.path}${Platform.pathSeparator}preferences.json',
      ).writeAsString(
        jsonEncode(<String, String>{
          'app_locale': 'pt-BR',
          'tile_server_url': 'https://tiles.example.test/{z}/{x}/{y}.png',
        }),
      );
      await backend.write('app_locale', 'en');

      expect(await store.read(key: 'app_locale'), 'en');
      expect(
        await store.read(key: 'tile_server_url'),
        'https://tiles.example.test/{z}/{x}/{y}.png',
      );

      await backend.write('tile_server_url', 'native-value');
      await File(
        '${tempDir.path}${Platform.pathSeparator}preferences.json',
      ).writeAsString(
        jsonEncode(<String, String>{'tile_server_url': 'legacy'}),
      );
      final subsequentStore = AppPreferencesStore(
        backend: backend,
        supportDirectoryProvider: () async => tempDir,
      );

      expect(
        await subsequentStore.read(key: 'tile_server_url'),
        'native-value',
      );
    },
  );
}

class _InMemoryPreferencesBackend implements AppPreferencesBackend {
  final Map<String, String> _values = {};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
  }
}
