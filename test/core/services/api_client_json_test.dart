import 'dart:convert';

import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/services/api_client.dart';
import 'package:endurain/core/services/auth_service.dart';
import 'package:endurain/core/services/auth_session_store.dart';
import 'package:endurain/core/services/base_http_client.dart';
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

  group('ApiClient authenticated JSON verbs', () {
    test('getJsonObject attaches bearer + client headers and decodes the '
        'object', () async {
      final storage = SecureStorageService();
      await _seedSession(storage);
      final requests = <http.Request>[];
      final client = ApiClient(
        storage: storage,
        authService: AuthService(storage: storage),
        baseClient: BaseHttpClient(
          httpClient: MockClient((request) async {
            requests.add(request);
            return http.Response('{"id":7,"name":"ride"}', 200);
          }),
        ),
      );

      final data = await client.getJsonObject(
        '/api/v1/activities/7',
        failureCode: AppErrorCode.activityUploadFailed,
      );

      expect(data['id'], 7);
      expect(data['name'], 'ride');
      expect(requests, hasLength(1));
      expect(requests.single.method, 'GET');
      expect(
        requests.single.url.toString(),
        'https://example.test/api/v1/activities/7',
      );
      expect(requests.single.headers['Authorization'], 'Bearer access-1');
      expect(requests.single.headers['X-Client-Type'], 'mobile');
    });

    test('getJson decodes a JSON list', () async {
      final storage = SecureStorageService();
      await _seedSession(storage);
      final client = ApiClient(
        storage: storage,
        authService: AuthService(storage: storage),
        baseClient: BaseHttpClient(
          httpClient: MockClient((request) async {
            return http.Response('[1,2,3]', 200);
          }),
        ),
      );

      final data = await client.getJson(
        '/api/v1/activities',
        failureCode: AppErrorCode.activityUploadFailed,
      );

      expect(data, [1, 2, 3]);
    });

    test(
      'postJsonObject sends an encoded body with a JSON content type',
      () async {
        final storage = SecureStorageService();
        await _seedSession(storage);
        final requests = <http.Request>[];
        final client = ApiClient(
          storage: storage,
          authService: AuthService(storage: storage),
          baseClient: BaseHttpClient(
            httpClient: MockClient((request) async {
              requests.add(request);
              return http.Response('{"created":true}', 200);
            }),
          ),
        );

        final data = await client.postJsonObject(
          '/api/v1/activities',
          body: {'name': 'morning run'},
          failureCode: AppErrorCode.activityUploadFailed,
        );

        expect(data['created'], true);
        expect(requests.single.method, 'POST');
        expect(
          requests.single.headers['Content-Type'],
          startsWith('application/json'),
        );
        expect(jsonDecode(requests.single.body), {'name': 'morning run'});
      },
    );

    test('putJsonObject issues a PUT with the encoded body', () async {
      final storage = SecureStorageService();
      await _seedSession(storage);
      final requests = <http.Request>[];
      final client = ApiClient(
        storage: storage,
        authService: AuthService(storage: storage),
        baseClient: BaseHttpClient(
          httpClient: MockClient((request) async {
            requests.add(request);
            return http.Response('{"updated":true}', 200);
          }),
        ),
      );

      final data = await client.putJsonObject(
        '/api/v1/activities/7',
        body: {'name': 'renamed'},
        failureCode: AppErrorCode.activityUploadFailed,
      );

      expect(data['updated'], true);
      expect(requests.single.method, 'PUT');
      expect(jsonDecode(requests.single.body), {'name': 'renamed'});
    });

    test('deleteJson succeeds on 204 with no body', () async {
      final storage = SecureStorageService();
      await _seedSession(storage);
      final requests = <http.Request>[];
      final client = ApiClient(
        storage: storage,
        authService: AuthService(storage: storage),
        baseClient: BaseHttpClient(
          httpClient: MockClient((request) async {
            requests.add(request);
            return http.Response('', 204);
          }),
        ),
      );

      await client.deleteJson(
        '/api/v1/activities/7',
        failureCode: AppErrorCode.activityUploadFailed,
      );

      expect(requests.single.method, 'DELETE');
    });

    test('refreshes the token and retries once after a 401', () async {
      final storage = SecureStorageService();
      await _seedSession(storage);
      final authHeaders = <String?>[];
      final authService = AuthService(
        storage: storage,
        httpClient: MockClient((request) async {
          expect(request.url.path, '/api/v1/auth/refresh');
          return http.Response(
            jsonEncode({
              'access_token': 'access-2',
              'refresh_token': 'refresh-2',
              'session_id': 'session-2',
              'expires_in': 3600,
            }),
            200,
          );
        }),
      );
      final client = ApiClient(
        storage: storage,
        authService: authService,
        baseClient: BaseHttpClient(
          httpClient: MockClient((request) async {
            authHeaders.add(request.headers['Authorization']);
            if (authHeaders.length == 1) {
              return http.Response('{"detail":"expired"}', 401);
            }
            return http.Response('{"id":7}', 200);
          }),
        ),
      );

      final data = await client.getJsonObject(
        '/api/v1/activities/7',
        failureCode: AppErrorCode.activityUploadFailed,
      );

      expect(data['id'], 7);
      expect(authHeaders, ['Bearer access-1', 'Bearer access-2']);
      expect((await _readSession(storage))?.accessToken, 'access-2');
    });

    test('throws sessionExpired when a 401 persists after refresh', () async {
      final storage = SecureStorageService();
      await _seedSession(storage);
      final authService = AuthService(
        storage: storage,
        httpClient: MockClient((request) async {
          return http.Response(
            jsonEncode({
              'access_token': 'access-2',
              'refresh_token': 'refresh-2',
              'session_id': 'session-2',
              'expires_in': 3600,
            }),
            200,
          );
        }),
      );
      final client = ApiClient(
        storage: storage,
        authService: authService,
        baseClient: BaseHttpClient(
          httpClient: MockClient((request) async {
            return http.Response('{"detail":"expired"}', 401);
          }),
        ),
      );

      await expectLater(
        client.getJsonObject(
          '/api/v1/activities/7',
          failureCode: AppErrorCode.activityUploadFailed,
        ),
        throwsA(
          isA<AppException>().having(
            (e) => e.code,
            'code',
            AppErrorCode.sessionExpired,
          ),
        ),
      );
    });

    test('throws transientAuthUnavailable when the post-401 refresh fails '
        'transiently', () async {
      final storage = SecureStorageService();
      await _seedSession(storage);
      final authService = AuthService(
        storage: storage,
        httpClient: MockClient((request) async {
          // 5xx keeps the session (transient) rather than clearing it.
          return http.Response('{"detail":"unavailable"}', 503);
        }),
      );
      final client = ApiClient(
        storage: storage,
        authService: authService,
        baseClient: BaseHttpClient(
          httpClient: MockClient((request) async {
            return http.Response('{"detail":"expired"}', 401);
          }),
        ),
      );

      await expectLater(
        client.getJsonObject(
          '/api/v1/activities/7',
          failureCode: AppErrorCode.activityUploadFailed,
        ),
        throwsA(
          isA<AppException>().having(
            (e) => e.code,
            'code',
            AppErrorCode.transientAuthUnavailable,
          ),
        ),
      );
      expect((await _readSession(storage))?.accessToken, 'access-1');
    });

    test('throws notAuthenticated without a committed session', () async {
      final storage = SecureStorageService();
      final client = ApiClient(
        storage: storage,
        authService: AuthService(storage: storage),
        baseClient: BaseHttpClient(
          httpClient: MockClient((request) async {
            fail('No request should be made without a session.');
          }),
        ),
      );

      await expectLater(
        client.getJsonObject(
          '/api/v1/activities/7',
          failureCode: AppErrorCode.activityUploadFailed,
        ),
        throwsA(
          isA<AppException>().having(
            (e) => e.code,
            'code',
            AppErrorCode.notAuthenticated,
          ),
        ),
      );
    });

    test('surfaces the failure code on a non-200 response', () async {
      final storage = SecureStorageService();
      await _seedSession(storage);
      final client = ApiClient(
        storage: storage,
        authService: AuthService(storage: storage),
        baseClient: BaseHttpClient(
          httpClient: MockClient((request) async {
            return http.Response('{"detail":"nope"}', 500);
          }),
        ),
      );

      await expectLater(
        client.getJsonObject(
          '/api/v1/activities/7',
          failureCode: AppErrorCode.fetchServerSettingsFailed,
        ),
        throwsA(
          isA<AppException>()
              .having(
                (e) => e.code,
                'code',
                AppErrorCode.fetchServerSettingsFailed,
              )
              .having((e) => e.details, 'details', 'nope'),
        ),
      );
    });

    test('rejects a request scoped to another login profile before the '
        'network call', () async {
      final storage = SecureStorageService();
      await _seedSession(storage, accountId: '42');
      final client = ApiClient(
        storage: storage,
        authService: AuthService(storage: storage),
        baseClient: BaseHttpClient(
          httpClient: MockClient((request) async {
            fail('A profile mismatch must be rejected before any request.');
          }),
        ),
      );

      await expectLater(
        client.getJsonObject(
          '/api/v1/activities/7',
          failureCode: AppErrorCode.activityUploadFailed,
          expectedProfileId: '99',
        ),
        throwsA(
          isA<AppException>().having(
            (e) => e.code,
            'code',
            AppErrorCode.notAuthenticated,
          ),
        ),
      );
    });
  });
}

Future<void> _seedSession(
  SecureStorageService storage, {
  String origin = 'https://example.test',
  String accountId = '42',
  int expiresInSeconds = 3600,
}) {
  return AuthSessionStore(storage: storage).saveSession(
    origin: origin,
    accessToken: 'access-1',
    refreshToken: 'refresh-1',
    sessionId: 'session-1',
    accountId: accountId,
    expiresInSeconds: expiresInSeconds,
  );
}

Future<dynamic> _readSession(SecureStorageService storage) {
  return AuthSessionStore(storage: storage).readSession();
}
