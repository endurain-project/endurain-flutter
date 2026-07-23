import 'package:endurain/core/services/crash_reporter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isUsableCrashReportingDsn', () {
    test('accepts a full Sentry DSN', () {
      expect(
        isUsableCrashReportingDsn(
          'https://public-key@diagnostics.endurain.com/1',
        ),
        isTrue,
      );
    });

    test('accepts an http DSN (self-hosted GlitchTip on a LAN)', () {
      expect(
        isUsableCrashReportingDsn('http://public-key@glitchtip.local/42'),
        isTrue,
      );
    });

    test('rejects null, blank, and whitespace', () {
      expect(isUsableCrashReportingDsn(null), isFalse);
      expect(isUsableCrashReportingDsn(''), isFalse);
      expect(isUsableCrashReportingDsn('   '), isFalse);
    });

    test('rejects a host-only URL with no public key', () {
      expect(
        isUsableCrashReportingDsn('https://diagnostics.endurain.com'),
        isFalse,
      );
    });

    test('rejects a DSN without a project path', () {
      expect(
        isUsableCrashReportingDsn(
          'https://public-key@diagnostics.endurain.com',
        ),
        isFalse,
      );
    });

    test('rejects a non-http scheme', () {
      expect(
        isUsableCrashReportingDsn(
          'ftp://public-key@diagnostics.endurain.com/1',
        ),
        isFalse,
      );
    });
  });

  group('NoopCrashReporter', () {
    test('never activates and swallows every call', () async {
      const reporter = NoopCrashReporter();

      expect(reporter.isActive, isFalse);
      expect(await reporter.start(dsn: 'https://key@host/1'), isFalse);
      expect(reporter.isActive, isFalse);
      await reporter.capture(StateError('boom'), StackTrace.current);
      await reporter.stop();
    });
  });
}
