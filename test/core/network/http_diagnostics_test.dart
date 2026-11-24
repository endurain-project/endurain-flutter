import 'dart:io';

import 'package:endurain/core/diagnostics/diagnostics_service.dart';
import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/network/base_http_client.dart';
import 'package:endurain/core/network/http_diagnostics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../helpers/recording_diagnostics.dart';

void main() {
  group('diagnosticEndpoint', () {
    test('keeps route words and drops the host and query', () {
      expect(
        diagnosticEndpoint(
          Uri.parse('https://my.server.test/api/v1/auth/password-change?x=1'),
        ),
        '/api/v1/auth/password-change',
      );
    });

    test('drops a base path the user chose before the API', () {
      expect(
        diagnosticEndpoint(
          Uri.parse('https://host.test/joao/endurain/api/v1/profile'),
        ),
        '/api/v1/profile',
      );
    });

    test('replaces ids, session ids and tokens', () {
      expect(
        diagnosticEndpoint(
          Uri.parse('https://h.test/api/v1/auth/sessions/abcdefghij/tokens'),
        ),
        '/api/v1/auth/sessions/:id/tokens',
      );
      expect(
        diagnosticEndpoint(Uri.parse('https://h.test/api/v1/activities/123')),
        '/api/v1/activities/:id',
      );
      expect(
        diagnosticEndpoint(Uri.parse('https://h.test/api/v1/jobs/plainword')),
        '/api/v1/jobs/:id',
      );
      expect(
        diagnosticEndpoint(
          Uri.parse('https://h.test/api/v1/public/idp/Ab3_x-Q9/icon'),
        ),
        '/api/v1/public/idp/:id/icon',
      );
    });
  });

  group('BaseHttpClient diagnostics', () {
    final url = Uri.parse('https://h.test/api/v1/profile?token=secret');

    test('records a 4xx/5xx answer with its status', () async {
      final diagnostics = RecordingDiagnostics();
      final client = BaseHttpClient(
        diagnostics: diagnostics,
        httpClient: MockClient((_) async => http.Response('', 500)),
      );

      await client.get(url);

      final details = diagnostics.single(DiagnosticsEvents.httpRequestFailed);
      expect(details['method'], 'GET');
      expect(details['endpoint'], '/api/v1/profile');
      expect(details['status'], 500);
      expect(details['ms'], isA<int>());
      expect(details.toString(), isNot(contains('secret')));
    });

    test('records a transport error with its type', () async {
      final diagnostics = RecordingDiagnostics();
      final client = BaseHttpClient(
        diagnostics: diagnostics,
        httpClient: MockClient((_) async {
          throw const SocketException('down');
        }),
      );

      await expectLater(client.get(url), throwsA(isA<SocketException>()));

      final details = diagnostics.single(DiagnosticsEvents.httpRequestFailed);
      expect(details['type'], 'SocketException');
      expect(details.containsKey('status'), isFalse);
    });

    test('records a timeout by its code', () async {
      final diagnostics = RecordingDiagnostics();
      final client = BaseHttpClient(
        diagnostics: diagnostics,
        timeout: const Duration(milliseconds: 1),
        httpClient: MockClient((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return http.Response('', 200);
        }),
      );

      await expectLater(client.get(url), throwsA(isA<AppException>()));

      expect(
        diagnostics.single(DiagnosticsEvents.httpRequestFailed)['code'],
        'requestTimeout',
      );
    });

    test('records nothing for a success', () async {
      final diagnostics = RecordingDiagnostics();
      final client = BaseHttpClient(
        diagnostics: diagnostics,
        httpClient: MockClient((_) async => http.Response('{}', 200)),
      );

      await client.get(url);

      expect(diagnostics.events, isEmpty);
    });
  });
}
