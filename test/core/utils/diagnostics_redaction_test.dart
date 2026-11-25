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
}
