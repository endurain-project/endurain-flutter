import 'package:endurain/core/services/crash_reporting_service.dart';
import 'package:endurain/features/settings/repositories/crash_reporting_settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_crash_reporter.dart';
import '../../helpers/fake_preferences_store.dart';

void main() {
  const managedDsn = 'https://managed-key@diagnostics.endurain.com/1';

  CrashReportingSettingsRepository settings([FakePreferencesStore? prefs]) {
    return CrashReportingSettingsRepository(
      preferences: prefs ?? FakePreferencesStore(),
    );
  }

  CrashReportingService service(
    FakeCrashReporter reporter, {
    FakePreferencesStore? prefs,
    String? defaultDsn,
  }) {
    return CrashReportingService(
      reporter: reporter,
      settings: settings(prefs),
      defaultDsn: defaultDsn,
      release: 'test-release',
      environment: 'test',
    );
  }

  group('CrashReportingService', () {
    test('is disabled and inactive by default', () async {
      final reporter = FakeCrashReporter();
      final subject = service(reporter, defaultDsn: managedDsn);

      await subject.load();

      expect(subject.isEnabled, isFalse);
      expect(subject.isActive, isFalse);
      expect(reporter.starts, isEmpty);
    });

    test('does not report while disabled', () async {
      final reporter = FakeCrashReporter();
      final subject = service(reporter, defaultDsn: managedDsn);
      await subject.load();

      await subject.recordError(StateError('boom'), StackTrace.current);

      expect(reporter.captures, isEmpty);
    });

    test('enabling with the managed default DSN starts reporting', () async {
      final reporter = FakeCrashReporter();
      final subject = service(reporter, defaultDsn: managedDsn);
      await subject.load();

      await subject.setEnabled(true);

      expect(subject.isEnabled, isTrue);
      expect(subject.isActive, isTrue);
      expect(subject.effectiveDsn, managedDsn);
      expect(reporter.starts.single.dsn, managedDsn);
      expect(reporter.starts.single.release, 'test-release');
      expect(reporter.starts.single.environment, 'test');
    });

    test('enabling without any usable DSN stays inactive', () async {
      final reporter = FakeCrashReporter();
      final subject = service(reporter); // no default DSN
      await subject.load();

      await subject.setEnabled(true);

      expect(subject.isEnabled, isTrue);
      expect(subject.hasUsableDsn, isFalse);
      expect(subject.isActive, isFalse);
      expect(reporter.starts, isEmpty);
    });

    test('forwards captured errors with their source while enabled', () async {
      final reporter = FakeCrashReporter();
      final subject = service(reporter, defaultDsn: managedDsn);
      await subject.load();
      await subject.setEnabled(true);

      final error = StateError('kaboom');
      await subject.recordError(error, StackTrace.current, source: 'root_zone');

      expect(reporter.captures.single.error, same(error));
      expect(reporter.captures.single.source, 'root_zone');
    });

    test('disabling stops the reporter', () async {
      final reporter = FakeCrashReporter();
      final subject = service(reporter, defaultDsn: managedDsn);
      await subject.load();
      await subject.setEnabled(true);
      expect(subject.isActive, isTrue);

      await subject.setEnabled(false);

      expect(subject.isEnabled, isFalse);
      expect(subject.isActive, isFalse);
      expect(reporter.stopCount, greaterThanOrEqualTo(1));
    });

    test('persists the opt-in across instances', () async {
      final prefs = FakePreferencesStore();
      final first = service(
        FakeCrashReporter(),
        prefs: prefs,
        defaultDsn: managedDsn,
      );
      await first.load();
      await first.setEnabled(true);

      final reporter = FakeCrashReporter();
      final second = service(reporter, prefs: prefs, defaultDsn: managedDsn);

      await second.initializeIfEnabled();

      expect(second.isEnabled, isTrue);
      expect(second.isActive, isTrue);
      expect(reporter.starts.single.dsn, managedDsn);
    });

    test(
      'initializeIfEnabled does nothing when the user has not opted in',
      () async {
        final reporter = FakeCrashReporter();
        final subject = service(reporter, defaultDsn: managedDsn);

        await subject.initializeIfEnabled();

        expect(subject.isActive, isFalse);
        expect(reporter.starts, isEmpty);
      },
    );
  });
}
