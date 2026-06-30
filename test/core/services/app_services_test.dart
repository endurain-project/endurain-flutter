import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:endurain/core/config/app_config.dart';
import 'package:endurain/core/services/app_services.dart';
import 'package:endurain/features/activity/repositories/local_activity_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
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

    test('activityRecordingController is an app-lifetime singleton', () {
      final services = AppServices();

      // The controller is documented as owned by AppServices so it survives
      // tab navigation; repeated reads must return the identical instance.
      expect(
        identical(
          services.activityRecordingController,
          services.activityRecordingController,
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
        final first = services.createActivityRecordingService();
        final second = services.createActivityRecordingService();
        expect(identical(first, second), isFalse);
      },
    );

    test('localActivities is a cached singleton', () {
      final services = AppServices();

      // It is a `late final` getter, so every consumer (the recording
      // controller, the upload queue, history screens) shares one repository
      // instance and therefore one consistent view of locally stored data.
      expect(
        identical(services.localActivities, services.localActivities),
        isTrue,
      );
      expect(services.localActivities, isA<LocalActivityRepository>());
    });
  });
}
