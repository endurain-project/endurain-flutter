import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/services/secure_storage_service.dart';
import 'package:endurain/core/utils/server_url_resolver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  group('ServerUrlResolver', () {
    test('returns the provided URL when non-empty', () async {
      final resolver = ServerUrlResolver(storage: SecureStorageService());

      final url = await resolver.resolve(serverUrl: 'https://provided.test');

      expect(url, 'https://provided.test');
    });

    test('falls back to the stored URL when no URL is provided', () async {
      final storage = SecureStorageService();
      await storage.setServerUrl('https://stored.test');
      final resolver = ServerUrlResolver(storage: storage);

      final url = await resolver.resolve();

      expect(url, 'https://stored.test');
    });

    test('provided URL takes precedence over the stored URL', () async {
      final storage = SecureStorageService();
      await storage.setServerUrl('https://stored.test');
      final resolver = ServerUrlResolver(storage: storage);

      final url = await resolver.resolve(serverUrl: 'https://provided.test');

      expect(url, 'https://provided.test');
    });

    test('throws serverUrlNotConfigured when neither source has a URL',
        () async {
      final resolver = ServerUrlResolver(storage: SecureStorageService());

      await expectLater(
        resolver.resolve(),
        throwsA(
          isA<AppException>().having(
            (e) => e.code,
            'code',
            AppErrorCode.serverUrlNotConfigured,
          ),
        ),
      );
    });

    test('treats an empty provided URL as absent and falls back to storage',
        () async {
      final storage = SecureStorageService();
      await storage.setServerUrl('https://stored.test');
      final resolver = ServerUrlResolver(storage: storage);

      final url = await resolver.resolve(serverUrl: '');

      expect(url, 'https://stored.test');
    });

    test('throws when provided URL is empty and storage is also empty',
        () async {
      final resolver = ServerUrlResolver(storage: SecureStorageService());

      await expectLater(
        resolver.resolve(serverUrl: ''),
        throwsA(
          isA<AppException>().having(
            (e) => e.code,
            'code',
            AppErrorCode.serverUrlNotConfigured,
          ),
        ),
      );
    });

    test('persists the provided URL to storage when save is true', () async {
      final storage = SecureStorageService();
      final resolver = ServerUrlResolver(storage: storage);

      await resolver.resolve(serverUrl: 'https://new.test', save: true);

      expect(await storage.getServerUrl(), 'https://new.test');
    });

    test('does not write to storage when save is false (default)', () async {
      final storage = SecureStorageService();
      final resolver = ServerUrlResolver(storage: storage);

      await resolver.resolve(serverUrl: 'https://new.test');

      expect(await storage.getServerUrl(), isNull);
    });

    test('does not overwrite storage when no URL is provided and save is true',
        () async {
      final storage = SecureStorageService();
      await storage.setServerUrl('https://stored.test');
      final resolver = ServerUrlResolver(storage: storage);

      await resolver.resolve(save: true);

      // Stored value should be unchanged — there is nothing new to write.
      expect(await storage.getServerUrl(), 'https://stored.test');
    });
  });
}
