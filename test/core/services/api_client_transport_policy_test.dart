import 'package:endurain/core/config/app_config.dart';
import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/services/secure_storage_service.dart';
import 'package:endurain/core/services/server_settings_service.dart';
import 'package:endurain/core/utils/server_url_resolver.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

/// HTTP client that fails the test if any request is made.
class _AssertNoCallHttpClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    fail(
      'HTTP client should not be called; URL was not rejected before network',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  group('Managed-mode transport policy integration', () {
    test(
      'stored http:// URL is rejected in managed mode before any network call',
      () async {
        final storage = SecureStorageService();
        await storage.setServerUrl('http://insecure.test');

        const managed = AppConfig(transportMode: AppTransportMode.managed);
        final service = ServerSettingsService(
          urlResolver: ServerUrlResolver(storage: storage, config: managed),
          httpClient: _AssertNoCallHttpClient(),
        );

        await expectLater(
          service.getServerSettings(),
          throwsA(
            isA<AppException>().having(
              (e) => e.code,
              'code',
              AppErrorCode.serverUrlNotConfigured,
            ),
          ),
        );
      },
    );

    test('stored http:// URL is accepted in selfHosted mode', () async {
      final storage = SecureStorageService();
      await storage.setServerUrl('http://local.test');

      const selfHosted = AppConfig(transportMode: AppTransportMode.selfHosted);
      final resolver = ServerUrlResolver(storage: storage, config: selfHosted);

      // Resolving succeeds — the URL is returned without throwing.
      final url = await resolver.resolve();
      expect(url, 'http://local.test');
    });
  });
}
