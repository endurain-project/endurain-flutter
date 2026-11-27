import 'package:endurain/app/app_infrastructure.dart';
import 'package:endurain/app/modules/activity_module.dart';
import 'package:endurain/app/modules/auth_module.dart';
import 'package:endurain/core/utils/platform_utils.dart';
import 'package:endurain/features/health/controllers/health_sync_controller.dart';
import 'package:endurain/features/health/repositories/health_import_repository.dart';
import 'package:endurain/features/health/repositories/health_sync_settings_repository.dart';
import 'package:endurain/features/health/services/health_auto_sync_service.dart';
import 'package:endurain/features/health/services/health_background_sync_adapter.dart';
import 'package:endurain/features/health/services/health_package_platform_adapter.dart';
import 'package:endurain/features/health/services/health_platform_adapter.dart';
import 'package:endurain/features/health/services/health_sync_service.dart';
import 'package:endurain/features/health/services/health_workout_changes_reader.dart';
import 'package:endurain/features/health/services/health_workout_gpx_builder.dart';
import 'package:endurain/features/health/services/heart_rate_series_reader.dart';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

/// Wires the Health platform sync feature (Apple HealthKit / Android Health
/// Connect): import provenance, sync settings, the sync and automatic-import
/// services, the background trigger, and the route-owned sync controller.
///
/// Depends on [AppInfrastructure], [AuthModule] (for the active connection
/// profile), and [ActivityModule] (imported workouts become local activities
/// fed into the shared upload queue).
class HealthModule {
  HealthModule({
    required AppInfrastructure infra,
    required AuthModule auth,
    required ActivityModule activity,
    Future<bool> Function(String sourceId)? isRecordedElsewhere,
  }) : _infra = infra,
       _auth = auth,
       _activity = activity,
       _isRecordedElsewhere = isRecordedElsewhere;

  final AppInfrastructure _infra;
  final AuthModule _auth;
  final ActivityModule _activity;
  final Future<bool> Function(String sourceId)? _isRecordedElsewhere;

  late final HealthSyncSettingsRepository syncSettings =
      HealthSyncSettingsRepository(
        preferences: _infra.preferences,
        storage: _infra.secureStorage,
      );

  late final HealthImportRepository importRepository = HealthImportRepository();

  late final HealthPlatformAdapter _platformAdapter = createPlatformAdapter();

  late final HealthSyncService syncService = HealthSyncService(
    adapter: _platformAdapter,
    importRepository: importRepository,
    localActivities: _activity.localActivities,
    uploadQueue: _activity.uploadQueue,
    gpxBuilder: const HealthWorkoutGpxBuilder(),
    syncSettings: syncSettings,
    diagnostics: _infra.diagnostics,
    healthSyncEnabled: _infra.config.healthSyncEnabled,
    activeConnectionProfile: _auth.session.getConnectionProfile,
    isRecordedElsewhere: _isRecordedElsewhere,
  );

  late final HealthBackgroundSyncAdapter _backgroundSync = isMobilePlatform
      ? const MethodChannelHealthBackgroundSyncAdapter()
      : const UnsupportedHealthBackgroundSyncAdapter();

  late final HealthAutoSyncService autoSyncService = HealthAutoSyncService(
    syncService: syncService,
    adapter: _platformAdapter,
    background: _backgroundSync,
    settings: syncSettings,
    importRepository: importRepository,
    uploadQueue: _activity.uploadQueue,
    diagnostics: _infra.diagnostics,
    healthSyncEnabled: _infra.config.healthSyncEnabled,
    activeConnectionProfile: _auth.session.getConnectionProfile,
  );

  /// Makes this (the app's) engine run the background syncs the platform
  /// starts while the app is running, instead of a headless engine.
  Future<void> listenForBackgroundSync() {
    return _backgroundSync.listen(autoSyncService.syncInBackground);
  }

  /// Runs the one background sync a headless engine was started for.
  /// Returns whether it ran without failures; it never throws.
  Future<bool> runBackgroundSync() => autoSyncService.syncInBackground();

  /// Tells the platform the headless engine's sync is over, so it can be
  /// destroyed.
  Future<void> reportBackgroundSyncFinished({required bool succeeded}) {
    return _backgroundSync.reportFinished(succeeded: succeeded);
  }

  /// Creates a route-owned controller for health-platform workout sync.
  ///
  /// Health UI state contains profile-scoped rows and selections, so it must
  /// not outlive the route or survive a logout/login transition.
  HealthSyncController createSyncController() {
    return HealthSyncController(
      service: syncService,
      autoSync: autoSyncService,
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
    if (isMobilePlatform) {
      return HealthPackagePlatformAdapter(
        health: Health(),
        diagnostics: _infra.diagnostics,
        // The plugin reduces condensed HealthKit heart rate series to one
        // value each, so iOS reads heart rate through its own channel.
        heartRateSeriesReader: defaultTargetPlatform == TargetPlatform.iOS
            ? const MethodChannelHeartRateSeriesReader()
            : null,
        // The plugin tracks changes only in Health Connect; on iOS they come
        // from HealthKit anchored queries over a channel of the app's own.
        workoutChangesReader: defaultTargetPlatform == TargetPlatform.iOS
            ? const MethodChannelHealthWorkoutChangesReader()
            : null,
      );
    }
    return const UnsupportedHealthPlatformAdapter();
  }
}
