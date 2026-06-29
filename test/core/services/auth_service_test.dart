import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:endurain/core/config/api_endpoints.dart';
import 'package:endurain/core/config/app_config.dart';
import 'package:endurain/core/constants/api_constants.dart';
import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/services/auth_service.dart';
import 'package:endurain/core/services/auth_session_store.dart';
import 'package:endurain/core/services/secure_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  group('AuthService', () {
    test('stores tokens after login session exchange succeeds', () async {
      final storage = SecureStorageService();
      final requests = <http.Request>[];
      final service = AuthService(
        storage: storage,
        httpClient: MockClient((request) async {
          requests.add(request);

          if (request.url.path == ApiEndpoints.defaults.tokenEndpoint) {
            expect(request.bodyFields['username'], 'joao');
            expect(request.bodyFields['password'], 'secret');
            return http.Response('{"session_id":"session-1"}', 200);
          }

          if (request.url.path ==
              '${ApiEndpoints.defaults.idpSessionTokenExchangeEndpoint}/session-1/tokens') {
            return http.Response(
              '{"access_token":"access-1","refresh_token":"refresh-1","session_id":"session-2","expires_in":3600}',
              200,
            );
          }

          fail('Unexpected request to ${request.url}');
        }),
      );

      final result = await service.login(
        'joao',
        'secret',
        serverUrl: 'https://example.test',
      );

      expect(result.success, isTrue);
      expect(result.mfaRequired, isFalse);
      expect(result.accessToken, 'access-1');
      expect(await storage.getAccessToken(), 'access-1');
      expect(await storage.getRefreshToken(), 'refresh-1');
      expect(await storage.getSessionId(), 'session-2');
      expect(await storage.getUsername(), 'joao');
      expect(requests, hasLength(2));
    });

    test('returns MFA state without exchanging tokens', () async {
      final storage = SecureStorageService();
      final service = AuthService(
        storage: storage,
        httpClient: MockClient((request) async {
          return http.Response(
            '{"mfa_required":true,"username":"joao","message":"MFA required"}',
            200,
          );
        }),
      );

      final result = await service.login(
        'joao',
        'secret',
        serverUrl: 'https://example.test',
      );

      expect(result.mfaRequired, isTrue);
      expect(result.username, 'joao');
      expect(result.message, 'MFA required');
      expect(await storage.getUsername(), 'joao');
      expect(await storage.getAccessToken(), isNull);
    });

    test('throws typed login failure with server detail', () async {
      final service = AuthService(
        storage: SecureStorageService(),
        httpClient: MockClient((request) async {
          return http.Response('{"detail":"Bad credentials"}', 401);
        }),
      );

      expect(
        () => service.login('joao', 'wrong', serverUrl: 'https://example.test'),
        throwsA(
          isA<AppException>()
              .having(
                (exception) => exception.code,
                'code',
                AppErrorCode.loginFailed,
              )
              .having(
                (exception) => exception.details,
                'details',
                'Bad credentials',
              ),
        ),
      );
    });

    test('throws typed response error for malformed successful login JSON', () {
      final service = AuthService(
        storage: SecureStorageService(),
        httpClient: MockClient((request) async {
          return http.Response('not json', 200);
        }),
      );

      expect(
        () =>
            service.login('joao', 'secret', serverUrl: 'https://example.test'),
        throwsA(
          isA<AppException>().having(
            (exception) => exception.code,
            'code',
            AppErrorCode.unexpectedResponseFormat,
          ),
        ),
      );
    });

    test('rejects successful token exchange with missing token fields', () async {
      final storage = SecureStorageService();
      final service = AuthService(
        storage: storage,
        httpClient: MockClient((request) async {
          if (request.url.path == ApiEndpoints.defaults.tokenEndpoint) {
            return http.Response('{"session_id":"session-1"}', 200);
          }

          if (request.url.path ==
              '${ApiEndpoints.defaults.idpSessionTokenExchangeEndpoint}/session-1/tokens') {
            return http.Response(
              '{"access_token":"access-1","session_id":"session-2","expires_in":3600}',
              200,
            );
          }

          fail('Unexpected request to ${request.url}');
        }),
      );

      await expectLater(
        service.login('joao', 'secret', serverUrl: 'https://example.test'),
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

    test('clears local tokens when refresh returns malformed success', () async {
      final storage = SecureStorageService();
      await storage.setServerUrl('https://example.test');
      await storage.setAccessToken('access-1');
      await storage.setRefreshToken('refresh-1');
      await storage.setSessionId('session-1');
      await storage.setAccessTokenExpiresAt(DateTime.now().toUtc());
      final service = AuthService(
        storage: storage,
        httpClient: MockClient((request) async {
          expect(request.url.path, ApiEndpoints.defaults.refreshEndpoint);
          return http.Response(
            '{"access_token":"access-2","session_id":"session-2","expires_in":3600}',
            200,
          );
        }),
      );

      final refreshed = await service.refreshToken();

      expect(refreshed, isFalse);
      expect(await storage.getAccessToken(), isNull);
      expect(await storage.getRefreshToken(), isNull);
      expect(await storage.getSessionId(), isNull);
    });

    test('clears local tokens when server logout fails', () async {
      final storage = SecureStorageService();
      await storage.setServerUrl('https://example.test');
      await storage.setAccessToken('access-1');
      await storage.setRefreshToken('refresh-1');
      await storage.setSessionId('session-1');
      final service = AuthService(
        storage: storage,
        httpClient: MockClient((request) async {
          expect(request.url.path, ApiEndpoints.defaults.logoutEndpoint);
          return http.Response('', 500);
        }),
      );

      final serverLogoutSucceeded = await service.logout();

      expect(serverLogoutSucceeded, isFalse);
      expect(await storage.getAccessToken(), isNull);
      expect(await storage.getRefreshToken(), isNull);
      expect(await storage.getSessionId(), isNull);
      expect(await storage.getServerUrl(), 'https://example.test');
    });

    test('throws when no server URL is configured for login', () async {
      final service = AuthService(
        storage: SecureStorageService(),
        httpClient: MockClient((request) async {
          fail('No request should be made without a server URL.');
        }),
      );

      await expectLater(
        service.login('joao', 'secret'),
        throwsA(
          isA<AppException>().having(
            (exception) => exception.code,
            'code',
            AppErrorCode.serverUrlNotConfigured,
          ),
        ),
      );
    });

    test('falls back to the stored server URL for login', () async {
      final storage = SecureStorageService();
      await storage.setServerUrl('https://stored.test');
      final service = AuthService(
        storage: storage,
        httpClient: MockClient((request) async {
          expect(request.url.origin, 'https://stored.test');
          if (request.url.path == ApiEndpoints.defaults.tokenEndpoint) {
            return http.Response('{"session_id":"session-1"}', 200);
          }
          return http.Response(
            '{"access_token":"access-1","refresh_token":"refresh-1","session_id":"session-2","expires_in":3600}',
            200,
          );
        }),
      );

      final result = await service.login('joao', 'secret');

      expect(result.accessToken, 'access-1');
    });

    test('throws when login succeeds without session or MFA', () async {
      final service = AuthService(
        storage: SecureStorageService(),
        httpClient: MockClient((request) async {
          return http.Response('{"unexpected":true}', 200);
        }),
      );

      await expectLater(
        service.login('joao', 'secret', serverUrl: 'https://example.test'),
        throwsA(
          isA<AppException>().having(
            (exception) => exception.code,
            'code',
            AppErrorCode.noSessionIdReceived,
          ),
        ),
      );
    });

    test('wraps transport errors during login as a typed error', () async {
      final service = AuthService(
        storage: SecureStorageService(),
        httpClient: MockClient((request) async {
          throw http.ClientException('network down');
        }),
      );

      await expectLater(
        service.login('joao', 'secret', serverUrl: 'https://example.test'),
        throwsA(
          isA<AppException>().having(
            (exception) => exception.code,
            'code',
            AppErrorCode.loginError,
          ),
        ),
      );
    });

    test('verifyMfa exchanges tokens after a successful code', () async {
      final storage = SecureStorageService();
      final service = AuthService(
        storage: storage,
        httpClient: MockClient((request) async {
          if (request.url.path == ApiEndpoints.defaults.tokenEndpoint) {
            return http.Response(
              '{"mfa_required":true,"username":"joao"}',
              200,
            );
          }
          if (request.url.path == ApiEndpoints.defaults.mfaVerifyEndpoint) {
            return http.Response('{"session_id":"session-1"}', 200);
          }
          if (request.url.path ==
              '${ApiEndpoints.defaults.idpSessionTokenExchangeEndpoint}/session-1/tokens') {
            return http.Response(
              '{"access_token":"access-1","refresh_token":"refresh-1","session_id":"session-2","expires_in":3600}',
              200,
            );
          }
          fail('Unexpected request to ${request.url}');
        }),
      );

      await service.login('joao', 'secret', serverUrl: 'https://example.test');
      final result = await service.verifyMfa('joao', '123456');

      expect(result.success, isTrue);
      expect(result.accessToken, 'access-1');
      expect(await storage.getAccessToken(), 'access-1');
    });

    test('verifyMfa requires a configured server URL', () async {
      final service = AuthService(
        storage: SecureStorageService(),
        httpClient: MockClient((request) async {
          fail('No request should be made without a server URL.');
        }),
      );

      await expectLater(
        service.verifyMfa('joao', '123456'),
        throwsA(
          isA<AppException>().having(
            (exception) => exception.code,
            'code',
            AppErrorCode.serverUrlNotConfigured,
          ),
        ),
      );
    });

    test('verifyMfa fails when no PKCE verifier is present', () async {
      final storage = SecureStorageService();
      await storage.setServerUrl('https://example.test');
      final service = AuthService(
        storage: storage,
        httpClient: MockClient((request) async {
          fail('No request should be made without a PKCE verifier.');
        }),
      );

      await expectLater(
        service.verifyMfa('joao', '123456'),
        throwsA(
          isA<AppException>().having(
            (exception) => exception.code,
            'code',
            AppErrorCode.pkceVerifierMissingRestartLogin,
          ),
        ),
      );
    });

    test('verifyMfa maps a rejected code to a typed failure', () async {
      final storage = SecureStorageService();
      final service = AuthService(
        storage: storage,
        httpClient: MockClient((request) async {
          if (request.url.path == ApiEndpoints.defaults.tokenEndpoint) {
            return http.Response('{"mfa_required":true}', 200);
          }
          return http.Response('{"detail":"Invalid code"}', 401);
        }),
      );

      await service.login('joao', 'secret', serverUrl: 'https://example.test');

      await expectLater(
        service.verifyMfa('joao', '000000'),
        throwsA(
          isA<AppException>()
              .having(
                (exception) => exception.code,
                'code',
                AppErrorCode.mfaVerificationFailed,
              )
              .having(
                (exception) => exception.details,
                'details',
                'Invalid code',
              ),
        ),
      );
    });

    test('refreshToken stores rotated tokens on success', () async {
      final storage = SecureStorageService();
      await storage.setServerUrl('https://example.test');
      await storage.setAccessToken('access-1');
      await storage.setRefreshToken('refresh-1');
      final service = AuthService(
        storage: storage,
        httpClient: MockClient((request) async {
          expect(request.url.path, ApiEndpoints.defaults.refreshEndpoint);
          expect(request.headers['Authorization'], 'Bearer refresh-1');
          return http.Response(
            '{"access_token":"access-2","refresh_token":"refresh-2","session_id":"session-2","expires_in":3600}',
            200,
          );
        }),
      );

      final refreshed = await service.refreshToken();

      expect(refreshed, isTrue);
      expect(await storage.getAccessToken(), 'access-2');
      expect(await storage.getRefreshToken(), 'refresh-2');
      expect(await storage.getSessionId(), 'session-2');
    });

    test('refreshToken clears the session without credentials', () async {
      final storage = SecureStorageService();
      await storage.setAccessToken('access-1');
      final service = AuthService(
        storage: storage,
        httpClient: MockClient((request) async {
          fail('No request should be made without a refresh token.');
        }),
      );

      final refreshed = await service.refreshToken();

      expect(refreshed, isFalse);
      expect(await storage.getAccessToken(), isNull);
    });

    test('refreshToken keeps the session on transport errors', () async {
      final storage = SecureStorageService();
      await storage.setServerUrl('https://example.test');
      await storage.setAccessToken('access-1');
      await storage.setRefreshToken('refresh-1');
      final service = AuthService(
        storage: storage,
        httpClient: MockClient((request) async {
          throw http.ClientException('network down');
        }),
      );

      final refreshed = await service.refreshToken();

      // Transient transport failure must not log the user out: the refresh
      // token is still valid and a later attempt should succeed.
      expect(refreshed, isFalse);
      expect(await storage.getAccessToken(), 'access-1');
      expect(await storage.getRefreshToken(), 'refresh-1');
    });

    test('refreshToken keeps the session on a 5xx server error', () async {
      final storage = SecureStorageService();
      await storage.setServerUrl('https://example.test');
      await storage.setAccessToken('access-1');
      await storage.setRefreshToken('refresh-1');
      final service = AuthService(
        storage: storage,
        httpClient: MockClient((request) async {
          return http.Response('{"detail":"temporarily down"}', 503);
        }),
      );

      final refreshed = await service.refreshToken();

      expect(refreshed, isFalse);
      expect(await storage.getAccessToken(), 'access-1');
      expect(await storage.getRefreshToken(), 'refresh-1');
    });

    test(
      'concurrent refreshToken calls trigger a single network round-trip',
      () async {
        final storage = SecureStorageService();
        await storage.setServerUrl('https://example.test');
        await storage.setAccessToken('access-1');
        await storage.setRefreshToken('refresh-1');
        var refreshRequests = 0;
        final service = AuthService(
          storage: storage,
          httpClient: MockClient((request) async {
            expect(request.url.path, ApiEndpoints.defaults.refreshEndpoint);
            refreshRequests++;
            // Yield so all concurrent callers are awaiting before the first
            // refresh completes.
            await Future<void>.delayed(Duration.zero);
            return http.Response(
              '{"access_token":"access-2","refresh_token":"refresh-2","session_id":"session-2","expires_in":3600}',
              200,
            );
          }),
        );

        final results = await Future.wait([
          service.refreshToken(),
          service.refreshToken(),
          service.refreshToken(),
        ]);

        expect(results, everyElement(isTrue));
        expect(refreshRequests, 1);
        expect(await storage.getRefreshToken(), 'refresh-2');
      },
    );

    test(
      'refreshToken can run again after an in-flight refresh completes',
      () async {
        final storage = SecureStorageService();
        await storage.setServerUrl('https://example.test');
        await storage.setAccessToken('access-1');
        await storage.setRefreshToken('refresh-1');
        var refreshRequests = 0;
        final service = AuthService(
          storage: storage,
          httpClient: MockClient((request) async {
            refreshRequests++;
            final next = refreshRequests + 1;
            return http.Response(
              '{"access_token":"access-$next","refresh_token":"refresh-$next","session_id":"session-$next","expires_in":3600}',
              200,
            );
          }),
        );

        expect(await service.refreshToken(), isTrue);
        expect(await service.refreshToken(), isTrue);

        expect(refreshRequests, 2);
      },
    );

    test('logout succeeds when the server confirms the logout', () async {
      final storage = SecureStorageService();
      await storage.setServerUrl('https://example.test');
      await storage.setAccessToken('access-1');
      await storage.setRefreshToken('refresh-1');
      final service = AuthService(
        storage: storage,
        httpClient: MockClient((request) async {
          expect(request.url.path, ApiEndpoints.defaults.logoutEndpoint);
          return http.Response('', 200);
        }),
      );

      final serverLogoutSucceeded = await service.logout();

      expect(serverLogoutSucceeded, isTrue);
      expect(await storage.getAccessToken(), isNull);
      expect(await storage.getRefreshToken(), isNull);
    });

    test('logout clears local tokens without server credentials', () async {
      final storage = SecureStorageService();
      await storage.setServerUrl('https://example.test');
      await storage.setAccessToken('access-1');
      final service = AuthService(
        storage: storage,
        httpClient: MockClient((request) async {
          fail('No server logout should run without a refresh token.');
        }),
      );

      final serverLogoutSucceeded = await service.logout();

      expect(serverLogoutSucceeded, isTrue);
      expect(await storage.getAccessToken(), isNull);
    });

    test('isAuthenticated is true for a valid unexpired token', () async {
      final storage = SecureStorageService();
      await storage.setAccessToken('access-1');
      await storage.setAccessTokenExpiresAt(
        DateTime.now().toUtc().add(const Duration(hours: 1)),
      );
      final service = AuthService(
        storage: storage,
        httpClient: MockClient((request) async {
          fail('No refresh should be needed for a valid token.');
        }),
      );

      expect(await service.isAuthenticated(), isTrue);
    });

    test(
      'isAuthenticated clears the session without a refresh token',
      () async {
        final storage = SecureStorageService();
        await storage.setAccessToken('access-1');
        await storage.setAccessTokenExpiresAt(
          DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
        );
        final service = AuthService(
          storage: storage,
          httpClient: MockClient((request) async {
            fail('No refresh should run without a refresh token.');
          }),
        );

        expect(await service.isAuthenticated(), isFalse);
        expect(await storage.getAccessToken(), isNull);
      },
    );

    test('isAuthenticated refreshes an expiring token', () async {
      final storage = SecureStorageService();
      await storage.setServerUrl('https://example.test');
      await storage.setAccessToken('access-1');
      await storage.setRefreshToken('refresh-1');
      await storage.setAccessTokenExpiresAt(
        DateTime.now().toUtc().add(const Duration(seconds: 30)),
      );
      final service = AuthService(
        storage: storage,
        httpClient: MockClient((request) async {
          return http.Response(
            '{"access_token":"access-2","refresh_token":"refresh-2","session_id":"session-2","expires_in":3600}',
            200,
          );
        }),
      );

      expect(await service.isAuthenticated(), isTrue);
      expect(await storage.getAccessToken(), 'access-2');
    });

    test('isAuthenticated clears the session when refresh fails', () async {
      final storage = SecureStorageService();
      await storage.setServerUrl('https://example.test');
      await storage.setAccessToken('access-1');
      await storage.setRefreshToken('refresh-1');
      await storage.setAccessTokenExpiresAt(
        DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
      );
      final service = AuthService(
        storage: storage,
        httpClient: MockClient((request) async {
          return http.Response('{"detail":"Expired"}', 401);
        }),
      );

      expect(await service.isAuthenticated(), isFalse);
      expect(await storage.getAccessToken(), isNull);
      expect(await storage.getRefreshToken(), isNull);
    });

    test(
      'refreshToken reads server URL and refresh token from session store',
      () async {
        // sessionStorage is the session store's backing; rawStorage is the
        // _storage field — they are distinct to prove the session store path
        // is used, not the raw storage path.
        final sessionStorage = SecureStorageService();
        await sessionStorage.setServerUrl('https://session.test');
        await sessionStorage.setRefreshToken('refresh-from-store');
        final sessionStore = AuthSessionStore(storage: sessionStorage);
        final rawStorage = SecureStorageService();
        final service = AuthService(
          storage: rawStorage,
          sessionStore: sessionStore,
          httpClient: MockClient((request) async {
            expect(request.url.origin, 'https://session.test');
            expect(
              request.headers[ApiConstants.authorizationHeader],
              'Bearer refresh-from-store',
            );
            return http.Response(
              '{"access_token":"access-2","refresh_token":"refresh-2",'
              '"session_id":"session-2","expires_in":3600}',
              200,
            );
          }),
        );

        final refreshed = await service.refreshToken();

        expect(refreshed, isTrue);
      },
    );

    test(
      'logout reads server URL and refresh token from session store',
      () async {
        final sessionStorage = SecureStorageService();
        await sessionStorage.setServerUrl('https://session.test');
        await sessionStorage.setRefreshToken('refresh-from-store');
        final sessionStore = AuthSessionStore(storage: sessionStorage);
        final rawStorage = SecureStorageService();
        final service = AuthService(
          storage: rawStorage,
          sessionStore: sessionStore,
          httpClient: MockClient((request) async {
            expect(request.url.origin, 'https://session.test');
            expect(
              request.headers[ApiConstants.authorizationHeader],
              'Bearer refresh-from-store',
            );
            return http.Response('', 200);
          }),
        );

        final serverLogoutSucceeded = await service.logout();

        expect(serverLogoutSucceeded, isTrue);
      },
    );

    test(
      'rejects http serverUrl in managed mode before making any request',
      () async {
        final service = AuthService(
          storage: SecureStorageService(),
          httpClient: MockClient((request) async {
            fail(
              'No HTTP request should be made with http:// in managed mode.',
            );
          }),
          config: const AppConfig(transportMode: AppTransportMode.managed),
        );

        await expectLater(
          service.login('joao', 'secret', serverUrl: 'http://example.test'),
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

    test('uses custom apiBasePath from ApiEndpoints', () async {
      const v2Config = AppConfig(apiBasePath: '/api/v2');
      final requests = <http.Request>[];
      final service = AuthService(
        storage: SecureStorageService(),
        httpClient: MockClient((request) async {
          requests.add(request);
          if (request.url.path == '/api/v2/auth/login') {
            return http.Response('{"session_id":"session-1"}', 200);
          }
          if (request.url.path ==
              '/api/v2/public/idp/session/session-1/tokens') {
            return http.Response(
              '{"access_token":"a","refresh_token":"r","session_id":"s2","expires_in":3600}',
              200,
            );
          }
          fail('Unexpected path: ${request.url.path}');
        }),
        config: v2Config,
        endpoints: const ApiEndpoints(v2Config),
      );

      await service.login('joao', 'secret', serverUrl: 'https://example.test');

      expect(requests.first.url.path, '/api/v2/auth/login');
    });
  });
}
