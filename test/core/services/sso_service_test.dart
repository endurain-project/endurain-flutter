import 'package:endurain/core/constants/api_constants.dart';
import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/services/secure_storage_service.dart';
import 'package:endurain/core/services/sso_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  group('SsoService', () {
    test('rejects successful token exchange with missing token fields', () async {
      final storage = SecureStorageService();
      final service = SsoService(
        storage: storage,
        httpClient: MockClient((request) async {
          expect(
            request.url.path,
            '${ApiConstants.idpSessionTokenExchangeEndpoint}/session-1/tokens',
          );
          return http.Response(
            '{"access_token":"access-1","session_id":"session-2","expires_in":3600}',
            200,
          );
        }),
      );

      await service.initiateOAuth('oidc', serverUrl: 'https://example.test');

      await expectLater(
        service.exchangeSessionForTokens('session-1'),
        throwsA(
          isA<AppException>().having(
            (exception) => exception.code,
            'code',
            AppErrorCode.unexpectedResponseFormat,
          ),
        ),
      );
      expect(await storage.getAccessToken(), isNull);
      expect(await storage.getRefreshToken(), isNull);
      expect(await storage.getSessionId(), isNull);
    });

    test('rejects exchange when no flow has been started', () async {
      final service = SsoService(
        storage: SecureStorageService(),
        httpClient: MockClient((_) async => fail('Should not reach network')),
      );

      await expectLater(
        service.exchangeSessionForTokens('session-x'),
        throwsA(
          isA<AppException>().having(
            (e) => e.code,
            'code',
            AppErrorCode.pkceVerifierMissingRestartLogin,
          ),
        ),
      );
    });

    test('rejects exchange after clearPkce()', () async {
      final service = SsoService(
        storage: SecureStorageService(),
        httpClient: MockClient((_) async => fail('Should not reach network')),
      );

      await service.initiateOAuth('oidc', serverUrl: 'https://example.test');
      service.clearPkce();

      await expectLater(
        service.exchangeSessionForTokens('session-x'),
        throwsA(
          isA<AppException>().having(
            (e) => e.code,
            'code',
            AppErrorCode.pkceVerifierMissingRestartLogin,
          ),
        ),
      );
    });

    test('rejects exchange when the PKCE flow has expired', () async {
      // Freeze time so the flow is created "30 minutes ago".
      final baseTime = DateTime.utc(2026, 1, 1, 12);
      var currentTime = baseTime;

      final service = SsoService(
        storage: SecureStorageService(),
        httpClient: MockClient((_) async => fail('Should not reach network')),
        now: () => currentTime,
      );

      await service.initiateOAuth('oidc', serverUrl: 'https://example.test');

      // Advance time past the TTL.
      currentTime = baseTime.add(
        ApiConstants.ssoPkceTtl + const Duration(seconds: 1),
      );

      await expectLater(
        service.exchangeSessionForTokens('session-x'),
        throwsA(
          isA<AppException>().having(
            (e) => e.code,
            'code',
            AppErrorCode.pkceVerifierMissingRestartLogin,
          ),
        ),
      );
    });

    test('accepts exchange when the PKCE flow is within the TTL', () async {
      final baseTime = DateTime.utc(2026, 1, 1, 12);
      var currentTime = baseTime;

      final service = SsoService(
        storage: SecureStorageService(),
        httpClient: MockClient((request) async {
          return http.Response(
            '{"access_token":"at","refresh_token":"rt",'
            '"session_id":"sid","expires_in":3600}',
            200,
          );
        }),
        now: () => currentTime,
      );

      await service.initiateOAuth('oidc', serverUrl: 'https://example.test');

      // Advance time to just before the TTL expires.
      currentTime = baseTime.add(
        ApiConstants.ssoPkceTtl - const Duration(seconds: 1),
      );

      final result = await service.exchangeSessionForTokens('session-x');
      expect(result.success, isTrue);
    });

    test(
      'rejects exchange when stored server URL changed after flow initiation',
      () async {
        final storage = SecureStorageService();
        final service = SsoService(
          storage: storage,
          httpClient: MockClient((request) async {
            fail('No HTTP request should be made after server URL mismatch.');
          }),
        );

        // Initiate on server A.
        await service.initiateOAuth('oidc', serverUrl: 'https://server-a.test');

        // Simulate server URL being changed to server B in storage.
        await storage.setServerUrl('https://server-b.test');

        await expectLater(
          service.exchangeSessionForTokens('session-x'),
          throwsA(
            isA<AppException>().having(
              (e) => e.code,
              'code',
              AppErrorCode.pkceVerifierMissingRestartLogin,
            ),
          ),
        );
      },
    );
  });
}
