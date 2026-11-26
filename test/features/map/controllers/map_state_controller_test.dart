import 'package:endurain/core/constants/map_constants.dart';
import 'package:endurain/core/location/location_service.dart';
import 'package:endurain/features/map/controllers/map_state_controller.dart';
import 'package:endurain/features/map/repositories/map_settings_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_location_platform_adapter.dart';
import '../../../helpers/fake_preferences_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MapSettingsRepository makeSettings() {
    return MapSettingsRepository(preferences: FakePreferencesStore());
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

    test('reloads the tile URL when it changes', () async {
      final changes = TileServerUrlChanges();
      addTearDown(changes.dispose);
      final settings = MapSettingsRepository(
        preferences: FakePreferencesStore(),
        changes: changes,
      );
      final controller = MapStateController(
        locationService: LocationService(
          platformAdapter: FakeLocationPlatformAdapter(),
        ),
        mapSettingsRepository: settings,
      );
      addTearDown(controller.dispose);
      await controller.initialize();
      expect(controller.tileServerUrl, MapConstants.defaultTileServerUrl);

      // Saved on the Map tiles screen while the map tab stays alive.
      await settings.saveTileServerUrl(
        'https://tiles.example.test/{z}/{x}/{y}.png',
      );
      await pumpEventQueue();

      expect(
        controller.tileServerUrl,
        'https://tiles.example.test/{z}/{x}/{y}.png',
      );
    });

    test('reloads the tile URL when the connection changes', () async {
      final changes = TileServerUrlChanges();
      addTearDown(changes.dispose);
      final prefs = FakePreferencesStore();
      const origin = 'https://endurain.example.test';
      String? activeOrigin = origin;
      final settings = MapSettingsRepository(
        preferences: prefs,
        activeConnectionOrigin: () async => activeOrigin,
        changes: changes,
      );
      await settings.saveTileServerUrl(
        'https://tiles.example.test/{z}/{x}/{y}.png',
      );
      final controller = MapStateController(
        locationService: LocationService(
          platformAdapter: FakeLocationPlatformAdapter(),
        ),
        mapSettingsRepository: settings,
      );
      addTearDown(controller.dispose);
      await controller.initialize();
      expect(
        controller.tileServerUrl,
        'https://tiles.example.test/{z}/{x}/{y}.png',
      );

      // Signing out drops the origin; the app signals the change.
      activeOrigin = null;
      changes.notifyChanged();
      await pumpEventQueue();

      expect(controller.tileServerUrl, MapConstants.defaultTileServerUrl);
    });

    test('stops listening for tile URL changes once disposed', () async {
      final changes = _CountingTileServerUrlChanges();
      addTearDown(changes.dispose);
      final controller = MapStateController(
        locationService: LocationService(
          platformAdapter: FakeLocationPlatformAdapter(),
        ),
        mapSettingsRepository: MapSettingsRepository(
          preferences: FakePreferencesStore(),
          changes: changes,
        ),
      );
      await controller.initialize();

      expect(changes.listenerCount, 1);

      controller.dispose();

      expect(changes.listenerCount, 0);
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

    group('app lifecycle', () {
      Future<(MapStateController, FakeLocationPlatformAdapter)> make() async {
        final platform = FakeLocationPlatformAdapter(
          currentPosition: testPosition(latitude: 41.1, longitude: -8.6),
        );
        final controller = MapStateController(
          locationService: LocationService(platformAdapter: platform),
          mapSettingsRepository: makeSettings(),
        );
        await controller.initialize();
        addTearDown(() async {
          controller.dispose();
          await platform.close();
        });
        return (controller, platform);
      }

      test('setAppInForeground(false) stops position updates', () async {
        final (controller, platform) = await make();

        controller.setAppInForeground(false);
        platform.addPosition(testPosition(latitude: 99.0, longitude: 0.0));
        await pumpEventQueue();

        expect(controller.currentLocation.latitude, closeTo(41.1, 0.001));
      });

      test('setAppInForeground(true) resumes position updates', () async {
        final (controller, platform) = await make();

        controller.setAppInForeground(false);
        controller.setAppInForeground(true);
        platform.addPosition(testPosition(latitude: 52.0, longitude: 13.0));
        await pumpEventQueue();

        expect(controller.currentLocation.latitude, closeTo(52.0, 0.001));
      });

      test(
        'returning to the foreground does not resume while recording',
        () async {
          final (controller, platform) = await make();

          controller.setRecordingActive(true);
          controller.setAppInForeground(false);
          controller.setAppInForeground(true);
          platform.addPosition(testPosition(latitude: 99.0, longitude: 0.0));
          await pumpEventQueue();

          expect(controller.currentLocation.latitude, closeTo(41.1, 0.001));
        },
      );

      test(
        'a recording ending while backgrounded keeps the stream off',
        () async {
          final (controller, platform) = await make();

          controller.setAppInForeground(false);
          controller.setRecordingActive(true);
          controller.setRecordingActive(false);
          platform.addPosition(testPosition(latitude: 99.0, longitude: 0.0));
          await pumpEventQueue();

          expect(controller.currentLocation.latitude, closeTo(41.1, 0.001));
        },
      );
    });
  });
}

class _CountingTileServerUrlChanges extends TileServerUrlChanges {
  int listenerCount = 0;

  @override
  void addListener(VoidCallback listener) {
    listenerCount++;
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    listenerCount--;
    super.removeListener(listener);
  }
}
