import 'package:endurain/core/auth/secure_storage_service.dart';
import 'package:endurain/core/diagnostics/diagnostics_service.dart';
import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/services/app_preferences_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake [FlutterSecureStorage] whose [read] always throws.
class _ThrowingStorage extends Fake implements FlutterSecureStorage {
  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    throw Exception('keychain unavailable');
  }
}

/// Fake [FlutterSecureStorage] whose [write] always throws.
class _ThrowingWriteStorage extends Fake implements FlutterSecureStorage {
  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => null;

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    throw Exception('keychain write failed');
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    throw Exception('keychain delete failed');
  }
}

/// Fake [FlutterSecureStorage] that fails the first [write] (simulating a stale
/// keychain item with mismatched accessibility) but succeeds on the retry after
/// the key is deleted.
class _StaleItemStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String?> values = {};
  int writeAttempts = 0;
  int deleteCalls = 0;

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    writeAttempts++;
    if (writeAttempts == 1) {
      throw Exception('errSecDuplicateItem');
    }
    values[key] = value;
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    deleteCalls++;
    values.remove(key);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  group('SecureStorageService', () {
    test('clears only auth tokens', () async {
      final storage = SecureStorageService();
      await storage.setServerUrl('https://example.test');
      await storage.setAccessToken('access-1');
      await storage.setRefreshToken('refresh-1');
      await storage.setSessionId('session-1');
      await storage.setAccessTokenExpiresAt(DateTime.now().toUtc());

      await storage.clearAuthTokens();

      expect(await storage.getServerUrl(), 'https://example.test');
      expect(await storage.getAccessToken(), isNull);
      expect(await storage.getRefreshToken(), isNull);
      expect(await storage.getSessionId(), isNull);
      expect(await storage.getAccessTokenExpiresAt(), isNull);
    });

    test('returns null expiry for an unparsable stored value', () async {
      final storage = SecureStorageService();
      await storage.write(key: 'access_token_expires_at', value: 'not-a-date');

      expect(await storage.getAccessTokenExpiresAt(), isNull);
    });

    test('round-trips server and username preferences', () async {
      final storage = SecureStorageService();

      await storage.setServerUrl('https://example.test');
      await storage.setUsername('joao');

      expect(await storage.getServerUrl(), 'https://example.test');
      expect(await storage.getUsername(), 'joao');
    });

    test('read returns null for a missing key', () async {
      final storage = SecureStorageService();

      expect(await storage.read(key: 'nonexistent_key'), isNull);
    });

    test('read throws secureStorageReadFailed on platform exception', () async {
      final storage = SecureStorageService(storage: _ThrowingStorage());

      expect(
        () => storage.read(key: 'any_key'),
        throwsA(
          isA<AppException>().having(
            (e) => e.code,
            'code',
            AppErrorCode.secureStorageReadFailed,
          ),
        ),
      );
    });

    test(
      'getAccessToken throws secureStorageReadFailed on platform exception',
      () async {
        final storage = SecureStorageService(storage: _ThrowingStorage());

        expect(
          storage.getAccessToken,
          throwsA(
            isA<AppException>().having(
              (e) => e.code,
              'code',
              AppErrorCode.secureStorageReadFailed,
            ),
          ),
        );
      },
    );

    test(
      'getServerUrl throws secureStorageReadFailed on platform exception',
      () async {
        final storage = SecureStorageService(storage: _ThrowingStorage());

        expect(
          storage.getServerUrl,
          throwsA(
            isA<AppException>().having(
              (e) => e.code,
              'code',
              AppErrorCode.secureStorageReadFailed,
            ),
          ),
        );
      },
    );

    test('write throws secureStorageWriteFailed on platform exception', () {
      final storage = SecureStorageService(storage: _ThrowingWriteStorage());

      expect(
        () => storage.write(key: 'k', value: 'v'),
        throwsA(
          isA<AppException>().having(
            (e) => e.code,
            'code',
            AppErrorCode.secureStorageWriteFailed,
          ),
        ),
      );
    });

    test('write self-heals by deleting a stale item and retrying', () async {
      final fake = _StaleItemStorage();
      final storage = SecureStorageService(storage: fake);

      await storage.write(key: 'k', value: 'v');

      expect(fake.deleteCalls, 1);
      expect(fake.writeAttempts, 2);
      expect(fake.values['k'], 'v');
    });

    group('server URL mirror', () {
      test('falls back to the mirror when secure storage throws', () async {
        final backend = _MemoryBackend();
        final preferences = AppPreferencesStore(backend: backend);
        await preferences.write(
          key: 'server_url',
          value: 'https://mirror.test',
        );
        final storage = SecureStorageService(
          storage: _ThrowingStorage(),
          preferences: preferences,
        );

        expect(await storage.getServerUrl(), 'https://mirror.test');
      });

      test(
        'records a breadcrumb when the fallback hides a read failure',
        () async {
          final preferences = AppPreferencesStore(backend: _MemoryBackend());
          await preferences.write(
            key: 'server_url',
            value: 'https://mirror.test',
          );
          final diagnostics = _RecordingDiagnostics();
          final storage = SecureStorageService(
            storage: _ThrowingStorage(),
            preferences: preferences,
            diagnostics: diagnostics,
          );

          await storage.getServerUrl();

          expect(diagnostics.events, [
            DiagnosticsEvents.secureStorageServerUrlFallback,
          ]);
          expect(diagnostics.details.single, {'errorType': 'AppException'});
        },
      );

      test('falls back to the mirror when the secure value is gone', () async {
        FlutterSecureStorage.setMockInitialValues(<String, String>{});
        final preferences = AppPreferencesStore(backend: _MemoryBackend());
        await preferences.write(
          key: 'server_url',
          value: 'https://mirror.test',
        );
        final storage = SecureStorageService(preferences: preferences);

        expect(await storage.getServerUrl(), 'https://mirror.test');
      });

      test('prefers the secure value over the mirror', () async {
        FlutterSecureStorage.setMockInitialValues(<String, String>{
          'server_url': 'https://secure.test',
        });
        final preferences = AppPreferencesStore(backend: _MemoryBackend());
        await preferences.write(
          key: 'server_url',
          value: 'https://mirror.test',
        );
        final storage = SecureStorageService(preferences: preferences);

        expect(await storage.getServerUrl(), 'https://secure.test');
      });

      test('rethrows the read failure when the mirror is empty', () {
        final storage = SecureStorageService(
          storage: _ThrowingStorage(),
          preferences: AppPreferencesStore(backend: _MemoryBackend()),
        );

        expect(
          storage.getServerUrl,
          throwsA(
            isA<AppException>().having(
              (e) => e.code,
              'code',
              AppErrorCode.secureStorageReadFailed,
            ),
          ),
        );
      });

      test('setServerUrl writes both stores', () async {
        FlutterSecureStorage.setMockInitialValues(<String, String>{});
        final backend = _MemoryBackend();
        final storage = SecureStorageService(
          preferences: AppPreferencesStore(backend: backend),
        );

        await storage.setServerUrl('https://example.test');

        expect(await storage.read(key: 'server_url'), 'https://example.test');
        expect(await backend.read('server_url'), 'https://example.test');
      });

      test('setServerUrl succeeds when the mirror write fails', () async {
        FlutterSecureStorage.setMockInitialValues(<String, String>{});
        final storage = SecureStorageService(
          preferences: AppPreferencesStore(backend: _FailingBackend()),
        );

        await storage.setServerUrl('https://example.test');

        expect(await storage.read(key: 'server_url'), 'https://example.test');
      });

      test('clearAuthTokens keeps the mirrored server URL', () async {
        FlutterSecureStorage.setMockInitialValues(<String, String>{});
        final backend = _MemoryBackend();
        final storage = SecureStorageService(
          preferences: AppPreferencesStore(backend: backend),
        );
        await storage.setServerUrl('https://example.test');

        await storage.clearAuthTokens();

        expect(await storage.getServerUrl(), 'https://example.test');
      });
    });

    test('resetAll removes every secure value', () async {
      FlutterSecureStorage.setMockInitialValues(<String, String>{
        'a': '1',
        'b': '2',
      });
      final storage = SecureStorageService(
        preferences: AppPreferencesStore(backend: _MemoryBackend()),
      );

      await storage.resetAll();

      expect(await storage.read(key: 'a'), isNull);
      expect(await storage.read(key: 'b'), isNull);
    });

    test('delete throws secureStorageDeleteFailed on platform exception', () {
      final storage = SecureStorageService(storage: _ThrowingWriteStorage());

      expect(
        () => storage.delete(key: 'k'),
        throwsA(
          isA<AppException>().having(
            (e) => e.code,
            'code',
            AppErrorCode.secureStorageDeleteFailed,
          ),
        ),
      );
    });
  });
}

class _MemoryBackend implements AppPreferencesBackend {
  final Map<String, String> _values = {};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async => _values[key] = value;

  @override
  Future<void> delete(String key) async => _values.remove(key);
}

class _FailingBackend implements AppPreferencesBackend {
  @override
  Future<String?> read(String key) async => throw StateError('unavailable');

  @override
  Future<void> write(String key, String value) async =>
      throw StateError('unavailable');

  @override
  Future<void> delete(String key) async => throw StateError('unavailable');
}

class _RecordingDiagnostics implements DiagnosticsRecorder {
  final events = <String>[];
  final details = <Map<String, Object?>>[];

  @override
  void recordBreadcrumbSync(
    String event, {
    Map<String, Object?> details = const {},
  }) {
    events.add(event);
    this.details.add(details);
  }

  @override
  void recordErrorSync(
    Object error,
    StackTrace stackTrace, {
    String source = DiagnosticsSources.uncaught,
  }) {}
}
