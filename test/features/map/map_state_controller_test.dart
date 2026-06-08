import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:endurain/core/services/app_preferences_store.dart';
import 'package:endurain/core/services/location_service.dart';
import 'package:endurain/features/map/map_settings_repository.dart';
import 'package:endurain/features/map/map_state_controller.dart';

import '../../helpers/fake_location_platform_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('map_state_ctrl_test_');
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  MapSettingsRepository makeSettings() {
    return MapSettingsRepository(
      preferences: AppPreferencesStore(
        supportDirectoryProvider: () async => tempDir,
      ),
    );
  }

  group('MapStateController', () {
    test('loads tile settings and current location', () async {
      final settings = makeSettings();
      await settings.saveTileServerUrl(
        'https://tiles.example.test/{z}/{x}/{y}.png',
      );
      final platform = FakeLocationPlatformAdapter(
        currentPosition: testPosition(
          latitude: 41.1,
          longitude: -8.6,
          heading: 45,
        ),
      );
      final controller = MapStateController(
        locationService: LocationService(platformAdapter: platform),
        mapSettingsRepository: settings,
      );

      await controller.initialize();

      expect(
        controller.tileServerUrl,
        'https://tiles.example.test/{z}/{x}/{y}.png',
      );
      expect(controller.hasLocationPermission, isTrue);
      expect(controller.currentLocation.latitude, 41.1);
      expect(controller.currentLocation.longitude, -8.6);
      expect(controller.heading, 45);
      controller.dispose();
    });

    test('updates location from the position stream', () async {
      final platform = FakeLocationPlatformAdapter(
        currentPosition: testPosition(latitude: 41.1, longitude: -8.6),
      );
      final controller = MapStateController(
        locationService: LocationService(platformAdapter: platform),
        mapSettingsRepository: makeSettings(),
      );

      await controller.initialize();
      platform.addPosition(
        testPosition(latitude: 42.0, longitude: -9.0, heading: 180),
      );
      await Future<void>.delayed(Duration.zero);

      expect(controller.currentLocation.latitude, 42.0);
      expect(controller.currentLocation.longitude, -9.0);
      expect(controller.heading, 180);
      controller.dispose();
      await platform.close();
    });

    test('surfaces position stream errors without throwing', () async {
      final platform = FakeLocationPlatformAdapter(
        currentPosition: testPosition(latitude: 41.1, longitude: -8.6),
      );
      final controller = MapStateController(
        locationService: LocationService(platformAdapter: platform),
        mapSettingsRepository: makeSettings(),
      );

      await controller.initialize();
      platform.addPositionError(StateError('stream stopped'));
      await pumpEventQueue();

      expect(controller.hasLocationError, isTrue);
      expect(controller.hasLocationPermission, isFalse);
      expect(controller.isLoadingLocation, isFalse);
      controller.dispose();
      await platform.close();
    });

    test('toggles and unlocks location lock', () {
      final controller = MapStateController(
        locationService: LocationService(
          platformAdapter: FakeLocationPlatformAdapter(),
        ),
        mapSettingsRepository: makeSettings(),
      );

      expect(controller.isLocationLocked, isTrue);
      controller.toggleLocationLock();
      expect(controller.isLocationLocked, isFalse);
      controller.unlockLocation();
      expect(controller.isLocationLocked, isFalse);
      controller.dispose();
    });

    test(
      'setRecordingActive(true) stops position updates from stream',
      () async {
        final platform = FakeLocationPlatformAdapter(
          currentPosition: testPosition(latitude: 41.1, longitude: -8.6),
        );
        final controller = MapStateController(
          locationService: LocationService(platformAdapter: platform),
          mapSettingsRepository: makeSettings(),
        );

        await controller.initialize();
        final locationAfterInit = controller.currentLocation;

        controller.setRecordingActive(true);

        // Emit a new position; the stream is cancelled so it must not update.
        platform.addPosition(testPosition(latitude: 99.0, longitude: 0.0));
        await Future<void>.delayed(Duration.zero);

        expect(controller.currentLocation, locationAfterInit);
        controller.dispose();
        await platform.close();
      },
    );

    test(
      'setRecordingActive(false) resumes position updates from stream',
      () async {
        final platform = FakeLocationPlatformAdapter(
          currentPosition: testPosition(latitude: 41.1, longitude: -8.6),
        );
        final controller = MapStateController(
          locationService: LocationService(platformAdapter: platform),
          mapSettingsRepository: makeSettings(),
        );

        await controller.initialize();

        controller.setRecordingActive(true);
        controller.setRecordingActive(false);

        // Stream is re-subscribed; new positions must be applied.
        platform.addPosition(testPosition(latitude: 52.0, longitude: 13.0));
        await Future<void>.delayed(Duration.zero);

        expect(controller.currentLocation.latitude, closeTo(52.0, 0.001));
        expect(controller.currentLocation.longitude, closeTo(13.0, 0.001));
        controller.dispose();
        await platform.close();
      },
    );
  });
}
