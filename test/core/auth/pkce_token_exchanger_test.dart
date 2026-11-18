import 'dart:convert';

import 'package:endurain/core/auth/auth_session_store.dart';
import 'package:endurain/core/auth/pkce_token_exchanger.dart';
import 'package:endurain/core/auth/secure_storage_service.dart';
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

  const tokens = <String, dynamic>{
    'next_step': 'tokens',
    'access_token': 'at',
    'refresh_token': 'rt',
    'session_id': 'sid',
    'expires_in': 3600,
  };

  PkceTokenExchanger makeExchanger(
    SecureStorageService storage,
    http.Client client,
  ) => PkceTokenExchanger(
    sessionStore: AuthSessionStore(storage: storage),
    http: BaseHttpClient(httpClient: client),
    // No real delays in tests.
    retryDelay: (_) async {},
  );

  group('PkceTokenExchanger.exchange', () {
    test('posts the verifier and device id and returns the step', () async {
      final client = MockClient((request) async {
        expect(
          request.url.path,
          ApiEndpoints.defaults.sessionTokensEndpoint('session-1'),
        );
        expect(jsonDecode(request.body), {'code_verifier': 'verifier'});
        expect(request.headers[ApiConstants.deviceIdHeader], 'device-1');
        expect(request.headers[ApiConstants.clientTypeHeader], 'mobile');
        return http.Response('{"next_step":"mfa","mfa_challenge":"c"}', 200);
      });

      final step = await makeExchanger(SecureStorageService(), client).exchange(
        serverUrl: 'https://example.test',
        sessionId: 'session-1',
        verifier: 'verifier',
        deviceId: 'device-1',
        failureCode: AppErrorCode.tokenExchangeFailed,
      );

      expect(step['next_step'], 'mfa');
    });
  });

  group('PkceTokenExchanger.saveTokens', () {
    test('retries a transient profile-fetch failure and still saves', () async {
      final storage = SecureStorageService();
      var profileAttempts = 0;
      final client = MockClient((request) async {
        expect(request.url.path, ApiEndpoints.defaults.profileEndpoint);
        profileAttempts++;
        // Fail the first two attempts with a transient 503, then succeed.
        if (profileAttempts < 3) {
          return http.Response('{"detail":"temporarily down"}', 503);
        }
        return http.Response('{"id":42}', 200);
      });

      await makeExchanger(storage, client).saveTokens(
        serverUrl: 'https://example.test',
        body: tokens,
        failureCode: AppErrorCode.tokenExchangeFailed,
      );

      expect(profileAttempts, 3);
      final session = await AuthSessionStore(storage: storage).readSession();
      expect(session?.accessToken, 'at');
      // The stable profile id is origin-qualified from the server account id.
      expect(session?.accountId, '42');
      expect(session?.profileId, 'https://example.test#42');
    });

    test('accepts the UUID account id of a v0.21 server', () async {
      final storage = SecureStorageService();
      final client = MockClient(
        (request) async =>
            http.Response('{"id":"7c9e6679-7425-40de-944b-e07fc1f90ae7"}', 200),
      );

      await makeExchanger(storage, client).saveTokens(
        serverUrl: 'https://example.test',
        body: tokens,
        failureCode: AppErrorCode.tokenExchangeFailed,
      );

      final session = await AuthSessionStore(storage: storage).readSession();
      expect(session?.accountId, '7c9e6679-7425-40de-944b-e07fc1f90ae7');
      expect(
        session?.profileId,
        'https://example.test#7c9e6679-7425-40de-944b-e07fc1f90ae7',
      );
    });

    test(
      'does not save a session when the profile fetch keeps failing',
      () async {
        final storage = SecureStorageService();
        var profileAttempts = 0;
        final client = MockClient((request) async {
          profileAttempts++;
          return http.Response('{"detail":"down"}', 503);
        });

        await expectLater(
          makeExchanger(storage, client).saveTokens(
            serverUrl: 'https://example.test',
            body: tokens,
            failureCode: AppErrorCode.tokenExchangeFailed,
          ),
          throwsA(
            isA<AppException>().having(
              (e) => e.code,
              'code',
              AppErrorCode.tokenExchangeFailed,
            ),
          ),
        );

        // All attempts were exhausted, and the freshly-issued tokens were not
        // committed because the profile id could not be resolved.
        expect(profileAttempts, 3);
        expect(await AuthSessionStore(storage: storage).readSession(), isNull);
      },
    );
  });
}
