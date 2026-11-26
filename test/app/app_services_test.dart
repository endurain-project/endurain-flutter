import 'package:endurain/app/app_services.dart';
import 'package:endurain/core/config/app_config.dart';
import 'package:endurain/features/activity/repositories/local_activity_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    // The recording service now depends (via the heart-rate sensor service) on
    // the preferences store, so the async shared-preferences platform must be
    // mocked here too.
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  group('AppServices', () {
    test('default constructor uses AppConfig.defaults', () {
      final services = AppServices();
      expect(services.config, AppConfig.defaults);
      expect(services.config.cloudBaseUrl, isNull);
    });

    test('constructor preserves supplied config', () {
      const custom = AppConfig(cloudBaseUrl: 'https://app.endurain.test');
      final services = AppServices(config: custom);
      expect(services.config.cloudBaseUrl, 'https://app.endurain.test');
      expect(
        services.config.allowInsecureTransportFor('http://app.endurain.test'),
        isFalse,
      );
    });

    test('map repositories share one tile URL change signal', () {
      final services = AppServices();

      expect(
        identical(
          services.createMapSettingsRepository().changes,
          services.tileServerUrlChanges,
        ),
        isTrue,
      );
    });

    test('a session change signals the map and connection listeners', () {
      final services = AppServices();
      var tileChanges = 0;
      var connectionChanges = 0;
      services.tileServerUrlChanges.addListener(() => tileChanges++);
      services.connectionChanges.addListener(() => connectionChanges++);

      services.notifyConnectionChanged();

      expect(tileChanges, 1);
      expect(connectionChanges, 1);
    });

    test('activity.recordingController is an app-lifetime singleton', () {
      final services = AppServices();

      // The controller is documented as owned by AppServices so it survives
      // tab navigation; repeated reads must return the identical instance.
      expect(
        identical(
          services.activity.recordingController,
          services.activity.recordingController,
        ),
        isTrue,
      );
    });

    test(
      'createActivityRecordingService returns a fresh instance per call',
      () {
        final services = AppServices();

        // It is a factory (not a cached getter): each screen that builds a
        // recording session must get its own service, otherwise disposing one
        // would tear down another screen's recorder.
        final first = services.activity.createRecordingService();
        final second = services.activity.createRecordingService();
        expect(identical(first, second), isFalse);
      },
    );

    test('localActivities is a cached singleton', () {
      final services = AppServices();

      // It is a `late final` getter, so every consumer (the recording
      // controller, the upload queue, history screens) shares one repository
      // instance and therefore one consistent view of locally stored data.
      expect(
        identical(
          services.activity.localActivities,
          services.activity.localActivities,
        ),
        isTrue,
      );
      expect(services.activity.localActivities, isA<LocalActivityRepository>());
    });
  });
}
