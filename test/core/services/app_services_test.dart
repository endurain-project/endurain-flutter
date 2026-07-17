import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:endurain/core/config/app_config.dart';
import 'package:endurain/core/services/app_services.dart';
import 'package:endurain/features/activity/models/activity_recording_state.dart';
import 'package:endurain/features/activity/repositories/local_activity_repository.dart';
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

    test('heartRateHandoffReleased detects the end of a recording handoff', () {
      // The first observation (null previous) is never treated as a release.
      expect(
        AppServices.heartRateHandoffReleased(
          null,
          ActivityRecordingStatus.recording,
        ),
        isFalse,
      );

      // Leaving an owning phase (recording/paused/stopping) for a terminal one
      // releases the native heart-rate handoff.
      for (final previous in const [
        ActivityRecordingStatus.recording,
        ActivityRecordingStatus.paused,
        ActivityRecordingStatus.stopping,
      ]) {
        expect(
          AppServices.heartRateHandoffReleased(
            previous,
            ActivityRecordingStatus.completed,
          ),
          isTrue,
          reason: '$previous -> completed should release',
        );
      }
      expect(
        AppServices.heartRateHandoffReleased(
          ActivityRecordingStatus.recording,
          ActivityRecordingStatus.failed,
        ),
        isTrue,
      );
      expect(
        AppServices.heartRateHandoffReleased(
          ActivityRecordingStatus.stopping,
          ActivityRecordingStatus.idle,
        ),
        isTrue,
      );

      // Transitions within owning phases, or between terminal phases, do not.
      expect(
        AppServices.heartRateHandoffReleased(
          ActivityRecordingStatus.recording,
          ActivityRecordingStatus.paused,
        ),
        isFalse,
      );
      expect(
        AppServices.heartRateHandoffReleased(
          ActivityRecordingStatus.recording,
          ActivityRecordingStatus.stopping,
        ),
        isFalse,
      );
      expect(
        AppServices.heartRateHandoffReleased(
          ActivityRecordingStatus.completed,
          ActivityRecordingStatus.idle,
        ),
        isFalse,
      );
      expect(
        AppServices.heartRateHandoffReleased(
          ActivityRecordingStatus.idle,
          ActivityRecordingStatus.recording,
        ),
        isFalse,
      );
    });

    test('usesNativeHeartRateHandoff is Android-only', () {
      // Only Android releases the Dart BLE link to the native foreground
      // service (FOREGROUND_SERVICE_CONNECTED_DEVICE). iOS and every other
      // platform keep the Dart sensor connected and stream its BPM into the
      // recording pipeline, so live heart rate stays visible while recording.
      expect(
        AppServices.usesNativeHeartRateHandoff(TargetPlatform.android),
        isTrue,
      );
      for (final platform in const [
        TargetPlatform.iOS,
        TargetPlatform.macOS,
        TargetPlatform.linux,
        TargetPlatform.windows,
        TargetPlatform.fuchsia,
      ]) {
        expect(
          AppServices.usesNativeHeartRateHandoff(platform),
          isFalse,
          reason: '$platform should keep the Dart heart-rate connection',
        );
      }
    });
  });
}
