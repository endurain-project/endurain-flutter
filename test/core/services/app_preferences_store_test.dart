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

  test('reads and writes booleans with a default', () async {
    expect(await store.readBool(key: 'flag'), isFalse);
    expect(await store.readBool(key: 'flag', defaultValue: true), isTrue);

    await store.writeBool(key: 'flag', value: false);
    expect(await store.readBool(key: 'flag', defaultValue: true), isFalse);

    await store.writeBool(key: 'flag', value: true);
    expect(await store.readBool(key: 'flag'), isTrue);
  });

  test('reads integers clamped, with a default for bad values', () async {
    Future<int> read() =>
        store.readClampedInt(key: 'n', defaultValue: 7, min: 5, max: 60);

    expect(await read(), 7);
    await store.write(key: 'n', value: 'abc');
    expect(await read(), 7);
    await store.write(key: 'n', value: '1');
    expect(await read(), 5);
    await store.write(key: 'n', value: '999');
    expect(await read(), 60);
    await store.write(key: 'n', value: '30');
    expect(await read(), 30);
  });

  test('writeOrDelete removes the key for null', () async {
    await store.writeOrDelete(key: 'k', value: 'v');
    expect(await store.read(key: 'k'), 'v');

    await store.writeOrDelete(key: 'k');
    expect(await store.read(key: 'k'), isNull);
  });

  test('tells a fresh install from an upgrade and from a marked one', () async {
    expect(await store.isFreshInstall(), isTrue);

    await store.markInstalled();
    expect(await store.isFreshInstall(), isFalse);

    // An upgrading install has the legacy-import flag but no marker yet.
    final upgraded = AppPreferencesStore(
      backend: _InMemoryPreferencesBackend()
        .._values['endurain.preferences_json_migration_complete'] = 'true',
      supportDirectoryProvider: () async => tempDir,
    );
    expect(await upgraded.isFreshInstall(), isFalse);

    // An install that predates the import flag still has the legacy file.
    await File('${tempDir.path}${Platform.pathSeparator}preferences.json')
        .writeAsString(jsonEncode(<String, String>{'app_locale': 'en'}));
    final legacy = AppPreferencesStore(
      backend: _InMemoryPreferencesBackend(),
      supportDirectoryProvider: () async => tempDir,
    );
    expect(await legacy.isFreshInstall(), isFalse);
  });

  test(
    'imports legacy JSON preferences once without overwriting new values',
    () async {
      await File('${tempDir.path}${Platform.pathSeparator}preferences.json')
          .writeAsString(
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
      await File('${tempDir.path}${Platform.pathSeparator}preferences.json')
          .writeAsString(
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

  test('retries the legacy import after a failed attempt', () async {
    final flaky = _InMemoryPreferencesBackend()..failReads = 1;
    final retryingStore = AppPreferencesStore(
      backend: flaky,
      supportDirectoryProvider: () async => tempDir,
    );

    await expectLater(
      retryingStore.read(key: 'theme'),
      throwsA(isA<StateError>()),
    );

    await retryingStore.write(key: 'theme', value: 'dark');
    expect(await retryingStore.read(key: 'theme'), 'dark');
  });
}

class _InMemoryPreferencesBackend implements AppPreferencesBackend {
  final Map<String, String> _values = {};

  /// How many upcoming reads throw, to simulate a platform failure.
  int failReads = 0;

  @override
  Future<String?> read(String key) async {
    if (failReads > 0) {
      failReads--;
      throw StateError('preferences unavailable');
    }
    return _values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
  }
}
