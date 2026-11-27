import 'package:endurain/app/app_services.dart';
import 'package:endurain/features/activity/controllers/auto_pause_settings_controller.dart';
import 'package:endurain/features/activity/controllers/start_countdown_settings_controller.dart';
import 'package:endurain/features/activity/screens/activity_details_screen.dart';
import 'package:endurain/features/activity/screens/activity_history_screen.dart';
import 'package:endurain/features/activity/screens/audio_announcement_settings_screen.dart';
import 'package:endurain/features/activity/screens/auto_pause_settings_screen.dart';
import 'package:endurain/features/activity/screens/start_countdown_settings_screen.dart';
import 'package:endurain/features/activity/widgets/activity_recording_overlay.dart';
import 'package:endurain/features/auth/controllers/login_controller.dart';
import 'package:endurain/features/auth/screens/login_screen.dart';
import 'package:endurain/features/auth/services/auth_coordinator.dart';
import 'package:endurain/features/health/screens/health_sync_screen.dart';
import 'package:endurain/features/map/controllers/tile_server_settings_controller.dart';
import 'package:endurain/features/map/screens/map_screen.dart';
import 'package:endurain/features/map/screens/tile_server_settings_screen.dart';
import 'package:endurain/features/sensors/models/sensor_bluetooth_state.dart';
import 'package:endurain/features/sensors/screens/sensor_settings_screen.dart';
import 'package:endurain/features/settings/controllers/settings_controller.dart';
import 'package:endurain/features/settings/models/bluetooth_access_state.dart';
import 'package:endurain/features/settings/repositories/server_settings_repository.dart';
import 'package:endurain/features/settings/screens/device_access_screen.dart';
import 'package:endurain/features/settings/screens/diagnostics_screen.dart';
import 'package:endurain/features/settings/screens/language_settings_screen.dart';
import 'package:endurain/features/settings/screens/server_settings_screen.dart';
import 'package:endurain/features/settings/screens/settings_destinations.dart';
import 'package:endurain/features/settings/screens/settings_screen.dart';
import 'package:endurain/features/settings/screens/units_settings_screen.dart';
import 'package:flutter/widgets.dart';

/// Builds every screen the app shows, handing each only the dependencies it
/// declares.
///
/// This is the one place screens meet [AppServices]: a screen's constructor
/// lists what it really uses (a controller, a repository, a factory), so a
/// feature never reaches into the whole service graph. Wiring a new
/// dependency into a screen means editing it here, not the screen.
class AppScreens {
  const AppScreens(this._services);

  final AppServices _services;

  /// The map tab, with the recording overlay laid over it.
  Widget map(BuildContext context) {
    final activity = _services.activity;
    return MapScreen(
      activityController: activity.recordingController,
      locationService: _services.infra.location,
      urlLauncher: _services.infra.urlLauncher,
      mapSettings: _services.createMapSettingsRepository(),
      sensorServices: _services.sensors.services,
      // The real app resumes a recording the OS killed mid-activity.
      recoverActiveRecordingOnOpen: true,
      recordingOverlayBuilder: (context, controller, trailingReservedWidth) =>
          ActivityRecordingOverlay(
            controller: controller,
            trailingReservedWidth: trailingReservedWidth,
            startCountdownSettings: activity.startCountdownSettings,
            startCountdownPlatform: activity.startCountdownPlatform,
            readAudioAnnouncementSettings: () =>
                activity.audioAnnouncementSettingsController.settings,
            historyBuilder: activityHistory,
          ),
    );
  }

  /// The settings tab. [onLogout] is forwarded to the server settings page,
  /// [onSignIn] is what a guest's "connect a server" entry does.
  Widget settings(
    BuildContext context, {
    required bool isGuest,
    VoidCallback? onLogout,
    VoidCallback? onSignIn,
  }) {
    final infra = _services.infra;
    return SettingsScreen(
      destinations: _settingsDestinations(onLogout),
      localeController: infra.localeController,
      urlLauncherService: infra.urlLauncher,
      healthSyncEnabled: _services.config.healthSyncEnabled,
      isGuest: isGuest,
      onSignIn: onSignIn,
      createController: () => SettingsController(
        packageInfoService: infra.packageInfo,
        secureStorage: infra.secureStorage,
        connectionChanges: _services.connectionChanges,
      ),
    );
  }

