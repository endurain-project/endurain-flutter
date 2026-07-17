import 'dart:async';

import 'package:endurain/core/config/api_endpoints.dart';
import 'package:endurain/core/config/app_config.dart';
import 'package:endurain/core/services/api_client.dart';
import 'package:endurain/core/services/platform/app_links_service.dart';
import 'package:endurain/core/services/app_preferences_store.dart';
import 'package:endurain/core/services/auth_session_store.dart';
import 'package:endurain/core/services/auth_service.dart';
import 'package:endurain/core/services/connectivity_service.dart';
import 'package:endurain/core/services/diagnostics_service.dart';
import 'package:endurain/core/services/location_service.dart';
import 'package:endurain/core/services/platform/package_info_service.dart';
import 'package:endurain/core/services/secure_storage_service.dart';
import 'package:endurain/core/services/server_settings_service.dart';
import 'package:endurain/core/services/sso_service.dart';
import 'package:endurain/core/services/platform/share_service.dart';
import 'package:endurain/core/services/platform/url_launcher_service.dart';
import 'package:endurain/features/activity/controllers/activity_recording_controller.dart';
import 'package:endurain/features/activity/models/activity_recording_state.dart';
import 'package:endurain/features/activity/repositories/activity_retention_settings_repository.dart';
import 'package:endurain/features/activity/repositories/file_active_activity_store.dart';
import 'package:endurain/features/activity/repositories/local_activity_repository.dart';
import 'package:endurain/features/activity/repositories/sqflite_activity_store.dart';
import 'package:endurain/features/activity/services/activity_location_recorder.dart';
import 'package:endurain/features/activity/services/activity_recording_service.dart';
import 'package:endurain/features/activity/services/activity_upload_queue.dart';
import 'package:endurain/features/activity/services/activity_upload_service.dart';
import 'package:endurain/features/activity/services/geolocator_activity_location_recorder.dart';
import 'package:endurain/features/activity/services/local_activity_gpx_storage.dart';
import 'package:endurain/features/activity/services/native_activity_recorder_channel.dart';
import 'package:endurain/features/health/controllers/health_sync_controller.dart';
import 'package:endurain/features/health/repositories/health_import_repository.dart';
import 'package:endurain/features/health/repositories/health_sync_settings_repository.dart';
import 'package:endurain/features/health/services/health_package_platform_adapter.dart';
import 'package:endurain/features/health/services/health_platform_adapter.dart';
import 'package:endurain/features/health/services/health_sync_service.dart';
import 'package:endurain/features/health/services/health_workout_gpx_builder.dart';
import 'package:endurain/features/sensors/repositories/sensor_preferences_repository.dart';
import 'package:endurain/features/sensors/services/heart_rate_sensor_adapter.dart';
import 'package:endurain/features/sensors/services/heart_rate_sensor_service.dart';
import 'package:endurain/features/sensors/services/universal_ble_heart_rate_sensor_adapter.dart';
import 'package:endurain/features/settings/controllers/locale_controller.dart';
import 'package:endurain/features/settings/repositories/locale_settings_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

class AppServices {
  AppServices({this.config = AppConfig.defaults});

  /// Last-resort fallback instance.
  ///
  /// Production does NOT use this: the composition root (`main()`) constructs
  /// its own [AppServices] and injects it into the root `App`, which exposes it
  /// through `AppScope`. This global only exists as a safety net for two paths
  /// that can run without an injected instance:
  /// - the `AppScope.servicesOf` fallback for contexts not wrapped in a scope,
  /// - tests that build `App()` without supplying services.
  ///
  /// Feature code MUST obtain services via `AppScope.servicesOf(context)` so
  /// future managed, multi-environment, or account-scoped builds can isolate
  /// service instances. Do not reference `AppServices.instance` from feature
  /// widgets, controllers, or services.
  static final AppServices instance = AppServices();

  final DiagnosticsService diagnostics = DiagnosticsService();
  final AppConfig config;
  late final ApiEndpoints _endpoints = ApiEndpoints(config);
  late final SecureStorageService secureStorage = SecureStorageService();
  late final AppPreferencesStore preferences = AppPreferencesStore();

