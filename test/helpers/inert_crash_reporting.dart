import 'package:endurain/core/diagnostics/crash_reporter.dart';
import 'package:endurain/features/settings/repositories/crash_reporting_settings_repository.dart';
import 'package:endurain/features/settings/services/crash_reporting_service.dart';

import 'fake_preferences_store.dart';

/// An inert [CrashReportingService] for tests that do not exercise remote
/// reporting: a no-op reporter over in-memory preferences with no configured
/// DSN, so it stays permanently disabled and transmits nothing.
CrashReportingService inertCrashReportingService() => CrashReportingService(
  reporter: const NoopCrashReporter(),
  settings: CrashReportingSettingsRepository(
    preferences: FakePreferencesStore(),
  ),
);

/// A [CrashReporter] that discards everything, so no real backend is ever
/// contacted.
class NoopCrashReporter implements CrashReporter {
  const NoopCrashReporter();

  @override
  bool get isActive => false;

  @override
  Future<bool> start({
    required String dsn,
    String? release,
    String? environment,
  }) async => false;

  @override
  Future<void> stop() async {}

  @override
  Future<void> capture(
    Object error,
    StackTrace stackTrace, {
    String? source,
  }) async {}
}
