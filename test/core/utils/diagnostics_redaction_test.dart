import 'package:endurain/core/utils/diagnostics_redaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('redactDiagnosticText', () {
    test('redacts JSON members with quoted keys and values', () {
      final redacted = redactDiagnosticText(
        '{"refresh_token":"rt-secret","password": "hunter 2","user":"bob"}',
      );

      expect(redacted, isNot(contains('rt-secret')));
      expect(redacted, isNot(contains('hunter 2')));
      expect(redacted, contains('token=<redacted>'));
      expect(redacted, contains('password=<redacted>'));
      expect(redacted, contains('"user":"bob"'));
    });

    test('redacts single-quoted values', () {
      final redacted = redactDiagnosticText("{'access_token': 'at-secret'}");

      expect(redacted, isNot(contains('at-secret')));
      expect(redacted, contains('token=<redacted>'));
    });

    test('redacts a bare JWT without a Bearer prefix', () {
      const jwt = 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIn0.c2lnbmF0dXJlLXZhbHVl';
      final redacted = redactDiagnosticText('decode failed for $jwt today');

      expect(redacted, isNot(contains(jwt)));
      expect(redacted, isNot(contains('c2lnbmF0dXJlLXZhbHVl')));
      expect(redacted, 'decode failed for <redacted> today');
    });

    test('keeps plain key=value redaction', () {
      expect(
        redactDiagnosticText('login failed password=hunter2 retrying'),
        'login failed password=<redacted> retrying',
      );
    });
  });

  group('redactDiagnosticText URLs and keys', () {
    test('redacts the host and path ids of a URL', () {
      final redacted = redactDiagnosticText(
        'failed uri=https://my.server.test:8443/api/v1/sessions/'
        '3f2b8c1e-aaaa-bbbb-cccc-1234567890ab/activities/42?page=2 now',
      );

      expect(redacted, isNot(contains('my.server.test')));
      expect(redacted, isNot(contains('3f2b8c1e')));
      expect(redacted, isNot(contains('/42')));
      expect(
        redacted,
        'failed uri=https://<host>/api/v1/sessions/<id>/activities/<id>'
        '?page=<redacted> now',
      );
    });

    test('redacts ids in a bare path and keeps plain segments', () {
      expect(
        redactDiagnosticText('GET /api/v1/auth/sessions/1234/tokens failed'),
        'GET /api/v1/auth/sessions/<id>/tokens failed',
      );
      expect(
        redactDiagnosticText('GET /api/v1/auth/password-change ok'),
        'GET /api/v1/auth/password-change ok',
      );
    });

    test('redacts opaque tokens in a path but not a long plain word', () {
      expect(
        redactDiagnosticText('/api/v1/idp/Ab3_x-Q9Zk2LmN8pQr/icon'),
        '/api/v1/idp/<id>/icon',
      );
      expect(
        redactDiagnosticText('/api/v1/internationalization/x'),
        '/api/v1/internationalization/x',
      );
    });

    test('leaves a fraction or date outside a path alone', () {
      expect(
        redactDiagnosticText('step 1/2 on 2026/06/01'),
        'step 1/2 on 2026/06/01',
      );
    });

    test('redacts session_id, sessionId, code_verifier and friends', () {
      for (final key in [
        'session_id',
        'sessionId',
        'code_verifier',
        'refresh_token',
        'client_secret',
        'X-Auth-Cookie',
      ]) {
        final redacted = redactDiagnosticText('$key=abc123 next');
        expect(redacted, isNot(contains('abc123')), reason: key);
        expect(redacted, '$key=<redacted> next', reason: key);
      }
      expect(
        redactDiagnosticText('{"sessionId":"abc-1","user":"bob"}'),
        '{"sessionId=<redacted>,"user":"bob"}',
      );
    });

    test('redacts email addresses', () {
      expect(
        redactDiagnosticText('User joao.silva+run@mail.example.org not found'),
        'User <email> not found',
      );
      expect(
        redactDiagnosticText('{"detail":"a@b.co and c_d@e.io"}'),
        '{"detail":"<email> and <email>"}',
      );
    });

    test('leaves text with an at sign but no address alone', () {
      expect(redactDiagnosticText('ping @here now'), 'ping @here now');
    });

    group('hosts and addresses', () {
      test('redacts a host after a failed lookup, quoted or not', () {
        expect(
          redactDiagnosticText(
            "SocketException: Failed host lookup: 'endurain.myhome.example'",
          ),
          'SocketException: Failed host lookup: <host>',
        );
        expect(
          redactDiagnosticText('Failed host lookup: endurain.myhome.example)'),
          'Failed host lookup: <host>)',
        );
      });

      test('redacts the address of a socket error', () {
        final redacted = redactDiagnosticText(
          'SocketException: Connection refused, address = 192.168.1.20, '
          'port = 51234',
        );

        expect(redacted, isNot(contains('192.168')));
        expect(redacted, contains('address = <host>'));
        expect(
          redactDiagnosticText('address = server.example, port = 1'),
          'address = <host>, port = 1',
        );
      });

      test('redacts IPv4 and IPv6 literals anywhere', () {
        expect(
          redactDiagnosticText('peer 10.0.0.7 reset, via 2001:db8::1 and ::1'),
          'peer <host> reset, via <host> and <host>',
        );
        expect(
          redactDiagnosticText('2001:0db8:85a3:0000:0000:8a2e:0370:7334 down'),
          '<host> down',
        );
      });

      test('leaves versions, times and coordinates alone', () {
        expect(
          redactDiagnosticText('app 1.2.3 build 0.12.4'),
          contains('1.2.3'),
        );
        expect(
          redactDiagnosticText('at 12:34:56 version 0.12.4+26'),
          'at 12:34:56 version 0.12.4+26',
        );
        expect(
          redactDiagnosticText('fix 41.123456, -8.123456'),
          'fix <coordinates>',
        );
      });
    });

    group('authorization schemes', () {
      test('consumes a Basic scheme and its token', () {
        expect(
          redactDiagnosticText('Authorization: Basic dXNlcjpwYXNz'),
          'Authorization=<redacted>',
        );
      });

      test('consumes Bearer and Digest schemes', () {
        expect(
          redactDiagnosticText('Authorization: Bearer abc.def'),
          'Authorization=<redacted>',
        );
        expect(
          redactDiagnosticText('authorization: Digest nonce12345'),
          'authorization=<redacted>',
        );
      });
    });
  });
}