  /// App-wide selected language, persisted as a BCP 47 tag. A `null` locale
  /// follows the system. Owned here so the root `App` can rebuild the
  /// localized tree when the user switches languages in Settings.
  late final LocaleController localeController = LocaleController(
    repository: LocaleSettingsRepository(preferences: preferences),
  );
  late final AuthSessionStore authSession = AuthSessionStore(
    storage: secureStorage,
    config: config,
  );
  late final AuthService auth = AuthService(
    storage: secureStorage,
    sessionStore: authSession,
    config: config,
    endpoints: _endpoints,
  );
  late final SsoService sso = SsoService(
    storage: secureStorage,
    sessionStore: authSession,
    config: config,
    endpoints: _endpoints,
  );
  late final ServerSettingsService serverSettings = ServerSettingsService(
    storage: secureStorage,
    config: config,
    endpoints: _endpoints,
  );
  late final ApiClient apiClient = ApiClient(
    storage: secureStorage,
    sessionStore: authSession,
    authService: auth,
    config: config,
  );
  late final ActivityUploadService activityUpload = ActivityUploadService(
    apiClient: apiClient,
    config: ActivityUploadConfig.fromEndpoints(_endpoints),
    retryPolicy: const ActivityUploadRetryPolicy(maxAttempts: 3),
  );
  final LocationService location = LocationService();
  final ConnectivityService connectivity = ConnectivityService();
  late final LocalActivityGpxStorage localActivityGpxStorage =
      LocalActivityGpxStorage();
  late final LocalActivityRepository localActivities = LocalActivityRepository(
    gpxStorage: localActivityGpxStorage,
    store: SqfliteActivityStore(),
  );
  late final ActivityRetentionSettingsRepository activityRetentionSettings =
      ActivityRetentionSettingsRepository(storage: secureStorage);

  /// App-lifetime durable upload queue. Drains locally-stored activities whose
  /// upload has not yet succeeded; triggered on app-resume (see `app.dart`)
  /// and whenever connectivity is restored (via [connectivity]).
  late final ActivityUploadQueue activityUploadQueue = ActivityUploadQueue(
    repository: localActivities,
    uploadService: activityUpload,
    retentionSettingsRepository: activityRetentionSettings,
    isUploadAuthorized: auth.isAuthenticated,
    activeConnectionProfile: authSession.getConnectionProfile,
    diagnostics: diagnostics,
    connectivitySignal: connectivity.onOnlineChanged,
  );

  /// App-lifetime controller for the active activity recording session.
  ///
  /// Owned by [AppServices] so it survives tab navigation and can be used by
  /// non-map screens. Consumers obtain it from the app scope and must NOT
  /// dispose it — its lifetime is tied to [AppServices].
  late final ActivityRecordingController activityRecordingController =
      _buildActivityRecordingController();

  ActivityRecordingController _buildActivityRecordingController() {
    final controller = ActivityRecordingController(
      recordingService: createActivityRecordingService(),
      uploadService: activityUpload,
      localActivityRepository: localActivities,
      retentionSettingsRepository: activityRetentionSettings,
      isUploadAuthorized: auth.isAuthenticated,
      activeConnectionProfile: authSession.getConnectionProfile,
      diagnostics: diagnostics,
    );
    // When a recording ends, the native recorder releases the heart-rate
    // handoff (see _prepareNativeHeartRateSource); bring the Dart-side sensor
    // link back so it is ready again without the user reconnecting on the
    // Sensors screen.
    controller.addListener(
      () => _handleRecordingStatusForHeartRate(controller.state.status),
    );
    return controller;
  }

  final AppLinksService appLinks = DefaultAppLinksService();
  final UrlLauncherService urlLauncher = const UrlLauncherService();
  final ShareService share = ShareService();
  final PackageInfoService packageInfo = const PackageInfoService();

  // ── Health sync ──────────────────────────────────────────────────────────

