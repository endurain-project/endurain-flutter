import 'package:endurain/core/config/app_config.dart';
import 'package:endurain/core/constants/map_constants.dart';
import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/features/map/controllers/tile_server_settings_controller.dart';
import 'package:endurain/features/map/repositories/map_settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_preferences_store.dart';

void main() {
  group('TileServerSettingsController', () {
    late FakePreferencesStore prefs;

    setUp(() => prefs = FakePreferencesStore());

    TileServerSettingsController controllerFor({
      String? serverUrl = 'https://endurain.example.test',
      AppConfig config = AppConfig.defaults,
      MapSettingsRepository? repository,
    }) {
      final controller = TileServerSettingsController(
        repository:
            repository ??
            MapSettingsRepository(preferences: prefs, config: config),
        config: config,
        loadServerUrl: () async => serverUrl,
      );
      addTearDown(controller.dispose);
      return controller;
    }

    test('starts in the loading state before load runs', () {
      final controller = controllerFor();

      expect(controller.isLoading, isTrue);
      expect(controller.serverUrl, isNull);
      expect(controller.tileServerUrl, isEmpty);
    });

    test('load reads the tile URL and server, notifying twice', () async {
      await prefs.write(
        key: 'tile_server_url',
        value: 'https://tiles.example.test/{z}/{x}/{y}.png',
      );
      final controller = controllerFor();
      final loadingStates = <bool>[];
      controller.addListener(() => loadingStates.add(controller.isLoading));

      await controller.load();

      expect(loadingStates, [true, false]);
      expect(controller.serverUrl, 'https://endurain.example.test');
      expect(
        controller.tileServerUrl,
        'https://tiles.example.test/{z}/{x}/{y}.png',
      );
    });

    test('load falls back to the default tile URL', () async {
      final controller = controllerFor();

      await controller.load();

      expect(controller.tileServerUrl, MapConstants.defaultTileServerUrl);
    });

    test('a failing load clears loading and records the error', () async {
      var failServerUrl = true;
      final controller = TileServerSettingsController(
        repository: MapSettingsRepository(preferences: prefs),
        config: AppConfig.defaults,
        loadServerUrl: () async {
          if (failServerUrl) {
            throw const AppException(AppErrorCode.secureStorageReadFailed);
          }
          return 'https://endurain.example.test';
        },
      );
      addTearDown(controller.dispose);

      await controller.load();

      expect(controller.isLoading, isFalse);
      expect(controller.hasLoadError, isTrue);

      // A retry that succeeds clears the error.
      failServerUrl = false;
      await controller.load();

      expect(controller.hasLoadError, isFalse);
      expect(controller.serverUrl, 'https://endurain.example.test');
      expect(controller.tileServerUrl, MapConstants.defaultTileServerUrl);
    });

    group('evaluateTileHost', () {
      test('allows an empty or hostless tile URL', () async {
        final controller = controllerFor();
        await controller.load();

        expect(controller.evaluateTileHost(''), TileServerHostDecision.allowed);
        expect(
          controller.evaluateTileHost('/relative/{z}/{x}/{y}.png'),
          TileServerHostDecision.allowed,
        );
      });

      test('allows a tile host equal to the server host', () async {
        final controller = controllerFor();
        await controller.load();

        expect(
          controller.evaluateTileHost(
            'https://endurain.example.test/tiles/{z}/{x}/{y}.png',
          ),
          TileServerHostDecision.allowed,
        );
      });

      test('needs confirmation for a different tile host', () async {
        final controller = controllerFor();
        await controller.load();

        expect(
          controller.evaluateTileHost(
            'https://tiles.other.test/{z}/{x}/{y}.png',
          ),
          TileServerHostDecision.needsConfirmation,
        );
      });

      test('allows any host when no server host is configured', () async {
        final controller = controllerFor(serverUrl: null);
        await controller.load();

        expect(
          controller.evaluateTileHost(
            'https://tiles.other.test/{z}/{x}/{y}.png',
          ),
          TileServerHostDecision.allowed,
        );
      });

      test('blocks a host outside the managed allowlist', () async {
        final controller = controllerFor(
          config: const AppConfig(
            allowedTileServerHosts: {'endurain.example.test'},
          ),
        );
        await controller.load();

        expect(
          controller.evaluateTileHost(
            'https://not-allowed.test/{z}/{x}/{y}.png',
          ),
          TileServerHostDecision.blocked,
        );
      });

      test('allows an allowlisted host that also matches the server', () async {
        final controller = controllerFor(
          config: const AppConfig(
            allowedTileServerHosts: {'endurain.example.test'},
          ),
        );
        await controller.load();

        expect(
          controller.evaluateTileHost(
            'https://endurain.example.test/tiles/{z}/{x}/{y}.png',
          ),
          TileServerHostDecision.allowed,
        );
      });
    });

    test('saveTileServerUrl persists and updates state', () async {
      final controller = controllerFor();
      await controller.load();

      await controller.saveTileServerUrl(
        'https://tiles.new.test/{z}/{x}/{y}.png',
      );

      expect(
        await prefs.read(key: 'tile_server_url'),
        'https://tiles.new.test/{z}/{x}/{y}.png',
      );
      expect(
        controller.tileServerUrl,
        'https://tiles.new.test/{z}/{x}/{y}.png',
      );
    });

    test('saveTileServerUrl fails without an active connection', () async {
      // The app's repository is scoped to the signed-in server; with no
      // origin there is nowhere to store the value.
      final controller = controllerFor(
        repository: MapSettingsRepository(
          preferences: prefs,
          activeConnectionOrigin: () async => null,
        ),
      );
      await controller.load();

      await expectLater(
        controller.saveTileServerUrl('https://tiles.new.test/{z}/{x}/{y}.png'),
        throwsA(
          isA<AppException>().having(
            (e) => e.code,
            'code',
            AppErrorCode.notAuthenticated,
          ),
        ),
      );
      expect(controller.tileServerUrl, MapConstants.defaultTileServerUrl);
    });
  });
}
