import 'package:endurain/app/app_services.dart';
import 'package:endurain/app/navigation/app_screens.dart';
import 'package:endurain/features/activity/screens/activity_details_screen.dart';
import 'package:endurain/features/activity/screens/activity_history_screen.dart';
import 'package:endurain/features/activity/screens/audio_announcement_settings_screen.dart';
import 'package:endurain/features/activity/screens/auto_pause_settings_screen.dart';
import 'package:endurain/features/activity/screens/start_countdown_settings_screen.dart';
import 'package:endurain/features/activity/widgets/activity_recording_overlay.dart';
import 'package:endurain/features/auth/screens/login_screen.dart';
import 'package:endurain/features/health/screens/health_sync_screen.dart';
import 'package:endurain/features/map/screens/map_screen.dart';
import 'package:endurain/features/map/screens/tile_server_settings_screen.dart';
import 'package:endurain/features/sensors/screens/sensor_settings_screen.dart';
import 'package:endurain/features/settings/screens/device_access_screen.dart';
import 'package:endurain/features/settings/screens/diagnostics_screen.dart';
import 'package:endurain/features/settings/screens/language_settings_screen.dart';
import 'package:endurain/features/settings/screens/server_settings_screen.dart';
import 'package:endurain/features/settings/screens/settings_screen.dart';
import 'package:endurain/features/settings/screens/units_settings_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// [AppScreens] is the composition point between the service graph and the
/// screens. These tests build every screen (without pumping it) so a broken
/// wiring, such as a missing dependency or a factory that throws, fails here
/// instead of on a device.
void main() {
  late AppServices services;
  late AppScreens screens;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    services = AppServices();
    screens = AppScreens(services);
  });

  Future<BuildContext> contextOf(WidgetTester tester) async {
    late BuildContext captured;
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          captured = context;
          return const SizedBox.shrink();
        },
      ),
    );
    return captured;
  }

  testWidgets('the map tab wires the recording overlay and its history', (
    tester,
  ) async {
    final context = await contextOf(tester);

    final map = screens.map(context) as MapScreen;
    expect(map.recoverActiveRecordingOnOpen, isTrue);
    expect(
      identical(map.activityController, services.activity.recordingController),
      isTrue,
    );

    final overlay = map.recordingOverlayBuilder(
      context,
      map.activityController,
      0,
    ) as ActivityRecordingOverlay;
    expect(
      overlay.readAudioAnnouncementSettings(),
      services.activity.audioAnnouncementSettingsController.settings,
    );
    expect(overlay.historyBuilder(context), isA<ActivityHistoryScreen>());
  });

  testWidgets('the login route builds its controller from the auth module', (
    tester,
  ) async {
    final login = screens.login() as LoginScreen;

    final controller = login.createController!();
    addTearDown(controller.dispose);
  });

  testWidgets('the activity history owns a fresh controller per route', (
    tester,
  ) async {
    final context = await contextOf(tester);

    final history = screens.activityHistory(context) as ActivityHistoryScreen;
    final first = history.createController!();
    final second = history.createController!();
    addTearDown(first.dispose);
    addTearDown(second.dispose);

    expect(identical(first, second), isFalse);
  });

  testWidgets('every settings destination builds its screen', (tester) async {
    final context = await contextOf(tester);

    final settings = screens.settings(
      context,
      isGuest: false,
      onLogout: () {},
    ) as SettingsScreen;
    final settingsController = settings.createController!();
    addTearDown(settingsController.dispose);

    final destinations = settings.destinations;
    expect(destinations.serverSettings(context), isA<ServerSettingsScreen>());
    expect(destinations.language(context), isA<LanguageSettingsScreen>());
    expect(destinations.units(context), isA<UnitsSettingsScreen>());
    expect(
      destinations.audioAnnouncements(context),
      isA<AudioAnnouncementSettingsScreen>(),
    );
    expect(destinations.sensors(context), isA<SensorSettingsScreen>());
    expect(destinations.activityHistory(context), isA<ActivityHistoryScreen>());
    expect(destinations.diagnostics(context), isA<DiagnosticsScreen>());

    final tileServer =
        destinations.tileServer(context) as TileServerSettingsScreen;
    final tileController = tileServer.createController!();
    addTearDown(tileController.dispose);

    final countdown =
        destinations.startCountdown(context) as StartCountdownSettingsScreen;
    final countdownController = countdown.createController!();
    addTearDown(countdownController.dispose);

    final autoPause =
        destinations.autoPause(context) as AutoPauseSettingsScreen;
    final autoPauseController = autoPause.createController!();
    addTearDown(autoPauseController.dispose);

    final healthSync = destinations.healthSync(context) as HealthSyncScreen;
    final healthController = healthSync.createController!();
    addTearDown(healthController.dispose);
    final details = healthSync.activityDetailsBuilder(
      context,
      'record-1',
    ) as ActivityDetailsScreen;
    expect(details.recordId, 'record-1');

    final deviceAccess =
        destinations.deviceAccess(context) as DeviceAccessScreen;
    final deviceHealthController = deviceAccess.createHealthController!();
    addTearDown(deviceHealthController.dispose);
  });
}