  /// The login route.
  Widget login({VoidCallback? onLoginSuccess, VoidCallback? onCancel}) {
    final infra = _services.infra;
    final auth = _services.auth;
    return LoginScreen(
      onLoginSuccess: onLoginSuccess,
      onCancel: onCancel,
      urlLauncherService: infra.urlLauncher,
      createController: () => LoginController(
        authCoordinator: AuthCoordinator(
          authService: auth.service,
          ssoService: auth.sso,
          serverSettingsService: auth.serverSettings,
        ),
        appLinksService: infra.appLinks,
        saveServerSettings: _services
            .createMapSettingsRepository()
            .saveFromServerSettings,
        config: _services.config,
        diagnostics: infra.diagnostics,
      ),
    );
  }

  /// The local activity history, opened from Settings and from a finished
  /// recording.
  Widget activityHistory(BuildContext context) {
    return ActivityHistoryScreen(
      urlLauncher: _services.infra.urlLauncher,
      createController: _services.createLocalActivityHistoryController,
      uploadQueue: _services.activity.uploadQueue,
      mapSettingsRepository: _services.createMapSettingsRepository(),
    );
  }

  /// Maps the sensors feature's Bluetooth state onto what the Device access
  /// screen shows, so `settings` never imports `sensors`.
  Future<BluetoothAccessState> _bluetoothAccess(
    Future<SensorBluetoothState> Function() read,
  ) async {
    return switch (await read()) {
      SensorBluetoothState.ready => BluetoothAccessState.ready,
      SensorBluetoothState.off => BluetoothAccessState.off,
      SensorBluetoothState.unauthorized => BluetoothAccessState.blocked,
      SensorBluetoothState.unsupported => BluetoothAccessState.unavailable,
      SensorBluetoothState.unknown => BluetoothAccessState.notDetermined,
    };
  }

  SettingsDestinations _settingsDestinations(VoidCallback? onLogout) {
    final infra = _services.infra;
    final activity = _services.activity;
    final sensors = _services.sensors;
    final health = _services.health;
    final healthSyncEnabled = _services.config.healthSyncEnabled;

    return SettingsDestinations(
      serverSettings: (context) => ServerSettingsScreen(
        onLogout: onLogout,
        repository: ServerSettingsRepository(
          storage: infra.secureStorage,
          authService: _services.auth.service,
        ),
      ),
      language: (context) =>
          LanguageSettingsScreen(localeController: infra.localeController),
      units: (context) =>
          UnitsSettingsScreen(controller: infra.measurementSystemController),
      tileServer: (context) => TileServerSettingsScreen(
        createController: () => TileServerSettingsController(
          repository: _services.createMapSettingsRepository(),
          config: _services.config,
          loadServerUrl: infra.secureStorage.getServerUrl,
        ),
      ),
      startCountdown: (context) => StartCountdownSettingsScreen(
        createController: () => StartCountdownSettingsController(
          repository: activity.startCountdownSettings,
        ),
      ),
      autoPause: (context) => AutoPauseSettingsScreen(
        createController: () =>
            AutoPauseSettingsController(repository: activity.autoPauseSettings),
      ),
      audioAnnouncements: (context) => AudioAnnouncementSettingsScreen(
        controller: activity.audioAnnouncementSettingsController,
      ),
      sensors: (context) => SensorSettingsScreen(
        heartRateService: sensors.heartRate,
        powerService: sensors.power,
        cadenceService: sensors.cadence,
        openAppSettings: infra.location.openAppSettings,
      ),
      healthSync: (context) => HealthSyncScreen(
        createController: health.createSyncController,
        // Standalone (not beside a history list), so it owns its controller.
        activityDetailsBuilder: (context, recordId) => ActivityDetailsScreen(
          recordId: recordId,
          urlLauncher: infra.urlLauncher,
          createController: _services.createLocalActivityHistoryController,
        ),
      ),
      activityHistory: activityHistory,
      deviceAccess: (context) => DeviceAccessScreen(
        locationService: infra.location,
        createHealthController: health.createSyncController,
        healthSyncEnabled: healthSyncEnabled,
        checkBluetoothAccess: () =>
            _bluetoothAccess(sensors.heartRate.currentBluetoothState),
        requestBluetoothAccess: () async {
          await sensors.heartRate.ensurePermissions();
          return _bluetoothAccess(sensors.heartRate.currentBluetoothState);
        },
      ),
      diagnostics: (context) => DiagnosticsScreen(
        diagnostics: infra.diagnostics,
        crashReporting: infra.crashReporting,
      ),
    );
  }
}
