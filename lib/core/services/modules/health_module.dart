import 'package:endurain/core/services/app_infrastructure.dart';
import 'package:endurain/core/services/modules/activity_module.dart';
import 'package:endurain/core/services/modules/auth_module.dart';
import 'package:endurain/features/health/controllers/health_sync_controller.dart';
import 'package:endurain/features/health/repositories/health_import_repository.dart';
import 'package:endurain/features/health/repositories/health_sync_settings_repository.dart';
import 'package:endurain/features/health/services/health_package_platform_adapter.dart';
import 'package:endurain/features/health/services/health_platform_adapter.dart';
import 'package:endurain/features/health/services/health_sync_service.dart';
import 'package:endurain/features/health/services/health_workout_gpx_builder.dart';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

/// Wires the Health platform sync feature (Apple HealthKit / Android Health
/// Connect): import provenance, sync settings, the sync service, and the
/// route-owned sync controller.
///
/// Depends on [AppInfrastructure], [AuthModule] (for the active connection
/// profile), and [ActivityModule] (imported workouts become local activities
/// fed into the shared upload queue).
class HealthModule {
  HealthModule({
    required AppInfrastructure infra,
    required AuthModule auth,
    required ActivityModule activity,
  }) : _infra = infra,
       _auth = auth,
       _activity = activity;

  final AppInfrastructure _infra;
  final AuthModule _auth;
  final ActivityModule _activity;

  late final HealthSyncSettingsRepository syncSettings =
      HealthSyncSettingsRepository(storage: _infra.secureStorage);

  late final HealthImportRepository importRepository = HealthImportRepository();

  late final HealthSyncService syncService = HealthSyncService(
    adapter: createPlatformAdapter(),
    importRepository: importRepository,
    localActivities: _activity.localActivities,
    uploadQueue: _activity.uploadQueue,
    gpxBuilder: const HealthWorkoutGpxBuilder(),
    syncSettings: syncSettings,
    diagnostics: _infra.diagnostics,
    healthSyncEnabled: _infra.config.healthSyncEnabled,
    activeConnectionProfile: _auth.session.getConnectionProfile,
  );

  /// Creates a route-owned controller for health-platform workout sync.
  ///
  /// Health UI state contains profile-scoped rows and selections, so it must
  /// not outlive the route or survive a logout/login transition.
  HealthSyncController createSyncController() {
    return HealthSyncController(
      service: syncService,
      diagnostics: _infra.diagnostics,
      uploadCompletedSignal: _activity.uploadQueue.onDrainCompleted,
    );
  }

  /// Builds the concrete health-platform adapter for the current platform.
  ///
  /// Returns [HealthPackagePlatformAdapter] on Android/iOS; falls back to
  /// [UnsupportedHealthPlatformAdapter] on all other platforms (e.g. macOS,
  /// Linux, Windows, or the host test runner).
  HealthPlatformAdapter createPlatformAdapter() {
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      return HealthPackagePlatformAdapter(
        health: Health(),
        diagnostics: _infra.diagnostics,
      );
    }
    return const UnsupportedHealthPlatformAdapter();
  }
}
