import 'dart:async';
import 'dart:convert';

import 'package:endurain/core/auth/auth_service.dart';
import 'package:endurain/core/auth/auth_session_store.dart';
import 'package:endurain/core/auth/secure_storage_service.dart';
import 'package:endurain/core/config/api_endpoints.dart';
import 'package:endurain/core/config/app_config.dart';
import 'package:endurain/core/constants/api_constants.dart';
import 'package:endurain/core/diagnostics/diagnostics_service.dart';
import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/models/auth_session.dart';
import 'package:endurain/core/utils/pkce_utils.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../helpers/recording_diagnostics.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  group('AuthService', () {
    test(
      'password sign-in exchanges the session with the PKCE verifier',
      () async {
        final storage = SecureStorageService();
        final requests = <http.Request>[];
        final service = AuthService(
          storage: storage,
          httpClient: MockClient((request) async {
            requests.add(request);
            final path = request.url.path;
            if (path == ApiEndpoints.defaults.tokenEndpoint) {
              expect(request.url.query, isEmpty);
              expect(request.bodyFields['username'], 'joao');
              expect(request.bodyFields['password'], 'secret');
              expect(request.bodyFields['code_challenge_method'], 'S256');
              expect(request.bodyFields['code_challenge'], isNotEmpty);
              expect(request.headers[ApiConstants.deviceIdHeader], isNull);
              return http.Response(_exchangeStep(), 200);
            }
            if (path ==
                ApiEndpoints.defaults.sessionTokensEndpoint('session-1')) {
              final verifier =
                  (jsonDecode(request.body) as Map)['code_verifier'] as String;
              expect(
                PkceUtils.generateCodeChallenge(verifier),
                requests.first.bodyFields['code_challenge'],
              );
              expect(request.headers[ApiConstants.deviceIdHeader], _deviceId);
              return http.Response(_tokensStep(), 200);
            }
            if (path == ApiEndpoints.defaults.profileEndpoint) {
              expect(request.headers['Authorization'], 'Bearer access-1');
              return http.Response('{"id":"$_uuid"}', 200);
            }
            fail('Unexpected request to ${request.url}');
          }),
        );

        final result = await service.login(
          'joao',
          'secret',
          serverUrl: 'https://example.test',
        );

        expect(result.step, SignInStep.signedIn);
        final session = await _readSession(storage);
        expect(session?.accessToken, 'access-1');
        expect(session?.refreshToken, 'refresh-1');
        expect(session?.sessionId, 'session-2');
        expect(session?.accountId, _uuid);
        expect(await storage.getUsername(), 'joao');
        expect(await storage.getDeviceId('https://example.test'), _deviceId);
        expect(requests, hasLength(3));
      },
    );

    test('returns the MFA step without saving a session', () async {
      final storage = SecureStorageService();
      final service = AuthService(
        storage: storage,
        httpClient: MockClient((request) async {
          return http.Response(
            '{"next_step":"mfa","mfa_challenge":"challenge-1",'
            '"methods":["totp","backup_code"]}',
            200,
          );
        }),
      );

      final result = await service.login(
        'joao',
        'secret',
        serverUrl: 'https://example.test',
      );

      expect(result.step, SignInStep.mfa);
      expect(result.mfaMethods, ['totp', 'backup_code']);
      expect(await _readSession(storage), isNull);
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

    test(
      'rejects successful token exchange with missing token fields',
      () async {
        final storage = SecureStorageService();
        final service = AuthService(
          storage: storage,
          httpClient: MockClient((request) async {
            final path = request.url.path;
            if (path == ApiEndpoints.defaults.tokenEndpoint) {
              return http.Response(_exchangeStep(), 200);
            }
            if (path ==
                ApiEndpoints.defaults.sessionTokensEndpoint('session-1')) {
              return http.Response(
                '{"next_step":"tokens","access_token":"access-1",'
                '"session_id":"session-2","expires_in":3600}',
                200,
              );
            }
            if (path == ApiEndpoints.defaults.profileEndpoint) {
              return http.Response('{"id":"$_uuid"}', 200);
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
        expect(await _readSession(storage), isNull);
      },
    );

    test(
      'clears local tokens when refresh returns malformed success',
      () async {
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
      },
    );

    test('clears local tokens when server logout fails', () async {
      final storage = SecureStorageService();
      await _seedSession(storage);
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
      expect(await _readSession(storage), isNull);
    });

    test(
      'logout still completes when the stored session is unreadable',
      () async {
        final service = AuthService(
          storage: SecureStorageService(storage: _UnreadableStorage()),
          httpClient: MockClient((request) async {
            fail('No server call without a readable session.');
          }),
        );

        expect(await service.logout(), isTrue);
      },
    );

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
        httpClient: _signInServer(origin: 'https://stored.test'),
      );

      final result = await service.login('joao', 'secret');

      expect(result.step, SignInStep.signedIn);
      final session = await _readSession(storage);
      expect(session?.origin, 'https://stored.test');
      expect(session?.accessToken, 'access-1');
    });

    test(
      'an unknown next_step stops the sign-in and asks for an update',
      () async {
        final storage = SecureStorageService();
        final service = AuthService(
          storage: storage,
          httpClient: MockClient((request) async {
            return http.Response('{"next_step":"passkey"}', 200);
          }),
        );

        await expectLater(
          service.login('joao', 'secret', serverUrl: 'https://example.test'),
          throwsA(
            isA<AppException>().having(
              (exception) => exception.code,
              'code',
              AppErrorCode.signInStepUnsupported,
            ),
          ),
        );
        expect(await _readSession(storage), isNull);
        await expectLater(
          service.verifyMfa('123456'),
          throwsA(_hasCode(AppErrorCode.mfaSessionMissing)),
        );
      },
    );

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

    test('verifyMfa sends the challenge, then exchanges the session', () async {
      final storage = SecureStorageService();
      final service = AuthService(
        storage: storage,
        httpClient: _signInServer(
          login: (_) => http.Response(
            '{"next_step":"mfa","mfa_challenge":"challenge-1","methods":["totp"]}',
            200,
          ),
          mfaVerify: (request) {
            expect(jsonDecode(request.body), {
              'mfa_challenge': 'challenge-1',
              'mfa_code': '123456',
            });
            return http.Response(_exchangeStep(), 200);
          },
        ),
      );

      await service.login('joao', 'secret', serverUrl: 'https://example.test');
      final result = await service.verifyMfa('123456');

      expect(result.step, SignInStep.signedIn);
      expect((await _readSession(storage))?.accessToken, 'access-1');
    });

    test('verifyMfa without a pending step reports a lost sign-in', () async {
      final service = AuthService(
        storage: SecureStorageService(),
        httpClient: MockClient((request) async {
          fail('No request should be made without a pending sign-in.');
        }),
      );

      await expectLater(
        service.verifyMfa('123456'),
        throwsA(_hasCode(AppErrorCode.mfaSessionMissing)),
      );
    });

    test('a wrong MFA code keeps the step for another try', () async {
      final storage = SecureStorageService();
      var attempts = 0;
      final service = AuthService(
        storage: storage,
        httpClient: _signInServer(
          login: (_) => http.Response(
            '{"next_step":"mfa","mfa_challenge":"challenge-1"}',
            200,
          ),
          mfaVerify: (request) {
            attempts++;
            if (attempts == 1) {
              return http.Response('{"detail":"Invalid code"}', 400);
            }
            return http.Response(_exchangeStep(), 200);
          },
        ),
      );

      await service.login('joao', 'secret', serverUrl: 'https://example.test');
      await expectLater(
        service.verifyMfa('000000'),
        throwsA(
          _hasCode(AppErrorCode.mfaVerificationFailed)
              .having((e) => e.details, 'details', 'Invalid code'),
        ),
      );
      final result = await service.verifyMfa('123456');

      expect(result.step, SignInStep.signedIn);
      expect(attempts, 2);
    });

    test('a dead MFA challenge ends the sign-in', () async {
      final service = AuthService(
        storage: SecureStorageService(),
        httpClient: _signInServer(
          login: (_) => http.Response(
            '{"next_step":"mfa","mfa_challenge":"challenge-1"}',
            200,
          ),
          mfaVerify: (_) => http.Response('{"detail":"Session ended"}', 401),
        ),
      );

      await service.login('joao', 'secret', serverUrl: 'https://example.test');
      await expectLater(
        service.verifyMfa('000000'),
        throwsA(_hasCode(AppErrorCode.mfaSessionMissing)),
      );
      await expectLater(
        service.verifyMfa('123456'),
        throwsA(_hasCode(AppErrorCode.mfaSessionMissing)),
      );
    });

    test('the password-change step finishes the sign-in', () async {
      final storage = SecureStorageService();
      var attempts = 0;
      final service = AuthService(
        storage: storage,
        httpClient: _signInServer(
          login: (_) => http.Response(
            '{"next_step":"password_change",'
            '"password_change_challenge":"change-1"}',
            200,
          ),
          passwordChange: (request) {
            attempts++;
            expect(jsonDecode(request.body), {
              'password_change_challenge': 'change-1',
              'password': attempts == 1 ? 'short' : 'a much better password',
            });
            if (attempts == 1) {
              return http.Response('{"detail":"Password is too short"}', 422);
            }
            return http.Response(_exchangeStep(), 200);
          },
        ),
      );

      final first = await service.login(
        'joao',
        'secret',
        serverUrl: 'https://example.test',
      );
      expect(first.step, SignInStep.passwordChange);
      await expectLater(
        service.changePassword('short'),
        throwsA(
          _hasCode(AppErrorCode.passwordChangeFailed)
              .having((e) => e.details, 'details', 'Password is too short'),
        ),
      );
      final result = await service.changePassword('a much better password');

      expect(result.step, SignInStep.signedIn);
      expect((await _readSession(storage))?.accessToken, 'access-1');
    });

    test('sends the stored device id on every sign-in request', () async {
      final storage = SecureStorageService();
      await storage.setDeviceId('https://example.test', _deviceId);
      final seen = <String, String?>{};
      final service = AuthService(
        storage: storage,
        httpClient: MockClient((request) async {
          seen[request.url.path] = request.headers[ApiConstants.deviceIdHeader];
          final path = request.url.path;
          if (path == ApiEndpoints.defaults.tokenEndpoint) {
            return http.Response(
              '{"next_step":"mfa","mfa_challenge":"challenge-1"}',
              200,
            );
          }
          if (path == ApiEndpoints.defaults.mfaVerifyEndpoint) {
            return http.Response(_exchangeStep(), 200);
          }
          if (path ==
              ApiEndpoints.defaults.sessionTokensEndpoint('session-1')) {
            return http.Response(_tokensStep(), 200);
          }
          return http.Response('{"id":"$_uuid"}', 200);
        }),
      );

      await service.login('joao', 'secret', serverUrl: 'https://example.test');
      await service.verifyMfa('123456');

      expect(seen[ApiEndpoints.defaults.tokenEndpoint], _deviceId);
      expect(seen[ApiEndpoints.defaults.mfaVerifyEndpoint], _deviceId);
      expect(
        seen[ApiEndpoints.defaults.sessionTokensEndpoint('session-1')],
        _deviceId,
      );
    });

    test('cancelSignIn drops the pending step', () async {
      final service = AuthService(
        storage: SecureStorageService(),
        httpClient: _signInServer(
          login: (_) => http.Response(
            '{"next_step":"mfa","mfa_challenge":"challenge-1"}',
            200,
          ),
        ),
      );

      await service.login('joao', 'secret', serverUrl: 'https://example.test');
      service.cancelSignIn();

      await expectLater(
        service.verifyMfa('123456'),
        throwsA(_hasCode(AppErrorCode.mfaSessionMissing)),
      );
    });

    test(
      'a rejected refresh records the failure and the cleared session',
      () async {
        final storage = SecureStorageService();
        await _seedSession(storage);
        final diagnostics = RecordingDiagnostics();
        final service = AuthService(
          storage: storage,
          diagnostics: diagnostics,
          httpClient: MockClient((request) async {
            return http.Response('{"detail":"Session ended"}', 401);
          }),
        );

        expect(await service.refreshToken(), isFalse);

        expect(diagnostics.events, [
          DiagnosticsEvents.httpRequestFailed,
          DiagnosticsEvents.authRefreshFailed,
          DiagnosticsEvents.authSessionCleared,
        ]);
        expect(diagnostics.details[1], {'reason': 'rejected', 'status': 401});
        expect(diagnostics.details[2], {'reason': 'refresh_rejected'});
        expect(diagnostics.details[0]['endpoint'], '/api/v1/auth/refresh');
      },
    );

    test(
      'a transient refresh failure keeps the session and says why',
      () async {
        final storage = SecureStorageService();
        await _seedSession(storage);
        final diagnostics = RecordingDiagnostics();
        final service = AuthService(
          storage: storage,
          diagnostics: diagnostics,
          httpClient: MockClient((request) async {
            return http.Response('unavailable', 503);
          }),
        );

        expect(await service.refreshToken(), isFalse);

        expect(diagnostics.single(DiagnosticsEvents.authRefreshFailed), {
          'reason': 'server_error',
          'status': 503,
        });
        expect(
          diagnostics.events,
          isNot(contains(DiagnosticsEvents.authSessionCleared)),
        );
        expect(await _readSession(storage), isNotNull);
      },
    );

    test('refreshToken stores rotated tokens on success', () async {
      final storage = SecureStorageService();
      await _seedSession(storage);
      final service = AuthService(
        storage: storage,
        httpClient: MockClient((request) async {
          expect(request.url.path, ApiEndpoints.defaults.refreshEndpoint);
          expect(request.headers['Authorization'], isNull);
          expect(jsonDecode(request.body), {'refresh_token': 'refresh-1'});
          return http.Response(
            '{"access_token":"access-2","refresh_token":"refresh-2","session_id":"session-2","expires_in":3600}',
            200,
          );
        }),
      );

      final refreshed = await service.refreshToken();

      expect(refreshed, isTrue);
      final session = await _readSession(storage);
      expect(session?.accessToken, 'access-2');
      expect(session?.refreshToken, 'refresh-2');
      expect(session?.sessionId, 'session-2');
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
      await _seedSession(storage);
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
      final session = await _readSession(storage);
      expect(session?.accessToken, 'access-1');
      expect(session?.refreshToken, 'refresh-1');
    });

    test('refreshToken keeps the session on a 5xx server error', () async {
      final storage = SecureStorageService();
      await _seedSession(storage);
      final service = AuthService(
        storage: storage,
        httpClient: MockClient((request) async {
          return http.Response('{"detail":"temporarily down"}', 503);
        }),
      );

      final refreshed = await service.refreshToken();

      expect(refreshed, isFalse);
      final session = await _readSession(storage);
      expect(session?.accessToken, 'access-1');
      expect(session?.refreshToken, 'refresh-1');
    });

    test(
      'concurrent refreshToken calls trigger a single network round-trip',
      () async {
        final storage = SecureStorageService();
        await _seedSession(storage);
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
        expect((await _readSession(storage))?.refreshToken, 'refresh-2');
      },
    );

    test('stale refresh cannot overwrite a replacement login', () async {
      final storage = SecureStorageService();
      final store = AuthSessionStore(storage: storage);
      await _seedSession(storage, origin: 'https://a.example');
      final requestStarted = Completer<void>();
      final response = Completer<http.Response>();
      final service = AuthService(
        storage: storage,
        sessionStore: store,
        httpClient: MockClient((request) async {
          requestStarted.complete();
          return response.future;
        }),
      );

      final refresh = service.refreshToken();
      await requestStarted.future;
      await _seedSession(
        storage,
        store: store,
        origin: 'https://b.example',
        accessToken: 'access-b',
        refreshToken: 'refresh-b',
        sessionId: 'session-b',
        accountId: '43',
      );
      response.complete(
        http.Response(
          '{"access_token":"late-a","refresh_token":"late-refresh-a",'
          '"session_id":"late-session-a","expires_in":3600}',
          200,
        ),
      );

      expect(await refresh, isFalse);
      final current = await store.readSession();
      expect(current?.origin, 'https://b.example');
      expect(current?.accessToken, 'access-b');
    });

    test('refreshToken can run again after an in-flight refresh completes', () async {
      final storage = SecureStorageService();
      await _seedSession(storage);
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
    });

    test('logout succeeds when the server confirms the logout', () async {
      final storage = SecureStorageService();
      await _seedSession(storage);
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
      expect(await _readSession(storage), isNull);
    });

    test('stale logout cannot clear a replacement login', () async {
      final storage = SecureStorageService();
      final store = AuthSessionStore(storage: storage);
      await _seedSession(storage, store: store, origin: 'https://a.example');
      final requestStarted = Completer<void>();
      final response = Completer<http.Response>();
      final service = AuthService(
        storage: storage,
        sessionStore: store,
        httpClient: MockClient((request) async {
          requestStarted.complete();
          return response.future;
        }),
      );

      final logout = service.logout();
      await requestStarted.future;
      await _seedSession(
        storage,
        store: store,
        origin: 'https://b.example',
        accessToken: 'access-b',
        refreshToken: 'refresh-b',
        sessionId: 'session-b',
        accountId: '43',
      );
      response.complete(http.Response('', 200));

      expect(await logout, isTrue);
      final current = await store.readSession();
      expect(current?.origin, 'https://b.example');
      expect(current?.accessToken, 'access-b');
    });

    test('logout clears a refresh that completed first', () async {
      final storage = SecureStorageService();
      final store = AuthSessionStore(storage: storage);
      await _seedSession(storage, store: store);
      final refreshStarted = Completer<void>();
      final refreshResponse = Completer<http.Response>();
      var logoutCalls = 0;
      final service = AuthService(
        storage: storage,
        sessionStore: store,
        httpClient: MockClient((request) async {
          if (request.url.path == ApiEndpoints.defaults.refreshEndpoint) {
            refreshStarted.complete();
            return refreshResponse.future;
          }
          logoutCalls++;
          return http.Response('', 200);
        }),
      );

      final refresh = service.refreshToken();
      await refreshStarted.future;
      final logout = service.logout();
      refreshResponse.complete(
        http.Response(
          '{"access_token":"access-2","refresh_token":"refresh-2",'
          '"session_id":"session-2","expires_in":3600}',
          200,
        ),
      );

      expect(await refresh, isTrue);
      expect(await logout, isTrue);
      expect(logoutCalls, 1);
      expect(await store.readSession(), isNull);
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
      await _seedSession(storage);
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
        await _seedSession(storage, refreshToken: '', expiresInSeconds: -60);
        final service = AuthService(
          storage: storage,
          httpClient: MockClient((request) async {
            fail('No refresh should run without a refresh token.');
          }),
        );

        expect(await service.isAuthenticated(), isFalse);
        expect(await _readSession(storage), isNull);
      },
    );

    test('isAuthenticated refreshes an expiring token', () async {
      final storage = SecureStorageService();
      await _seedSession(storage, expiresInSeconds: 30);
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
      expect((await _readSession(storage))?.accessToken, 'access-2');
    });

    test('isAuthenticated clears the session when refresh fails', () async {
      final storage = SecureStorageService();
      await _seedSession(storage, expiresInSeconds: -60);
      final service = AuthService(
        storage: storage,
        httpClient: MockClient((request) async {
          return http.Response('{"detail":"Expired"}', 401);
        }),
      );

      expect(await service.isAuthenticated(), isFalse);
      expect(await _readSession(storage), isNull);
    });

    test(
      'refreshToken reads server URL and refresh token from session store',
      () async {
        // sessionStorage is the session store's backing; rawStorage is the
        // _storage field — they are distinct to prove the session store path
        // is used, not the raw storage path.
        final sessionStorage = SecureStorageService();
        final sessionStore = AuthSessionStore(storage: sessionStorage);
        await _seedSession(
          sessionStorage,
          store: sessionStore,
          origin: 'https://session.test',
          refreshToken: 'refresh-from-store',
        );
        final rawStorage = SecureStorageService();
        final service = AuthService(
          storage: rawStorage,
          sessionStore: sessionStore,
          httpClient: MockClient((request) async {
            expect(request.url.origin, 'https://session.test');
            expect(request.headers[ApiConstants.authorizationHeader], isNull);
            expect(jsonDecode(request.body), {
              'refresh_token': 'refresh-from-store',
            });
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
        final sessionStore = AuthSessionStore(storage: sessionStorage);
        await _seedSession(
          sessionStorage,
          store: sessionStore,
          origin: 'https://session.test',
          refreshToken: 'refresh-from-store',
        );
        final rawStorage = SecureStorageService();
        final service = AuthService(
          storage: rawStorage,
          sessionStore: sessionStore,
          httpClient: MockClient((request) async {
            expect(request.url.origin, 'https://session.test');
            expect(request.headers[ApiConstants.authorizationHeader], isNull);
            expect(jsonDecode(request.body), {
              'refresh_token': 'refresh-from-store',
            });
            return http.Response('{"idp_logout_url":null}', 200);
          }),
        );

        final serverLogoutSucceeded = await service.logout();

        expect(serverLogoutSucceeded, isTrue);
      },
    );

    test('rejects http serverUrl to the cloud origin before making any request', () async {
      final service = AuthService(
        storage: SecureStorageService(),
        httpClient: MockClient((request) async {
          fail(
            'No HTTP request should be made with http:// to the cloud origin.',
          );
        }),
        config: const AppConfig(cloudBaseUrl: 'https://example.test'),
      );

      await expectLater(
        service.login('joao', 'secret', serverUrl: 'http://example.test'),
        throwsA(
          isA<AppException>().having(
            (e) => e.code,
            'code',
            AppErrorCode.insecureTransportNotAllowed,
          ),
        ),
      );
    });

    test('uses custom apiBasePath from ApiEndpoints', () async {
      const v2Config = AppConfig(apiBasePath: '/api/v2');
      final requests = <http.Request>[];
      final service = AuthService(
        storage: SecureStorageService(),
        httpClient: MockClient((request) async {
          requests.add(request);
          if (request.url.path == '/api/v2/auth/login') {
            return http.Response(_exchangeStep(), 200);
          }
          if (request.url.path == '/api/v2/auth/sessions/session-1/tokens') {
            return http.Response(_tokensStep(), 200);
          }
          if (request.url.path == '/api/v2/profile') {
            return http.Response('{"id":"$_uuid"}', 200);
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

const _uuid = '7c9e6679-7425-40de-944b-e07fc1f90ae7';
const _deviceId = 'aBcDeFgHiJkLmNoPqRsTuVwXyZ0123456789-_abcde';

String _exchangeStep() =>
    '{"next_step":"exchange","session_id":"session-1","device_id":"$_deviceId"}';

String _tokensStep() =>
    '{"next_step":"tokens","access_token":"access-1",'
    '"refresh_token":"refresh-1","session_id":"session-2",'
    '"token_type":"bearer","expires_in":3600,'
    '"refresh_token_expires_in":604800,"device_id":null}';

TypeMatcher<AppException> _hasCode(AppErrorCode code) =>
    isA<AppException>().having((e) => e.code, 'code', code);

/// A server for one password sign-in: [login] answers `POST /auth/login`
/// (an `exchange` step by default), [mfaVerify] and [passwordChange] their
/// steps, and the exchange and profile reads answer a signed-in session.
MockClient _signInServer({
  String origin = 'https://example.test',
  http.Response Function(http.Request request)? login,
  http.Response Function(http.Request request)? mfaVerify,
  http.Response Function(http.Request request)? passwordChange,
}) {
  return MockClient((request) async {
    expect(request.url.origin, origin);
    final path = request.url.path;
    const endpoints = ApiEndpoints.defaults;
    if (path == endpoints.tokenEndpoint) {
      return (login ?? (_) => http.Response(_exchangeStep(), 200))(request);
    }
    if (path == endpoints.mfaVerifyEndpoint && mfaVerify != null) {
      return mfaVerify(request);
    }
    if (path == endpoints.passwordChangeEndpoint && passwordChange != null) {
      return passwordChange(request);
    }
    if (path == endpoints.sessionTokensEndpoint('session-1')) {
      return http.Response(_tokensStep(), 200);
    }
    if (path == endpoints.profileEndpoint) {
      return http.Response('{"id":"$_uuid"}', 200);
    }
    fail('Unexpected request to ${request.url}');
  });
}

Future<void> _seedSession(
  SecureStorageService storage, {
  AuthSessionStore? store,
  String origin = 'https://example.test',
  String accessToken = 'access-1',
  String refreshToken = 'refresh-1',
  String sessionId = 'session-1',
  String accountId = '42',
  int expiresInSeconds = 3600,
}) {
  return (store ?? AuthSessionStore(storage: storage)).saveSession(
    origin: origin,
    accessToken: accessToken,
    refreshToken: refreshToken,
    sessionId: sessionId,
    accountId: accountId,
    expiresInSeconds: expiresInSeconds,
  );
}

Future<AuthSession?> _readSession(SecureStorageService storage) {
  return AuthSessionStore(storage: storage).readSession();
}

/// Fake [FlutterSecureStorage] whose reads fail but deletes succeed.
class _UnreadableStorage extends Fake implements FlutterSecureStorage {
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
    throw Exception('keystore unavailable');
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
  }) async {}
}
