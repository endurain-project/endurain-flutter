import 'package:endurain/core/services/crash_reporter.dart';
import 'package:endurain/core/services/crash_reporting_service.dart';
import 'package:endurain/features/settings/repositories/crash_reporting_settings_repository.dart';

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
