import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/services/api_response.dart';

void main() {
  group('ApiResponse', () {
    test('decodes JSON objects', () {
      final response = http.Response('{"name":"endurain"}', 200);

      final data = ApiResponse.decodeJsonObject(response);

      expect(data, {'name': 'endurain'});
    });

    test('throws typed exception for unexpected JSON shape', () {
      final response = http.Response('["endurain"]', 200);

      expect(
        () => ApiResponse.decodeJsonObject(response),
        throwsA(
          isA<AppException>().having(
            (exception) => exception.code,
            'code',
            AppErrorCode.unexpectedResponseFormat,
          ),
        ),
      );
    });

    test('extracts server error details from supported keys', () {
      final response = http.Response('{"detail":"Invalid login"}', 400);

      final error = ApiResponse.failure(response, AppErrorCode.loginFailed);

      expect(error.code, AppErrorCode.loginFailed);
      expect(error.details, 'Invalid login');
    });

    test('uses plain body as error detail when response is not JSON', () {
      final response = http.Response('Server unavailable', 503);

      final error = ApiResponse.failure(
        response,
        AppErrorCode.fetchServerSettingsFailed,
      );

      expect(error.details, 'Server unavailable');
    });

    group('errorDetail — bounding and sanitisation', () {
      test('returns null for an empty body', () {
        final response = http.Response('', 500);
        expect(ApiResponse.errorDetail(response), isNull);
      });

      test('returns short JSON detail as-is', () {
        final response = http.Response('{"detail":"bad request"}', 400);
        expect(ApiResponse.errorDetail(response), 'bad request');
      });

      test('truncates a JSON detail field longer than 200 characters', () {
        final long = 'A' * 250;
        final response = http.Response('{"detail":"$long"}', 400);
        final detail = ApiResponse.errorDetail(response);
        expect(detail, isNotNull);
        // Truncated to 200 chars + ellipsis character
        expect(detail!.length, 201);
        expect(detail.endsWith('\u2026'), isTrue);
      });

      test('truncates a non-JSON body longer than 200 characters', () {
        final html = '<html><body>${'x' * 300}</body></html>';
        final response = http.Response(html, 502);
        final detail = ApiResponse.errorDetail(response);
        expect(detail, isNotNull);
        expect(detail!.length, 201);
        expect(detail.endsWith('\u2026'), isTrue);
      });

      test('returns null when JSON body is a non-map (array, etc.)', () {
        final response = http.Response('[1,2,3]', 400);
        expect(ApiResponse.errorDetail(response), isNull);
      });

      test('returns null when JSON map has no recognised error key', () {
        final response = http.Response('{"status":"unknown"}', 400);
        expect(ApiResponse.errorDetail(response), isNull);
      });

      test('prefers "detail" key over "message" and "error"', () {
        final response = http.Response(
          '{"detail":"from detail","message":"from message","error":"from error"}',
          400,
        );
        expect(ApiResponse.errorDetail(response), 'from detail');
      });

      test('falls back to "message" when "detail" is absent', () {
        final response = http.Response(
          '{"message":"from message","error":"from error"}',
          400,
        );
        expect(ApiResponse.errorDetail(response), 'from message');
      });
    });
  });
}
