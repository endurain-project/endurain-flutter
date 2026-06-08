import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/services/secure_storage_service.dart';
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

  @override
  Future<void> deleteAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    throw Exception('keychain deleteAll failed');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  group('SecureStorageService', () {
    test('detects tokens expiring inside the threshold', () async {
      final storage = SecureStorageService();
      await storage.setAccessTokenExpiresAt(
        DateTime.now().toUtc().add(const Duration(seconds: 30)),
      );

      expect(await storage.isAccessTokenExpiringSoon(), isTrue);
    });

    test('does not treat later token expiry as expiring soon', () async {
      final storage = SecureStorageService();
      await storage.setAccessTokenExpiresAt(
        DateTime.now().toUtc().add(const Duration(hours: 1)),
      );

      expect(await storage.isAccessTokenExpiringSoon(), isFalse);
    });

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

    test('treats a missing expiry as not expiring soon', () async {
      final storage = SecureStorageService();

      expect(await storage.isAccessTokenExpiringSoon(), isFalse);
    });

    test('reports authentication based on a stored access token', () async {
      final storage = SecureStorageService();

      expect(await storage.isAuthenticated(), isFalse);

      await storage.setAccessToken('access-1');
      expect(await storage.isAuthenticated(), isTrue);
    });

    test('round-trips server and username preferences', () async {
      final storage = SecureStorageService();

      await storage.setServerUrl('https://example.test');
      await storage.setUsername('joao');

      expect(await storage.getServerUrl(), 'https://example.test');
      expect(await storage.getUsername(), 'joao');

      await storage.deleteServerUrl();
      await storage.deleteUsername();

      expect(await storage.getServerUrl(), isNull);
      expect(await storage.getUsername(), isNull);
    });

    test('deleteAll removes every stored value', () async {
      final storage = SecureStorageService();
      await storage.setServerUrl('https://example.test');
      await storage.setAccessToken('access-1');

      await storage.deleteAll();

      expect(await storage.getServerUrl(), isNull);
      expect(await storage.getAccessToken(), isNull);
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
          () => storage.getAccessToken(),
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
          () => storage.getServerUrl(),
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

    test(
      'deleteAll throws secureStorageDeleteFailed on platform exception',
      () {
        final storage = SecureStorageService(storage: _ThrowingWriteStorage());

        expect(
          () => storage.deleteAll(),
          throwsA(
            isA<AppException>().having(
              (e) => e.code,
              'code',
              AppErrorCode.secureStorageDeleteFailed,
            ),
          ),
        );
      },
    );
  });
}