  late final HealthSyncSettingsRepository healthSyncSettings =
      HealthSyncSettingsRepository(storage: secureStorage);

  late final HealthImportRepository healthImportRepository =
      HealthImportRepository();

  late final HealthSyncService healthSyncService = HealthSyncService(
    adapter: createHealthPlatformAdapter(),
    importRepository: healthImportRepository,
    localActivities: localActivities,
    uploadQueue: activityUploadQueue,
    gpxBuilder: const HealthWorkoutGpxBuilder(),
    syncSettings: healthSyncSettings,
    diagnostics: diagnostics,
    healthSyncEnabled: config.healthSyncEnabled,
    activeConnectionProfile: authSession.getConnectionProfile,
  );

  /// Creates a route-owned controller for health-platform workout sync.
  ///
  /// Health UI state contains profile-scoped rows and selections, so it must
  /// not outlive the route or survive a logout/login transition.
  HealthSyncController createHealthSyncController() {
    return HealthSyncController(
      service: healthSyncService,
      diagnostics: diagnostics,
      uploadCompletedSignal: activityUploadQueue.onDrainCompleted,
    );
  }

  /// Builds the concrete health-platform adapter for the current platform.
  ///
  /// Returns [HealthPackagePlatformAdapter] on Android/iOS; falls back to
  /// [UnsupportedHealthPlatformAdapter] on all other platforms (e.g. macOS,
  /// Linux, Windows, or the host test runner).
  HealthPlatformAdapter createHealthPlatformAdapter() {
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      return HealthPackagePlatformAdapter(
        health: Health(),
        diagnostics: diagnostics,
      );
    }
    return const UnsupportedHealthPlatformAdapter();
  }

  // ── External sensors (BLE) ─────────────────────────────────────────────────

  /// App-lifetime coordinator for external heart-rate sensors.
  ///
  /// Owned here so a live BLE connection survives navigation between screens
  /// and can feed the recording pipeline. Route controllers observe it but must
  /// not dispose it.
  late final HeartRateSensorService heartRateSensorService =
      HeartRateSensorService(
        adapter: createHeartRateSensorAdapter(),
        preferences: SensorPreferencesRepository(preferences: preferences),
        canAutoReconnect: _canAutoReconnectHeartRate,
      );

  /// Builds the BLE heart-rate sensor adapter for the current platform.
  ///
  /// Returns the `universal_ble`-backed adapter on Android/iOS; falls back
  /// to [UnsupportedHeartRateSensorAdapter] elsewhere (desktop, web, or the
  /// host test runtime) so the feature degrades gracefully without a BLE stack.
  HeartRateSensorAdapter createHeartRateSensorAdapter() {
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      return UniversalBleHeartRateSensorAdapter();
    }
    return const UnsupportedHeartRateSensorAdapter();
  }

  /// Builds the active-recording recorder for the current platform.
  ///
  /// Android and iOS use the native background-capable recorder. Other
  /// environments (such as the test/host runtime) fall back to the geolocator
  /// recorder backed by the durable [FileActiveActivityStore].
  ActivityLocationRecorder createActivityLocationRecorder({
    LocationService? locationService,
  }) {
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      return NativeActivityRecorderChannel();
    }
    return GeolocatorActivityLocationRecorder(
      store: FileActiveActivityStore(diagnostics: diagnostics),
      locationService: locationService ?? location,
      diagnostics: diagnostics,
    );
  }

  /// Assembles a ready-to-use [ActivityRecordingService] for the current
  /// platform, wiring the correct recorder and the shared [LocationService].
  ///
  /// Callers (e.g. screen factories) should prefer this over building the
  /// service and its recorder inline.
  ActivityRecordingService createActivityRecordingService({
    LocationService? locationService,
  }) {
    final loc = locationService ?? location;
    final usesNativeHeartRate = usesNativeHeartRateHandoff(
      defaultTargetPlatform,
    );
    return ActivityRecordingService(
      diagnostics: diagnostics,
      locationService: loc,
      recorder: createActivityLocationRecorder(locationService: loc),
      // Only Android hands the sensor off to the native foreground service,
      // whose FOREGROUND_SERVICE_CONNECTED_DEVICE model must own the single GATT
      // link. iOS keeps the Dart (universal_ble) connection — alive in the
      // background during an active recording via the bluetooth-central mode —
      // and feeds its live stream into the recording pipeline, so the sensor
      // stays connected and its BPM is shown live and stamped onto points.
      heartRateReadings: usesNativeHeartRate
          ? null
          : heartRateSensorService.heartRate.map(
              (sample) => (timestamp: sample.timestamp, bpm: sample.bpm),
            ),
      prepareHeartRateSource: usesNativeHeartRate
          ? _prepareNativeHeartRateSource
          : null,
    );
  }

  /// Whether [platform] hands the paired heart-rate sensor off to the native
  /// recorder for the duration of a recording.
  ///
  /// Only Android needs this: its foreground-service model
  /// (`FOREGROUND_SERVICE_CONNECTED_DEVICE`) owns the single GATT connection, so
  /// the Dart-side link is released and the native service captures BPM. iOS and
  /// every other platform keep the Dart (universal_ble) connection and feed its
  /// live stream into the recording pipeline instead, which keeps the sensor
  /// connected and its live BPM visible while recording.
  @visibleForTesting
  static bool usesNativeHeartRateHandoff(TargetPlatform platform) =>
      platform == TargetPlatform.android;

  /// Hands the paired heart-rate sensor off to the native recorder for the
  /// duration of a recording: disconnects the Dart-side BLE link (so the native
  /// foreground service can own the single GATT connection) and returns the
  /// device id to record from, or `null` when no sensor is paired.
  Future<String?> _prepareNativeHeartRateSource() async {
    final device =
        heartRateSensorService.connectedDevice ??
        await heartRateSensorService.rememberedDevice();
    if (device == null) {
      return null;
    }
    await heartRateSensorService.disconnect();
    return device.id;
  }

  /// Whether the heart-rate service may auto-reconnect right now.
  ///
  /// Only Android hands the sensor off: while a recording is active (or
  /// stopping) the native recorder owns the single BLE link handed off in
  /// [_prepareNativeHeartRateSource], so reconnecting the Dart side then would
  /// fight that connection and is suppressed until the recording finishes. On
  /// iOS and elsewhere the Dart link stays connected throughout, so reconnection
  /// is always allowed.
  bool _canAutoReconnectHeartRate() {
    if (!usesNativeHeartRateHandoff(defaultTargetPlatform)) {
      return true;
    }
    final status = activityRecordingController.state.status;
    return status != ActivityRecordingStatus.recording &&
        status != ActivityRecordingStatus.paused &&
        status != ActivityRecordingStatus.stopping;
  }

  ActivityRecordingStatus? _previousRecordingStatus;

  /// Reconnects the remembered heart-rate sensor when a recording leaves the
  /// phase that owns it (recording/paused/stopping) for a terminal one
  /// (completed/failed/idle). By this point the native recorder has released
  /// the BLE link, so the Dart side can reclaim it. No-ops on the non-native
  /// path, where the link was never handed off (still connected).
  void _handleRecordingStatusForHeartRate(ActivityRecordingStatus status) {
    final previous = _previousRecordingStatus;
    _previousRecordingStatus = status;
    if (heartRateHandoffReleased(previous, status)) {
      unawaited(heartRateSensorService.tryReconnectRemembered());
    }
  }

  /// Whether a recording status transition from [previous] to [current] means
  /// the native heart-rate handoff has just been released (the recording left
  /// the recording/paused/stopping phase for a terminal one).
  @visibleForTesting
  static bool heartRateHandoffReleased(
    ActivityRecordingStatus? previous,
    ActivityRecordingStatus current,
  ) {
    if (previous == null) {
      return false;
    }
    const owningSensor = {
      ActivityRecordingStatus.recording,
      ActivityRecordingStatus.paused,
      ActivityRecordingStatus.stopping,
    };
    return owningSensor.contains(previous) && !owningSensor.contains(current);
  }
}
