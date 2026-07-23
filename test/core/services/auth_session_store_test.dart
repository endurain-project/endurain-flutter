import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:endurain/core/services/auth_session_store.dart';
import 'package:endurain/core/services/secure_storage_service.dart';

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
        await store.replaceSessionIfCurrent(
          expected: stale,
          accessToken: 'late-access-a',
          refreshToken: 'late-refresh-a',
          sessionId: 'late-session-a',
          expiresInSeconds: 3600,
        ),
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
