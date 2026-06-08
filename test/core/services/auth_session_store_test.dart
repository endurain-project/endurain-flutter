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
        accessToken: 'access-1',
        refreshToken: 'refresh-1',
        sessionId: 'session-1',
        username: 'joao',
        expiresInSeconds: 3600,
      );

      expect(await storage.getAccessToken(), 'access-1');
      expect(await storage.getRefreshToken(), 'refresh-1');
      expect(await storage.getSessionId(), 'session-1');
      expect(await storage.getUsername(), 'joao');
      expect(await storage.getAccessTokenExpiresAt(), isNotNull);
      expect(await store.isAccessTokenExpiringSoon(), isFalse);
    });

    test('clears auth tokens without removing server settings', () async {
      final storage = SecureStorageService();
      final store = AuthSessionStore(storage: storage);
      await storage.setServerUrl('https://example.test');
      await store.saveSession(
        accessToken: 'access-1',
        refreshToken: 'refresh-1',
        sessionId: 'session-1',
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
  });
}
