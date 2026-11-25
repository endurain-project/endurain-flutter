import 'package:endurain/core/auth/auth_session_store.dart';
import 'package:endurain/core/auth/secure_storage_service.dart';
import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/models/auth_session.dart';
import 'package:endurain/core/services/app_preferences_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  group('AuthSessionStore', () {
    test('persists session values and expiry', () async {
      final storage = SecureStorageService();
      final store = AuthSessionStore(storage: storage);

      await store.saveSession(
        origin: 'https://example.test',
        accessToken: 'access-1',
        refreshToken: 'refresh-1',
        sessionId: 'session-1',
        accountId: '42',
        username: 'joao',
        expiresInSeconds: 3600,
      );

      expect(await storage.getAccessToken(), isNull);
      expect(await storage.getRefreshToken(), isNull);
      expect(await storage.getSessionId(), isNull);
      expect(await storage.getUsername(), 'joao');
      expect(await storage.getAccessTokenExpiresAt(), isNull);
      expect(await storage.getAuthSession(), isNotNull);
      final session = await store.readSession();
      expect(session?.origin, 'https://example.test');
      expect(session?.accessToken, 'access-1');
      expect(session?.accountId, '42');
      expect(session?.profileId, 'https://example.test#42');
    });

    test('normalizes the committed origin', () async {
      final store = AuthSessionStore(storage: SecureStorageService());

      await store.saveSession(
        origin: 'https://EXAMPLE.test/',
        accessToken: 'access-1',
        refreshToken: 'refresh-1',
        sessionId: 'session-1',
        accountId: '42',
        expiresInSeconds: 3600,
      );

      final session = await store.readSession();
      expect(session?.origin, 'https://example.test');
      expect(session?.profileId, 'https://example.test#42');
    });

    test('stale session cannot replace or clear a newer login', () async {
      final store = AuthSessionStore(storage: SecureStorageService());
      await store.saveSession(
        origin: 'https://a.example',
        accessToken: 'access-a',
        refreshToken: 'refresh-a',
        sessionId: 'session-a',
        accountId: '42',
        expiresInSeconds: 3600,
      );
      final stale = (await store.readSession())!;

      await store.saveSession(
        origin: 'https://b.example',
        accessToken: 'access-b',
        refreshToken: 'refresh-b',
        sessionId: 'session-b',
        accountId: '43',
        expiresInSeconds: 3600,
      );

      expect(
        (await store.replaceSessionIfCurrent(
          expected: stale,
          accessToken: 'late-access-a',
          refreshToken: 'late-refresh-a',
          sessionId: 'late-session-a',
          expiresInSeconds: 3600,
        )).replaced,
        isFalse,
      );
      expect(await store.clearIfCurrent(stale), isFalse);
      final current = await store.readSession();
      expect(current?.origin, 'https://b.example');
      expect(current?.accessToken, 'access-b');
    });

    test('clears auth tokens without removing server settings', () async {
      final storage = SecureStorageService();
      final store = AuthSessionStore(storage: storage);
      await storage.setServerUrl('https://example.test');
      await store.saveSession(
        origin: 'https://example.test',
        accessToken: 'access-1',
        refreshToken: 'refresh-1',
        sessionId: 'session-1',
        accountId: '42',
        expiresInSeconds: 3600,
      );

      await store.clear();

      expect(await storage.getServerUrl(), 'https://example.test');
      expect(await storage.getAccessToken(), isNull);
      expect(await storage.getRefreshToken(), isNull);
      expect(await storage.getSessionId(), isNull);
      expect(await storage.getAccessTokenExpiresAt(), isNull);
    });

    test('saveSession resets an unusable store and signs in', () async {
      final fake = _BrokenStorage();
      final store = AuthSessionStore(
        storage: SecureStorageService(
          storage: fake,
          preferences: AppPreferencesStore(backend: _NoopBackend()),
        ),
      );

      await store.saveSession(
        origin: 'https://example.test',
        accessToken: 'access-1',
        refreshToken: 'refresh-1',
        sessionId: 'session-1',
        accountId: '42',
        expiresInSeconds: 3600,
      );

      expect(fake.deleteAllCalls, 1);
      expect((await store.readSession())?.accessToken, 'access-1');
    });

    test('saveSession retries a transient write failure in place', () async {
      final fake = _ConfigurableStorage()
        ..values['device_id:https://example.test'] = 'device-1'
        ..failNextWrites = 1;
      final store = _storeOver(fake);

      await _save(store);

      expect(fake.deleteAllCalls, 0);
      expect(fake.values['device_id:https://example.test'], 'device-1');
      expect((await store.readSession())?.accessToken, 'access-1');
    });

    test('saveSession clears only the auth keys for a damaged entry', () async {
      final fake = _ConfigurableStorage()
        ..values['device_id:https://example.test'] = 'device-1'
        ..values['auth_session_v2'] = 'damaged'
        ..damagedKeys.add('auth_session_v2');
      final store = _storeOver(fake);

      await _save(store);

      expect(fake.deleteAllCalls, 0);
      expect(fake.values['device_id:https://example.test'], 'device-1');
      expect((await store.readSession())?.accessToken, 'access-1');
    });

    test(
      'a failed legacy cleanup or username write keeps the session',
      () async {
        final fake = _ConfigurableStorage()
          ..failingDeletes.add('access_token')
          ..damagedKeys.add('username');
        final store = _storeOver(fake);

        await _save(store, username: 'joao');
        final saved = (await store.readSession())!;
        final replaced = await store.replaceSessionIfCurrent(
          expected: saved,
          accessToken: 'access-2',
          refreshToken: 'refresh-2',
          sessionId: 'session-2',
          expiresInSeconds: 3600,
        );

        expect(replaced.replaced, isTrue);
        expect(replaced.persistError, isNull);
        expect(fake.deleteAllCalls, 0);
        expect((await store.readSession())?.accessToken, 'access-2');
      },
    );

    group('a refresh secure storage rejects', () {
      test('stays the current session in memory', () async {
        final fake = _ConfigurableStorage();
        final store = _storeOver(fake);
        await _save(store);
        final saved = (await store.readSession())!;
        fake.damagedKeys.add('auth_session_v2');

        final replacement = await _replace(store, saved);

        expect(replacement.replaced, isTrue);
        expect(
          replacement.persistError,
          isA<AppException>().having(
            (e) => e.code,
            'code',
            AppErrorCode.secureStorageWriteFailed,
          ),
        );
        final current = (await store.readSession())!;
        expect(current.accessToken, 'access-2');
        expect(current.refreshToken, 'refresh-2');
        expect(current.revision, isNot(saved.revision));
        // Still only in memory: the stored blob is the old session.
        expect(fake.values['auth_session_v2'], contains('access-1'));
        expect((await _storeOver(fake).readSession())?.accessToken, 'access-1');
      });

      test('is stored by the next read once writes work again', () async {
        final fake = _ConfigurableStorage();
        final store = _storeOver(fake);
        await _save(store);
        fake.damagedKeys.add('auth_session_v2');
        await _replace(store, (await store.readSession())!);
        final pending = (await store.readSession())!;

        fake.damagedKeys.remove('auth_session_v2');
        expect((await store.readSession())?.revision, pending.revision);

        final stored = (await _storeOver(fake).readSession())!;
        expect(stored.accessToken, 'access-2');
        expect(stored.revision, pending.revision);
        // No longer held in memory: the store reads what is on disk again.
        fake.values.remove('auth_session_v2');
        expect(await store.readSession(), isNull);
      });

      test('can be refreshed again while still pending', () async {
        final fake = _ConfigurableStorage();
        final store = _storeOver(fake);
        await _save(store);
        fake.damagedKeys.add('auth_session_v2');
        await _replace(store, (await store.readSession())!);
        final pending = (await store.readSession())!;
        fake.damagedKeys.remove('auth_session_v2');

        final replacement = await _replace(
          store,
          pending,
          accessToken: 'access-3',
        );

        expect(replacement.replaced, isTrue);
        expect(replacement.persistError, isNull);
        expect((await _storeOver(fake).readSession())?.accessToken, 'access-3');
      });

      test('cannot be replaced or cleared by a stale revision', () async {
        final fake = _ConfigurableStorage();
        final store = _storeOver(fake);
        await _save(store);
        final stale = (await store.readSession())!;
        fake.damagedKeys.add('auth_session_v2');
        await _replace(store, stale);

        final late = await _replace(store, stale, accessToken: 'late-access');

        expect(late.replaced, isFalse);
        expect(await store.clearIfCurrent(stale), isFalse);
        expect((await store.readSession())?.accessToken, 'access-2');
      });

      test('is discarded by clear', () async {
        final fake = _ConfigurableStorage();
        final store = _storeOver(fake);
        await _save(store);
        fake.damagedKeys.add('auth_session_v2');
        await _replace(store, (await store.readSession())!);

        await store.clear();

        expect(await store.readSession(), isNull);
        expect(fake.values['auth_session_v2'], isNull);
      });

      test('is discarded by a matching clearIfCurrent', () async {
        final fake = _ConfigurableStorage();
        final store = _storeOver(fake);
        await _save(store);
        fake.damagedKeys.add('auth_session_v2');
        await _replace(store, (await store.readSession())!);
        final pending = (await store.readSession())!;

        expect(await store.clearIfCurrent(pending), isTrue);

        expect(await store.readSession(), isNull);
      });

      test('is discarded by a matching clearIfProfileCurrent', () async {
        final fake = _ConfigurableStorage();
        final store = _storeOver(fake);
        await _save(store);
        final saved = (await store.readSession())!;
        fake.damagedKeys.add('auth_session_v2');
        await _replace(store, saved);

        expect(await store.clearIfProfileCurrent(saved), isTrue);

        expect(await store.readSession(), isNull);
      });

      test('is replaced by a sign-in', () async {
        final fake = _ConfigurableStorage();
        final store = _storeOver(fake);
        await _save(store);
        fake.damagedKeys.add('auth_session_v2');
        await _replace(store, (await store.readSession())!);

        await store.saveSession(
          origin: 'https://example.test',
          accessToken: 'access-3',
          refreshToken: 'refresh-3',
          sessionId: 'session-3',
          accountId: '42',
          expiresInSeconds: 3600,
        );

        expect((await store.readSession())?.accessToken, 'access-3');
        expect((await _storeOver(fake).readSession())?.accessToken, 'access-3');
      });
    });

    test('readSession surfaces a read failure instead of clearing', () async {
      final fake = _BrokenStorage();
      final store = AuthSessionStore(
        storage: SecureStorageService(
          storage: fake,
          preferences: AppPreferencesStore(backend: _NoopBackend()),
        ),
      );

      await expectLater(
        store.readSession(),
        throwsA(
          isA<AppException>().having(
            (e) => e.code,
            'code',
            AppErrorCode.secureStorageReadFailed,
          ),
        ),
      );
      expect(fake.deleteAllCalls, 0);
    });

    test('returns the stored server URL', () async {
      final storage = SecureStorageService();
      final store = AuthSessionStore(storage: storage);
      await storage.setServerUrl('https://example.test');

      expect(await store.getLastServerUrl(), 'https://example.test');
    });

    test('returns null server URL when not set', () async {
      final store = AuthSessionStore(storage: SecureStorageService());

      expect(await store.getLastServerUrl(), isNull);
    });

    test('does not restore pre-v2 individual-key sessions', () async {
      // The legacy per-key session migration was removed: such installs must
      // re-authenticate rather than have a partial, account-less session
      // silently restored under a fabricated identity.
      final storage = SecureStorageService();
      final store = AuthSessionStore(storage: storage);
      await storage.setServerUrl('https://legacy.example');
      await storage.setAccessToken('access-1');
      await storage.setRefreshToken('refresh-1');
      await storage.setSessionId('session-1');
      await storage.setAccessTokenExpiresAt(
        DateTime.now().toUtc().add(const Duration(hours: 1)),
      );

      expect(await store.readSession(), isNull);
      // The server URL is left intact so the login screen can prefill it.
      expect(await storage.getServerUrl(), 'https://legacy.example');
    });

    test('migrates a pre-accountId auth_session_v2 blob', () async {
      // Older v2 blobs stored the raw account id under `profileId` and carried
      // no `accountId`/`revision`. They are upgraded in place: the account id
      // is adopted and the profile id becomes origin-qualified.
      final expiresAt = DateTime.now().toUtc().add(const Duration(hours: 1));
      FlutterSecureStorage.setMockInitialValues({
        'auth_session_v2':
            '{"profileId":"42","origin":"https://EXAMPLE.test/",'
            '"accessToken":"access-1","refreshToken":"refresh-1",'
            '"sessionId":"session-1",'
            '"accessTokenExpiresAt":"${expiresAt.toIso8601String()}"}',
      });
      final storage = SecureStorageService();
      final store = AuthSessionStore(storage: storage);

      final session = await store.readSession();

      expect(session?.origin, 'https://example.test');
      expect(session?.accountId, '42');
      expect(session?.profileId, 'https://example.test#42');
      expect(session?.revision, isNotEmpty);
    });

    test(
      'preserves a stable backend profile ID across sequential logins',
      () async {
        final store = AuthSessionStore(storage: SecureStorageService());

        await store.saveSession(
          origin: 'https://example.test',
          accessToken: 'access-1',
          refreshToken: 'refresh-1',
          sessionId: 'session-1',
          accountId: '42',
          expiresInSeconds: 3600,
        );
        final first = (await store.readSession())!;

        await store.saveSession(
          origin: 'https://example.test',
          accessToken: 'access-2',
          refreshToken: 'refresh-2',
          sessionId: 'session-2',
          accountId: '42',
          expiresInSeconds: 3600,
        );
        final second = (await store.readSession())!;

        expect(second.profileId, first.profileId);
        expect(second.profileId, 'https://example.test#42');
        expect(second.revision, isNot(first.revision));
      },
    );

    test('malformed canonical session clears without deadlocking', () async {
      FlutterSecureStorage.setMockInitialValues({
        'auth_session_v2': '{not json',
      });
      final store = AuthSessionStore(storage: SecureStorageService());

      expect(
        await store.readSession().timeout(const Duration(seconds: 1)),
        isNull,
      );
    });
  });
}

