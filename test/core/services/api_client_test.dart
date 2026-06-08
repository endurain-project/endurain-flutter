import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';
import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/services/api_client.dart';
import 'package:endurain/core/services/auth_service.dart';
import 'package:endurain/core/services/auth_session_store.dart';
import 'package:endurain/core/services/multipart_upload_adapter.dart';
import 'package:endurain/core/services/secure_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  group('ApiClient JSON helpers', () {
    test(
      'returns decoded object for successful authenticated requests',
      () async {
        final storage = SecureStorageService();
        await storage.setServerUrl('https://example.test');
        await storage.setAccessToken('access-1');

        final client = ApiClient(
          storage: storage,
          authService: AuthService(storage: storage),
          httpClient: MockClient((request) async {
            expect(request.url.toString(), 'https://example.test/api/profile');
            expect(request.headers['Authorization'], 'Bearer access-1');
            return http.Response('{"name":"Endurain"}', 200);
          }),
        );

        final data = await client.getJsonObject(
          '/api/profile',
          failureCode: AppErrorCode.loginFailed,
        );

        expect(data, {'name': 'Endurain'});
      },
    );

    test('maps non-success responses to typed failures', () async {
      final storage = SecureStorageService();
      await storage.setServerUrl('https://example.test');
      await storage.setAccessToken('access-1');

      final client = ApiClient(
        storage: storage,
        authService: AuthService(storage: storage),
        httpClient: MockClient((request) async {
          return http.Response('{"detail":"Profile unavailable"}', 503);
        }),
      );

      expect(
        () => client.getJsonObject(
          '/api/profile',
          failureCode: AppErrorCode.fetchServerSettingsFailed,
        ),
        throwsA(
          isA<AppException>()
              .having(
                (exception) => exception.code,
                'code',
                AppErrorCode.fetchServerSettingsFailed,
              )
              .having(
                (exception) => exception.details,
                'details',
                'Profile unavailable',
              ),
        ),
      );
    });

    test('clears tokens when pre-request refresh fails', () async {
      final storage = SecureStorageService();
      await storage.setServerUrl('https://example.test');
      await storage.setAccessToken('access-1');
      await storage.setRefreshToken('refresh-1');
      await storage.setSessionId('session-1');
      await storage.setAccessTokenExpiresAt(DateTime.now().toUtc());
      final authService = AuthService(
        storage: storage,
        httpClient: MockClient((request) async {
          expect(request.url.path, '/api/v1/auth/refresh');
          return http.Response('{"detail":"Expired refresh token"}', 401);
        }),
      );
      final client = ApiClient(
        storage: storage,
        authService: authService,
        httpClient: MockClient((request) async {
          fail('API request should not run without a refreshed access token');
        }),
      );

      await expectLater(
        client.getJsonObject(
          '/api/profile',
          failureCode: AppErrorCode.loginFailed,
        ),
        throwsA(
          isA<AppException>().having(
            (exception) => exception.code,
            'code',
            AppErrorCode.notAuthenticated,
          ),
        ),
      );
      expect(await storage.getAccessToken(), isNull);
      expect(await storage.getRefreshToken(), isNull);
      expect(await storage.getSessionId(), isNull);
      expect(await storage.getAccessTokenExpiresAt(), isNull);
    });

    test('clears tokens when retry refresh after 401 fails', () async {
      final storage = SecureStorageService();
      await storage.setServerUrl('https://example.test');
      await storage.setAccessToken('access-1');
      await storage.setRefreshToken('refresh-1');
      await storage.setSessionId('session-1');
      await storage.setAccessTokenExpiresAt(
        DateTime.now().toUtc().add(const Duration(hours: 1)),
      );
      final authService = AuthService(
        storage: storage,
        httpClient: MockClient((request) async {
          expect(request.url.path, '/api/v1/auth/refresh');
          return http.Response('{"detail":"Expired refresh token"}', 401);
        }),
      );
      final client = ApiClient(
        storage: storage,
        authService: authService,
        httpClient: MockClient((request) async {
          expect(request.url.path, '/api/profile');
          return http.Response('{"detail":"Expired access token"}', 401);
        }),
      );

      await expectLater(
        client.getJsonObject(
          '/api/profile',
          failureCode: AppErrorCode.loginFailed,
        ),
        throwsA(
          isA<AppException>().having(
            (exception) => exception.code,
            'code',
            AppErrorCode.sessionExpired,
          ),
        ),
      );
      expect(await storage.getAccessToken(), isNull);
      expect(await storage.getRefreshToken(), isNull);
      expect(await storage.getSessionId(), isNull);
      expect(await storage.getAccessTokenExpiresAt(), isNull);
    });
  });

  group('ApiClient uploads', () {
    test('uses injected multipart adapter with auth headers', () async {
      final storage = SecureStorageService();
      await storage.setServerUrl('https://example.test');
      await storage.setAccessToken('access-1');
      final uploadAdapter = _FakeMultipartUploadAdapter();
      final client = ApiClient(
        storage: storage,
        authService: AuthService(storage: storage),
        uploadAdapter: uploadAdapter,
      );

      await client.uploadFile('/api/files', '/tmp/activity.fit', 'file');

      expect(uploadAdapter.url.toString(), 'https://example.test/api/files');
      expect(uploadAdapter.filePath, '/tmp/activity.fit');
      expect(uploadAdapter.fieldName, 'file');
      expect(uploadAdapter.headers['Authorization'], 'Bearer access-1');
      expect(uploadAdapter.headers['X-Client-Type'], 'mobile');
    });

    test('refreshes token and retries once after upload 401', () async {
      final storage = SecureStorageService();
      await storage.setServerUrl('https://example.test');
      await storage.setAccessToken('access-1');
      await storage.setRefreshToken('refresh-1');
      await storage.setSessionId('session-1');
      await storage.setAccessTokenExpiresAt(
        DateTime.now().toUtc().add(const Duration(hours: 1)),
      );
      final uploadAdapter = _FakeMultipartUploadAdapter(
        statusCodes: [401, 201],
      );
      final authService = AuthService(
        storage: storage,
        httpClient: MockClient((request) async {
          expect(request.url.path, '/api/v1/auth/refresh');
          expect(request.headers['Authorization'], 'Bearer refresh-1');
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
        uploadAdapter: uploadAdapter,
      );

      final response = await client.uploadFile(
        '/api/files',
        '/tmp/activity.gpx',
        'file',
      );

      expect(response.statusCode, 201);
      expect(uploadAdapter.authorizationHeaders, [
        'Bearer access-1',
        'Bearer access-2',
      ]);
      expect(await storage.getAccessToken(), 'access-2');
    });

    test('throws when uploading without a configured server URL', () async {
      final storage = SecureStorageService();
      await storage.setAccessToken('access-1');
      final client = ApiClient(
        storage: storage,
        authService: AuthService(storage: storage),
        uploadAdapter: _FakeMultipartUploadAdapter(),
      );

      await expectLater(
        client.uploadFile('/api/files', '/tmp/activity.gpx', 'file'),
        throwsA(
          isA<AppException>().having(
            (exception) => exception.code,
            'code',
            AppErrorCode.serverUrlNotConfigured,
          ),
        ),
      );
    });

    test('throws when uploading without an access token', () async {
      final storage = SecureStorageService();
      await storage.setServerUrl('https://example.test');
      final client = ApiClient(
        storage: storage,
        authService: AuthService(storage: storage),
        uploadAdapter: _FakeMultipartUploadAdapter(),
      );

      await expectLater(
        client.uploadFile('/api/files', '/tmp/activity.gpx', 'file'),
        throwsA(
          isA<AppException>().having(
            (exception) => exception.code,
            'code',
            AppErrorCode.notAuthenticated,
          ),
        ),
      );
    });

    test('throws sessionExpired when upload refresh after 401 fails', () async {
      final storage = SecureStorageService();
      await storage.setServerUrl('https://example.test');
      await storage.setAccessToken('access-1');
      await storage.setRefreshToken('refresh-1');
      await storage.setAccessTokenExpiresAt(
        DateTime.now().toUtc().add(const Duration(hours: 1)),
      );
      final authService = AuthService(
        storage: storage,
        httpClient: MockClient((request) async {
          expect(request.url.path, '/api/v1/auth/refresh');
          return http.Response('{"detail":"Expired"}', 401);
        }),
      );
      final client = ApiClient(
        storage: storage,
        authService: authService,
        uploadAdapter: _FakeMultipartUploadAdapter(statusCodes: [401]),
      );

      await expectLater(
        client.uploadFile('/api/files', '/tmp/activity.gpx', 'file'),
        throwsA(
          isA<AppException>().having(
            (exception) => exception.code,
            'code',
            AppErrorCode.sessionExpired,
          ),
        ),
      );
    });
  });

  group('ApiClient request lifecycle', () {
    test('refreshes an expiring token before sending the request', () async {
      final storage = SecureStorageService();
      await storage.setServerUrl('https://example.test');
      await storage.setAccessToken('access-1');
      await storage.setRefreshToken('refresh-1');
      await storage.setAccessTokenExpiresAt(
        DateTime.now().toUtc().add(const Duration(seconds: 30)),
      );
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
        httpClient: MockClient((request) async {
          expect(request.headers['Authorization'], 'Bearer access-2');
          return http.Response('{"ok":true}', 200);
        }),
      );

      final data = await client.getJsonObject(
        '/api/profile',
        failureCode: AppErrorCode.loginFailed,
      );

      expect(data, {'ok': true});
    });

    test('refreshes and retries once after a 401 response', () async {
      final storage = SecureStorageService();
      await storage.setServerUrl('https://example.test');
      await storage.setAccessToken('access-1');
      await storage.setRefreshToken('refresh-1');
      await storage.setAccessTokenExpiresAt(
        DateTime.now().toUtc().add(const Duration(hours: 1)),
      );
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
      var attempts = 0;
      final client = ApiClient(
        storage: storage,
        authService: authService,
        httpClient: MockClient((request) async {
          attempts++;
          if (attempts == 1) {
            expect(request.headers['Authorization'], 'Bearer access-1');
            return http.Response('{"detail":"Expired"}', 401);
          }
          expect(request.headers['Authorization'], 'Bearer access-2');
          return http.Response('{"ok":true}', 200);
        }),
      );

      final data = await client.postJsonObject(
        '/api/profile',
        body: {'value': 1},
        failureCode: AppErrorCode.loginFailed,
      );

      expect(data, {'ok': true});
      expect(attempts, 2);
    });

    test('supports PUT and DELETE JSON helpers', () async {
      final storage = SecureStorageService();
      await storage.setServerUrl('https://example.test');
      await storage.setAccessToken('access-1');
      final methods = <String>[];
      final client = ApiClient(
        storage: storage,
        authService: AuthService(storage: storage),
        httpClient: MockClient((request) async {
          methods.add(request.method);
          return http.Response('{"ok":true}', 200);
        }),
      );

      await client.putJsonObject(
        '/api/profile',
        body: {'value': 1},
        failureCode: AppErrorCode.loginFailed,
      );
      await client.deleteJsonObject(
        '/api/profile',
        failureCode: AppErrorCode.loginFailed,
      );

      expect(methods, ['PUT', 'DELETE']);
    });

    test('throws when no server URL is configured', () async {
      final storage = SecureStorageService();
      await storage.setAccessToken('access-1');
      final client = ApiClient(
        storage: storage,
        authService: AuthService(storage: storage),
        httpClient: MockClient((request) async {
          fail('No request should be made without a server URL.');
        }),
      );

      await expectLater(
        client.getJsonObject(
          '/api/profile',
          failureCode: AppErrorCode.loginFailed,
        ),
        throwsA(
          isA<AppException>().having(
            (exception) => exception.code,
            'code',
            AppErrorCode.serverUrlNotConfigured,
          ),
        ),
      );
    });

    test('throws when no access token is available', () async {
      final storage = SecureStorageService();
      await storage.setServerUrl('https://example.test');
      final client = ApiClient(
        storage: storage,
        authService: AuthService(storage: storage),
        httpClient: MockClient((request) async {
          fail('No request should be made without an access token.');
        }),
      );

      await expectLater(
        client.getJsonObject(
          '/api/profile',
          failureCode: AppErrorCode.loginFailed,
        ),
        throwsA(
          isA<AppException>().having(
            (exception) => exception.code,
            'code',
            AppErrorCode.notAuthenticated,
          ),
        ),
      );
    });
    test('reads server URL and access token from injected session store',
        () async {
      final storage = SecureStorageService();
      await storage.setServerUrl('https://session.test');
      await storage.setAccessToken('access-from-store');
      final sessionStore = AuthSessionStore(storage: storage);

      // No storage passed directly — all reads come from sessionStore.
      final client = ApiClient(
        sessionStore: sessionStore,
        authService: AuthService(storage: storage),
        httpClient: MockClient((request) async {
          expect(request.url.origin, 'https://session.test');
          expect(
            request.headers['Authorization'],
            'Bearer access-from-store',
          );
          return http.Response('{"ok":true}', 200);
        }),
      );

      final data = await client.getJsonObject(
        '/api/profile',
        failureCode: AppErrorCode.loginFailed,
      );

      expect(data, {'ok': true});
    });

    test('throws requestTimeout when the request exceeds the timeout', () async {
      final storage = SecureStorageService();
      await storage.setServerUrl('https://example.test');
      await storage.setAccessToken('access-1');

      final client = ApiClient(
        storage: storage,
        authService: AuthService(storage: storage),
        httpClient: MockClient((_) async {
          await Future<void>.delayed(const Duration(seconds: 10));
          return http.Response('{}', 200);
        }),
        requestTimeout: const Duration(milliseconds: 1),
      );

      await expectLater(
        client.getJsonObject(
          '/api/profile',
          failureCode: AppErrorCode.loginFailed,
        ),
        throwsA(
          isA<AppException>().having(
            (e) => e.code,
            'code',
            AppErrorCode.requestTimeout,
          ),
        ),
      );
    });
  });
}

class _FakeMultipartUploadAdapter implements MultipartUploadAdapter {
  _FakeMultipartUploadAdapter({List<int>? statusCodes})
    : _statusCodes = statusCodes ?? [200];

  final List<int> _statusCodes;
  late Uri url;
  late Map<String, String> headers;
  late String filePath;
  late String fieldName;
  final List<String?> authorizationHeaders = [];

  @override
  Future<http.StreamedResponse> uploadFile({
    required Uri url,
    required Map<String, String> headers,
    required String filePath,
    required String fieldName,
  }) async {
    this.url = url;
    this.headers = headers;
    this.filePath = filePath;
    this.fieldName = fieldName;
    authorizationHeaders.add(headers['Authorization']);
    final statusCode = _statusCodes.length > authorizationHeaders.length - 1
        ? _statusCodes[authorizationHeaders.length - 1]
        : _statusCodes.last;
    return http.StreamedResponse(const Stream<List<int>>.empty(), statusCode);
  }
}
