import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:endurain/core/constants/api_constants.dart';
import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/services/base_http_client.dart';

void main() {
  group('BaseHttpClient', () {
    group('default headers', () {
      test('includes client-type header on every GET', () async {
        String? capturedHeader;
        final client = BaseHttpClient(
          httpClient: MockClient((request) async {
            capturedHeader =
                request.headers[ApiConstants.clientTypeHeader];
            return http.Response('{}', 200);
          }),
        );

        await client.getJsonObject(
          Uri.parse('https://example.test/endpoint'),
          failureCode: AppErrorCode.fetchServerSettingsFailed,
        );

        expect(capturedHeader, ApiConstants.clientTypeValue);
      });

      test('includes client-type header on every POST', () async {
        String? capturedHeader;
        final client = BaseHttpClient(
          httpClient: MockClient((request) async {
            capturedHeader =
                request.headers[ApiConstants.clientTypeHeader];
            return http.Response('{}', 200);
          }),
        );

        await client.postJsonObject(
          Uri.parse('https://example.test/endpoint'),
          failureCode: AppErrorCode.loginFailed,
        );

        expect(capturedHeader, ApiConstants.clientTypeValue);
      });

      test('merges caller-supplied extra headers', () async {
        final captured = <String, String>{};
        final client = BaseHttpClient(
          httpClient: MockClient((request) async {
            captured.addAll(request.headers);
            return http.Response('{}', 200);
          }),
        );

        await client.getJsonObject(
          Uri.parse('https://example.test/endpoint'),
          extraHeaders: {'X-Custom': 'value'},
          failureCode: AppErrorCode.fetchServerSettingsFailed,
        );

        expect(captured[ApiConstants.clientTypeHeader],
            ApiConstants.clientTypeValue);
        expect(captured['X-Custom'], 'value');
      });
    });

    group('getJsonObject', () {
      test('returns decoded JSON map on 200', () async {
        final client = BaseHttpClient(
          httpClient: MockClient(
            (_) async => http.Response('{"key":"value"}', 200),
          ),
        );

        final result = await client.getJsonObject(
          Uri.parse('https://example.test/endpoint'),
          failureCode: AppErrorCode.fetchServerSettingsFailed,
        );

        expect(result, {'key': 'value'});
      });

      test('throws with failureCode on non-200 response', () async {
        final client = BaseHttpClient(
          httpClient: MockClient(
            (_) async => http.Response('{"detail":"Not found"}', 404),
          ),
        );

        await expectLater(
          client.getJsonObject(
            Uri.parse('https://example.test/endpoint'),
            failureCode: AppErrorCode.fetchServerSettingsFailed,
          ),
          throwsA(
            isA<AppException>().having(
              (e) => e.code,
              'code',
              AppErrorCode.fetchServerSettingsFailed,
            ),
          ),
        );
      });
    });

    group('getJson', () {
      test('returns JSON list on 200', () async {
        final client = BaseHttpClient(
          httpClient: MockClient(
            (_) async => http.Response('[1,2,3]', 200),
          ),
        );

        final result = await client.getJson(
          Uri.parse('https://example.test/list'),
          failureCode: AppErrorCode.fetchProvidersFailed,
        );

        expect(result, [1, 2, 3]);
      });

      test('throws with failureCode on non-200 response', () async {
        final client = BaseHttpClient(
          httpClient: MockClient(
            (_) async => http.Response('', 500),
          ),
        );

        await expectLater(
          client.getJson(
            Uri.parse('https://example.test/list'),
            failureCode: AppErrorCode.fetchProvidersFailed,
          ),
          throwsA(
            isA<AppException>().having(
              (e) => e.code,
              'code',
              AppErrorCode.fetchProvidersFailed,
            ),
          ),
        );
      });
    });

    group('postJsonObject', () {
      test('sends JSON body with Content-Type header', () async {
        String? capturedBody;
        String? capturedContentType;
        final client = BaseHttpClient(
          httpClient: MockClient((request) async {
            capturedBody = request.body;
            capturedContentType =
                request.headers[ApiConstants.contentTypeHeader];
            return http.Response('{"ok":true}', 200);
          }),
        );

        await client.postJsonObject(
          Uri.parse('https://example.test/endpoint'),
          jsonBody: {'user': 'alice'},
          failureCode: AppErrorCode.loginFailed,
        );

        expect(capturedBody, '{"user":"alice"}');
        expect(capturedContentType, ApiConstants.contentTypeJson);
      });

      test('sends rawBody without auto Content-Type override', () async {
        String? capturedBody;
        String? capturedContentType;
        final client = BaseHttpClient(
          httpClient: MockClient((request) async {
            capturedBody = request.body;
            capturedContentType =
                request.headers[ApiConstants.contentTypeHeader];
            return http.Response('{"session_id":"s1"}', 200);
          }),
        );

        await client.postJsonObject(
          Uri.parse('https://example.test/login'),
          extraHeaders: {
            ApiConstants.contentTypeHeader:
                ApiConstants.contentTypeFormUrlEncoded,
          },
          rawBody: 'username=alice&password=secret',
          failureCode: AppErrorCode.loginFailed,
        );

        expect(capturedBody, 'username=alice&password=secret');
        expect(capturedContentType,
            ApiConstants.contentTypeFormUrlEncoded);
      });

      test('throws with failureCode on non-200 response', () async {
        final client = BaseHttpClient(
          httpClient: MockClient(
            (_) async => http.Response('{"detail":"Unauthorized"}', 401),
          ),
        );

        await expectLater(
          client.postJsonObject(
            Uri.parse('https://example.test/endpoint'),
            failureCode: AppErrorCode.loginFailed,
          ),
          throwsA(
            isA<AppException>().having(
              (e) => e.code,
              'code',
              AppErrorCode.loginFailed,
            ),
          ),
        );
      });
    });

    group('low-level get/post', () {
      test('returns raw response for caller inspection', () async {
        final client = BaseHttpClient(
          httpClient: MockClient(
            (_) async => http.Response('OK', 204),
          ),
        );

        final response = await client.get(
          Uri.parse('https://example.test/ping'),
        );

        expect(response.statusCode, 204);
        expect(response.body, 'OK');
      });
    });

    group('timeout', () {
      test('throws requestTimeout when GET exceeds the configured duration',
          () async {
        final client = BaseHttpClient(
          httpClient: MockClient(
            (_) async {
              await Future<void>.delayed(const Duration(seconds: 10));
              return http.Response('{}', 200);
            },
          ),
          timeout: const Duration(milliseconds: 1),
        );

        await expectLater(
          client.get(Uri.parse('https://example.test/slow')),
          throwsA(
            isA<AppException>().having(
              (e) => e.code,
              'code',
              AppErrorCode.requestTimeout,
            ),
          ),
        );
      });

      test('throws requestTimeout when POST exceeds the configured duration',
          () async {
        final client = BaseHttpClient(
          httpClient: MockClient(
            (_) async {
              await Future<void>.delayed(const Duration(seconds: 10));
              return http.Response('{}', 200);
            },
          ),
          timeout: const Duration(milliseconds: 1),
        );

        await expectLater(
          client.post(Uri.parse('https://example.test/slow')),
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
  });
}
