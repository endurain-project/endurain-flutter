import 'package:endurain/core/config/api_endpoints.dart';
import 'package:endurain/core/config/app_config.dart';
import 'package:endurain/core/services/api_client.dart';
import 'package:endurain/core/services/app_links_service.dart';
import 'package:endurain/core/services/app_preferences_store.dart';
import 'package:endurain/core/services/auth_session_store.dart';
import 'package:endurain/core/services/auth_service.dart';
import 'package:endurain/core/services/diagnostics_service.dart';
import 'package:endurain/core/services/location_service.dart';
import 'package:endurain/core/services/package_info_service.dart';
import 'package:endurain/core/services/secure_storage_service.dart';
import 'package:endurain/core/services/server_settings_service.dart';
import 'package:endurain/core/services/sso_service.dart';
import 'package:endurain/core/services/url_launcher_service.dart';
import 'package:endurain/features/activity/controllers/activity_recording_controller.dart';
import 'package:endurain/features/activity/repositories/activity_retention_settings_repository.dart';
import 'package:endurain/features/activity/repositories/file_active_activity_store.dart';
import 'package:endurain/features/activity/repositories/json_manifest_activity_store.dart';
import 'package:endurain/features/activity/repositories/local_activity_repository.dart';
import 'package:endurain/features/activity/repositories/sqflite_activity_store.dart';
import 'package:endurain/features/activity/services/activity_location_recorder.dart';
import 'package:endurain/features/activity/services/activity_recording_service.dart';
import 'package:endurain/features/activity/services/activity_upload_service.dart';
import 'package:endurain/features/activity/services/geolocator_activity_location_recorder.dart';
import 'package:endurain/features/activity/services/local_activity_gpx_storage.dart';
import 'package:endurain/features/activity/services/native_activity_recorder_channel.dart';
import 'package:flutter/foundation.dart';

class AppServices {
  AppServices({this.config = AppConfig.defaults});

  static final AppServices instance = AppServices();

  final DiagnosticsService diagnostics = DiagnosticsService();
  final AppConfig config;
  late final ApiEndpoints _endpoints = ApiEndpoints(config);
  late final SecureStorageService secureStorage = SecureStorageService();
  late final AppPreferencesStore preferences = AppPreferencesStore();
  late final AuthSessionStore authSession = AuthSessionStore(
    storage: secureStorage,
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
  );
  late final ActivityUploadService activityUpload = ActivityUploadService(
    apiClient: apiClient,
    config: ActivityUploadConfig.fromEndpoints(_endpoints),
    retryPolicy: const ActivityUploadRetryPolicy(maxAttempts: 3),
  );
  final LocationService location = LocationService();
  late final LocalActivityGpxStorage localActivityGpxStorage =
      LocalActivityGpxStorage();
  late final LocalActivityRepository localActivities = LocalActivityRepository(
    gpxStorage: localActivityGpxStorage,
    diagnostics: diagnostics,
    store: SqfliteActivityStore(
      manifestReader: () =>
          JsonManifestActivityStore(diagnostics: diagnostics).list(),
    ),
  );
  late final ActivityRetentionSettingsRepository activityRetentionSettings =
      ActivityRetentionSettingsRepository(storage: secureStorage);

  /// App-lifetime controller for the active activity recording session.
  ///
  /// Owned by [AppServices] so it survives tab navigation and can be used by
  /// non-map screens. Consumers obtain it from the app scope and must NOT
  /// dispose it — its lifetime is tied to [AppServices].
  late final ActivityRecordingController activityRecordingController =
      ActivityRecordingController(
        recordingService: createActivityRecordingService(),
        uploadService: activityUpload,
        localActivityRepository: localActivities,
        retentionSettingsRepository: activityRetentionSettings,
      );

  final AppLinksService appLinks = DefaultAppLinksService();
  final UrlLauncherService urlLauncher = const UrlLauncherService();
  final PackageInfoService packageInfo = const PackageInfoService();

  /// Builds the active-recording recorder for the current platform.
  ///
  /// Android and iOS use the native background-capable recorder. Other
  /// platforms (such as macOS) fall back to the geolocator recorder backed by
  /// the durable [FileActiveActivityStore].
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
    return ActivityRecordingService(
      diagnostics: diagnostics,
      locationService: loc,
      recorder: createActivityLocationRecorder(locationService: loc),
    );
  }
}
