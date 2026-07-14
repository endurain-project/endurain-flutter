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
        profileId: '42',
        username: 'joao',
        expiresInSeconds: 3600,
      );

      expect(await storage.getAccessToken(), isNull);
      expect(await storage.getRefreshToken(), isNull);
      expect(await storage.getSessionId(), isNull);
      expect(await storage.getUsername(), 'joao');
      expect(await storage.getAccessTokenExpiresAt(), isNull);
      expect(await storage.getAuthSession(), isNotNull);
      expect(await store.isAccessTokenExpiringSoon(), isFalse);
      final session = await store.readSession();
      expect(session?.origin, 'https://example.test');
      expect(session?.accessToken, 'access-1');
    });

    test('normalizes the committed origin', () async {
      final store = AuthSessionStore(storage: SecureStorageService());

      await store.saveSession(
        origin: 'https://EXAMPLE.test/',
        accessToken: 'access-1',
        refreshToken: 'refresh-1',
        sessionId: 'session-1',
        profileId: '42',
        expiresInSeconds: 3600,
      );

      expect((await store.readSession())?.origin, 'https://example.test');
    });

    test('stale session cannot replace or clear a newer login', () async {
      final store = AuthSessionStore(storage: SecureStorageService());
      await store.saveSession(
        origin: 'https://a.example',
        accessToken: 'access-a',
        refreshToken: 'refresh-a',
        sessionId: 'session-a',
        profileId: '42',
        expiresInSeconds: 3600,
      );
      final stale = (await store.readSession())!;

      await store.saveSession(
        origin: 'https://b.example',
        accessToken: 'access-b',
        refreshToken: 'refresh-b',
        sessionId: 'session-b',
        profileId: '43',
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
        profileId: '42',
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

      expect(await store.getServerUrl(), 'https://example.test');
    });

    test('returns null server URL when not set', () async {
      final store = AuthSessionStore(storage: SecureStorageService());

      expect(await store.getServerUrl(), isNull);
    });

    test(
      'migrates a complete legacy session into the committed bundle',
      () async {
        final storage = SecureStorageService();
        final store = AuthSessionStore(storage: storage);
        await storage.setServerUrl('https://legacy.example');
        await storage.setAccessToken('access-1');
        await storage.setRefreshToken('refresh-1');
        await storage.setSessionId('session-1');
        await storage.setAccessTokenExpiresAt(
          DateTime.now().toUtc().add(const Duration(hours: 1)),
        );

        final session = await store.readSession();

        expect(session?.origin, 'https://legacy.example');
        expect(session?.refreshToken, 'refresh-1');
        expect(await storage.getAuthSession(), isNotNull);
        expect(await storage.getAccessToken(), isNull);
        expect(await storage.getRefreshToken(), isNull);
      },
    );

    test('migrates the previous auth_session_v2 JSON shape', () async {
      final expiresAt = DateTime.now().toUtc().add(const Duration(hours: 1));
      FlutterSecureStorage.setMockInitialValues({
        'auth_session_v2':
            '{"origin":"https://EXAMPLE.test/",'
            '"accessToken":"access-1","refreshToken":"refresh-1",'
            '"sessionId":"session-1",'
            '"accessTokenExpiresAt":"${expiresAt.toIso8601String()}"}',
      });
      final storage = SecureStorageService();
      final store = AuthSessionStore(storage: storage);

      final session = await store.readSession();

      expect(session?.origin, 'https://example.test');
      expect(session?.profileId, isNotEmpty);
      expect(session?.revision, isNotEmpty);
      expect(await storage.isAuthSessionAuthoritative(), isTrue);
    });

    test('preserves a stable backend profile ID across sequential logins',
        () async {
      final store = AuthSessionStore(storage: SecureStorageService());

      await store.saveSession(
        origin: 'https://example.test',
        accessToken: 'access-1',
        refreshToken: 'refresh-1',
        sessionId: 'session-1',
        profileId: '42',
        expiresInSeconds: 3600,
      );
      final first = (await store.readSession())!;

      await store.saveSession(
        origin: 'https://example.test',
        accessToken: 'access-2',
        refreshToken: 'refresh-2',
        sessionId: 'session-2',
        profileId: '42',
        expiresInSeconds: 3600,
      );
      final second = (await store.readSession())!;

      expect(second.profileId, first.profileId);
      expect(second.revision, isNot(first.revision));
    });

    test('malformed canonical session clears without deadlocking', () async {
      FlutterSecureStorage.setMockInitialValues({
        'auth_session_v2': '{not json',
        'auth_session_authoritative': 'true',
      });
      final store = AuthSessionStore(storage: SecureStorageService());

      expect(
        await store.readSession().timeout(const Duration(seconds: 1)),
        isNull,
      );
    });
  });
}
