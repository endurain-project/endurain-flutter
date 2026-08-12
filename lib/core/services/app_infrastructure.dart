import 'package:endurain/core/config/api_endpoints.dart';
import 'package:endurain/core/config/app_config.dart';
import 'package:endurain/core/services/app_preferences_store.dart';
import 'package:endurain/core/services/connectivity_service.dart';
import 'package:endurain/core/services/crash_reporting_service.dart';
import 'package:endurain/core/services/diagnostics_service.dart';
import 'package:endurain/core/services/location_service.dart';
import 'package:endurain/core/services/platform/app_links_service.dart';
import 'package:endurain/core/services/platform/device_measurement_system_service.dart';
import 'package:endurain/core/services/platform/package_info_service.dart';
import 'package:endurain/core/services/platform/sentry_crash_reporter.dart';
import 'package:endurain/core/services/platform/share_service.dart';
import 'package:endurain/core/services/platform/url_launcher_service.dart';
import 'package:endurain/core/services/secure_storage_service.dart';
import 'package:endurain/features/settings/controllers/locale_controller.dart';
import 'package:endurain/features/settings/controllers/measurement_system_controller.dart';
import 'package:endurain/features/settings/repositories/crash_reporting_settings_repository.dart';
import 'package:endurain/features/settings/repositories/locale_settings_repository.dart';
import 'package:endurain/features/settings/repositories/measurement_settings_repository.dart';
import 'package:flutter/foundation.dart';

/// Shared, feature-agnostic infrastructure wired once and handed to every
/// feature module.
///
/// Holds the leaf services that carry no feature logic (storage, diagnostics,
/// connectivity, platform integrations, endpoints, and the app-wide locale).
/// Feature modules depend on this rather than on each other for these basics,
/// which keeps the dependency direction one-way: modules → infrastructure.
///
/// Everything is lazily initialized (`late final`), so constructing an
/// [AppInfrastructure] does no work until a service is first touched.
class AppInfrastructure {
  AppInfrastructure({required this.config});

  /// Runtime configuration (API base path, managed-origin policy, feature
  /// flags) shared by every service.
  final AppConfig config;

  final DiagnosticsService diagnostics = DiagnosticsService();

  late final ApiEndpoints endpoints = ApiEndpoints(config);

  late final SecureStorageService secureStorage = SecureStorageService();

  late final AppPreferencesStore preferences = AppPreferencesStore();

  final LocationService location = LocationService();

  final ConnectivityService connectivity = ConnectivityService();

  final AppLinksService appLinks = DefaultAppLinksService();

  final UrlLauncherService urlLauncher = const UrlLauncherService();

  final ShareService share = ShareService();

  final PackageInfoService packageInfo = const PackageInfoService();

  /// App-wide selected language, persisted as a BCP 47 tag. A `null` locale
  /// follows the system. Owned here so the root `App` can rebuild the localized
  /// tree when the user switches languages in Settings.
  late final LocaleController localeController = LocaleController(
    repository: LocaleSettingsRepository(preferences: preferences),
  );

  /// App-wide unit preference (metric/imperial). A `null` preference follows
  /// the operating-system measurement setting. Owned here for the same reason
  /// as [localeController]: the root `App` listens so switching units
  /// re-renders every screen.
  late final MeasurementSystemController measurementSystemController =
      MeasurementSystemController(
        repository: MeasurementSettingsRepository(preferences: preferences),
        deviceMeasurementSystem: const PlatformDeviceMeasurementSystemService(),
      );

  /// Opt-in remote crash reporting, independent of the local [diagnostics]
  /// recorder. Inactive until the user enables it and the managed DSN
  /// (`config.crashReportingDsn`) is available, so no build transmits crash
  /// data by default.
  late final CrashReportingService crashReporting = CrashReportingService(
    reporter: SentryCrashReporter(),
    settings: CrashReportingSettingsRepository(preferences: preferences),
    defaultDsn: config.crashReportingDsn,
    environment: kReleaseMode ? 'production' : 'development',
  );
}
