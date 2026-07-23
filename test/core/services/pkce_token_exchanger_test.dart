import 'package:endurain/core/config/api_endpoints.dart';
import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/services/auth_session_store.dart';
import 'package:endurain/core/services/base_http_client.dart';
import 'package:endurain/core/services/pkce_token_exchanger.dart';
import 'package:endurain/core/services/secure_storage_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  const tokensBody =
      '{"access_token":"at","refresh_token":"rt",'
      '"session_id":"sid","expires_in":3600}';

  PkceTokenExchanger makeExchanger(
    SecureStorageService storage,
    http.Client client,
  ) => PkceTokenExchanger(
    sessionStore: AuthSessionStore(storage: storage),
    http: BaseHttpClient(httpClient: client),
    // No real delays in tests.
    retryDelay: (_) async {},
  );

  group('PkceTokenExchanger profile fetch', () {
    test(
      'retries a transient profile-fetch failure and still logs in',
      () async {
        final storage = SecureStorageService();
        var profileAttempts = 0;
        final client = MockClient((request) async {
          if (request.method == 'POST' &&
              request.url.path.endsWith('/tokens')) {
            return http.Response(tokensBody, 200);
          }
          if (request.url.path == ApiEndpoints.defaults.profileEndpoint) {
            profileAttempts++;
            // Fail the first two attempts with a transient 503, then succeed.
            if (profileAttempts < 3) {
              return http.Response('{"detail":"temporarily down"}', 503);
            }
            return http.Response('{"id":42}', 200);
          }
          return http.Response('{"detail":"unexpected"}', 404);
        });

        final result = await makeExchanger(storage, client).exchange(
          serverUrl: 'https://example.test',
          sessionId: 'session-1',
          verifier: 'verifier',
          failureCode: AppErrorCode.tokenExchangeFailed,
        );

        expect(result.success, isTrue);
        expect(profileAttempts, 3);
        final session = await AuthSessionStore(storage: storage).readSession();
        expect(session?.accessToken, 'at');
        // The stable profile id is origin-qualified from the server account id.
        expect(session?.accountId, '42');
        expect(session?.profileId, 'https://example.test#42');
      },
    );

    test(
      'does not save a session when the profile fetch keeps failing',
      () async {
        final storage = SecureStorageService();
        var profileAttempts = 0;
        final client = MockClient((request) async {
          if (request.method == 'POST' &&
              request.url.path.endsWith('/tokens')) {
            return http.Response(tokensBody, 200);
          }
          if (request.url.path == ApiEndpoints.defaults.profileEndpoint) {
            profileAttempts++;
            return http.Response('{"detail":"down"}', 503);
          }
          return http.Response('{"detail":"unexpected"}', 404);
        });

        await expectLater(
          makeExchanger(storage, client).exchange(
            serverUrl: 'https://example.test',
            sessionId: 'session-1',
            verifier: 'verifier',
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