AuthSessionStore _storeOver(FlutterSecureStorage fake) {
  return AuthSessionStore(
    storage: SecureStorageService(
      storage: fake,
      preferences: AppPreferencesStore(backend: _NoopBackend()),
    ),
  );
}

Future<void> _save(AuthSessionStore store, {String? username}) {
  return store.saveSession(
    origin: 'https://example.test',
    accessToken: 'access-1',
    refreshToken: 'refresh-1',
    sessionId: 'session-1',
    accountId: '42',
    username: username,
    expiresInSeconds: 3600,
  );
}

Future<SessionReplacement> _replace(
  AuthSessionStore store,
  AuthSession expected, {
  String accessToken = 'access-2',
}) {
  return store.replaceSessionIfCurrent(
    expected: expected,
    accessToken: accessToken,
    refreshToken: 'refresh-2',
    sessionId: 'session-2',
    expiresInSeconds: 3600,
  );
}

/// Map-backed fake [FlutterSecureStorage] with scripted failures.
class _ConfigurableStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> values = {};

  /// Writes to these keys fail until the key is deleted.
  final Set<String> damagedKeys = {};

  /// Deletes of these keys fail.
  final Set<String> failingDeletes = {};

  /// How many upcoming writes fail, whatever the key.
  int failNextWrites = 0;
  int deleteAllCalls = 0;

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => values[key];

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
    if (failNextWrites > 0) {
      failNextWrites--;
      throw Exception('keystore busy');
    }
    if (damagedKeys.contains(key)) throw Exception('damaged entry');
    values[key] = value!;
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
    if (failingDeletes.contains(key)) throw Exception('delete failed');
    damagedKeys.remove(key);
    values.remove(key);
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
    deleteAllCalls++;
    values.clear();
    damagedKeys.clear();
  }
}

/// Fake [FlutterSecureStorage] simulating an unusable store (e.g. an
/// invalidated Android Keystore key): reads and writes throw until
/// [deleteAll] resets it.
class _BrokenStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> values = {};
  bool broken = true;
  int deleteAllCalls = 0;

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
    if (broken) throw Exception('keystore unavailable');
    return values[key];
  }

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
    if (broken) throw Exception('keystore unavailable');
    values[key] = value!;
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
    values.remove(key);
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
    deleteAllCalls++;
    values.clear();
    broken = false;
  }
}

class _NoopBackend implements AppPreferencesBackend {
  @override
  Future<String?> read(String key) async => null;

  @override
  Future<void> write(String key, String value) async {}

  @override
  Future<void> delete(String key) async {}
}
