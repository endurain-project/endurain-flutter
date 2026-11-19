import 'dart:convert';

import 'package:endurain/core/auth/auth_service.dart';
import 'package:endurain/core/auth/auth_session_store.dart';
import 'package:endurain/core/auth/secure_storage_service.dart';
import 'package:endurain/core/auth/sign_in_flow.dart';
import 'package:endurain/core/auth/sso_service.dart';
import 'package:endurain/core/config/api_endpoints.dart';
import 'package:endurain/core/constants/api_constants.dart';
import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/network/base_http_client.dart';
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
    test(
      'rejects successful token exchange with missing token fields',
      () async {
        final storage = SecureStorageService();
        final service = SsoService(
          storage: storage,
          httpClient: MockClient((request) async {
            expect(
              request.url.path,
              ApiEndpoints.defaults.sessionTokensEndpoint('session-1'),
            );
            return http.Response(
              '{"next_step":"tokens","access_token":"access-1",'
              '"session_id":"session-2","expires_in":3600}',
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
      },
    );

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
          if (request.url.path == ApiEndpoints.defaults.profileEndpoint) {
            return http.Response('{"id":"$_uuid"}', 200);
          }
          return http.Response(_tokensStep, 200);
        }),
        now: () => currentTime,
      );

      await service.initiateOAuth('oidc', serverUrl: 'https://example.test');

      // Advance time to just before the TTL expires.
      currentTime = baseTime.add(
        ApiConstants.ssoPkceTtl - const Duration(seconds: 1),
      );

      final result = await service.exchangeSessionForTokens('session-x');
      expect(result.step, SignInStep.signedIn);
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
    test('initiateOAuth sends the app callback as the redirect', () async {
      final service = SsoService(
        storage: SecureStorageService(),
        httpClient: MockClient((_) async => fail('No request expected')),
      );

      final url = Uri.parse(
        await service.initiateOAuth('oidc', serverUrl: 'https://example.test'),
      );

      expect(url.path, '${ApiEndpoints.defaults.idpLoginEndpoint}/oidc');
      expect(
        url.queryParameters['redirect'],
        'com.endurain.endurain:/auth/sso/callback',
      );
      expect(url.queryParameters['code_challenge_method'], 'S256');
    });

    test('matchesCallback accepts only the app callback address', () {
      expect(
        SsoService.matchesCallback(
          Uri.parse('com.endurain.endurain:/auth/sso/callback?session_id=1'),
        ),
        isTrue,
      );
      expect(
        SsoService.matchesCallback(
          Uri.parse('endurain://auth/sso/callback?session_id=1'),
        ),
        isFalse,
      );
      expect(
        SsoService.matchesCallback(
          Uri.parse('com.endurain.endurain:/other?session_id=1'),
        ),
        isFalse,
      );
    });

    test('isCallbackAllowed matches the scheme case-insensitively', () {
      expect(SsoService.isCallbackAllowed(null), isTrue);
      expect(SsoService.isCallbackAllowed(const []), isFalse);
      expect(
        SsoService.isCallbackAllowed(const [
          'COM.Endurain.Endurain:/auth/sso/callback',
        ]),
        isTrue,
      );
      expect(
        SsoService.isCallbackAllowed(const ['endurain://auth/sso/callback']),
        isFalse,
      );
      expect(
        SsoService.isCallbackAllowed(const [
          'com.endurain.endurain:/auth/sso/callback/',
        ]),
        isFalse,
      );
    });

    test('getEnabledProviders reads the page of providers', () async {
      final service = SsoService(
        storage: SecureStorageService(),
        httpClient: MockClient((request) async {
          expect(request.url.path, ApiEndpoints.defaults.idpListEndpoint);
          expect(request.url.queryParameters['num_records'], '200');
          return http.Response(
            '{"items":[{"id":"$_uuid","slug":"pocket","name":"Pocket ID",'
            '"icon":"pocketid","icon_uploaded":false}],'
            '"total":1,"page":1,"num_records":200,"next":null}',
            200,
          );
        }),
      );

      final providers = await service.getEnabledProviders(
        serverUrl: 'https://example.test',
      );

      expect(providers.single.id, _uuid);
      expect(providers.single.slug, 'pocket');
    });

    test(
      'an SSO sign-in with MFA continues at AuthService.verifyMfa',
      () async {
        final storage = SecureStorageService();
        final client = MockClient((request) async {
          final path = request.url.path;
          if (path ==
              ApiEndpoints.defaults.sessionTokensEndpoint('session-1')) {
            return http.Response(
              '{"next_step":"mfa","mfa_challenge":"challenge-1",'
              '"methods":["totp"]}',
              200,
            );
          }
          if (path == ApiEndpoints.defaults.mfaVerifyEndpoint) {
            expect(
              (jsonDecode(request.body) as Map)['mfa_challenge'],
              'challenge-1',
            );
            // An SSO sign-in finishes with tokens, never a second exchange.
            return http.Response(_tokensStep, 200);
          }
          if (path == ApiEndpoints.defaults.profileEndpoint) {
            return http.Response('{"id":"$_uuid"}', 200);
          }
          fail('Unexpected request to ${request.url}');
        });
        final http0 = BaseHttpClient(httpClient: client);
        final sessionStore = AuthSessionStore(storage: storage);
        final flow = SignInFlow(
          sessionStore: sessionStore,
          http: http0,
          storage: storage,
        );
        final sso = SsoService(
          storage: storage,
          sessionStore: sessionStore,
          baseClient: http0,
          signInFlow: flow,
        );
        final auth = AuthService(
          storage: storage,
          sessionStore: sessionStore,
          baseClient: http0,
          signInFlow: flow,
        );

        await sso.initiateOAuth('oidc', serverUrl: 'https://example.test');
        final first = await sso.exchangeSessionForTokens('session-1');
        expect(first.step, SignInStep.mfa);

        final result = await auth.verifyMfa('123456');

        expect(result.step, SignInStep.signedIn);
        expect((await sessionStore.readSession())?.accountId, _uuid);
      },
    );
  });
}

const _uuid = '7c9e6679-7425-40de-944b-e07fc1f90ae7';

const _tokensStep =
    '{"next_step":"tokens","access_token":"at","refresh_token":"rt",'
    '"session_id":"sid","expires_in":3600}';
