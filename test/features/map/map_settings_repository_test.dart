import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:endurain/core/constants/map_constants.dart';
import 'package:endurain/core/models/server_settings.dart';
import 'package:endurain/core/services/app_preferences_store.dart';
import 'package:endurain/features/map/map_settings_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late AppPreferencesStore prefs;
  late MapSettingsRepository repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('map_settings_repo_test_');
    prefs = AppPreferencesStore(supportDirectoryProvider: () async => tempDir);
    repository = MapSettingsRepository(preferences: prefs);
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  group('MapSettingsRepository', () {
    test('uses the default tile server when none is stored', () async {
      expect(
        await repository.getTileServerUrl(),
        MapConstants.defaultTileServerUrl,
      );
    });

    test('saves and loads the configured tile server', () async {
      await repository.saveTileServerUrl(
        'https://tiles.example.test/{z}/{x}/{y}.png',
      );

      expect(
        await repository.getTileServerUrl(),
        'https://tiles.example.test/{z}/{x}/{y}.png',
      );
    });

    group('saveFromServerSettings', () {
      test('persists non-empty tile URL, attribution, and map color', () async {
        final settings = ServerSettings.fromJson({
          'tileserver_url': 'https://tiles.test/{z}/{x}/{y}.png',
          'tileserver_attribution': 'OpenStreetMap',
          'map_background_color': '#102030',
        });

        await repository.saveFromServerSettings(settings);

        expect(
          await repository.getTileServerUrl(),
          'https://tiles.test/{z}/{x}/{y}.png',
        );
        expect(await repository.getTileServerAttribution(), 'OpenStreetMap');
        expect(await repository.getMapBackgroundColor(), '#102030');
      });

      test('does not overwrite stored values when fields are null', () async {
        await repository.saveTileServerUrl(
          'https://tiles.previous.test/{z}/{x}/{y}.png',
        );

        // fromJson defaults tileserver_url to null when not present.
        final settings = ServerSettings.fromJson({});

        await repository.saveFromServerSettings(settings);

        // Previous value must still be there.
        expect(
          await repository.getTileServerUrl(),
          'https://tiles.previous.test/{z}/{x}/{y}.png',
        );
      });

      test(
        'does not overwrite stored values when fields are empty strings',
        () async {
          await repository.saveTileServerUrl(
            'https://tiles.previous.test/{z}/{x}/{y}.png',
          );

          final settings = ServerSettings.fromJson({
            'tileserver_url': '',
            'tileserver_attribution': '',
            'map_background_color': '',
          });

          await repository.saveFromServerSettings(settings);

          expect(
            await repository.getTileServerUrl(),
            'https://tiles.previous.test/{z}/{x}/{y}.png',
          );
        },
      );
    });
  });
}
