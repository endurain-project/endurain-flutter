import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';
import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/services/api_client.dart';
import 'package:endurain/core/services/auth_service.dart';
import 'package:endurain/core/services/multipart_upload_adapter.dart';
import 'package:endurain/core/services/secure_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
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

    test('refreshes an expiring access token before uploading', () async {
      final storage = SecureStorageService();
      await storage.setServerUrl('https://example.test');
      await storage.setAccessToken('access-1');
      await storage.setRefreshToken('refresh-1');
      await storage.setAccessTokenExpiresAt(
        DateTime.now().toUtc().add(const Duration(seconds: 30)),
      );
      final uploadAdapter = _FakeMultipartUploadAdapter();
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
        uploadAdapter: uploadAdapter,
      );

      await client.uploadFile('/api/files', '/tmp/activity.gpx', 'file');

      expect(uploadAdapter.headers['Authorization'], 'Bearer access-2');
      expect(await storage.getAccessToken(), 'access-2');
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
