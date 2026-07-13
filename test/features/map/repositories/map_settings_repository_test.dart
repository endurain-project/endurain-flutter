import 'package:flutter_test/flutter_test.dart';
import 'package:endurain/core/constants/map_constants.dart';
import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/features/map/repositories/map_settings_repository.dart';
import 'package:endurain/core/models/server_settings.dart';

import '../../../helpers/fake_preferences_store.dart';

void main() {
  const originA = 'https://a.example';
  const originB = 'https://b.example';
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakePreferencesStore prefs;
  late MapSettingsRepository repository;

  setUp(() {
    prefs = FakePreferencesStore();
    repository = MapSettingsRepository(preferences: prefs);
  });

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

    test('rejects an invalid tile server URL at the boundary', () async {
      await expectLater(
        repository.saveTileServerUrl('not a url'),
        throwsA(
          isA<AppException>().having(
            (e) => e.code,
            'code',
            AppErrorCode.invalidTileServerUrl,
          ),
        ),
      );

      // Nothing was persisted, so the default still applies.
      expect(
        await repository.getTileServerUrl(),
        MapConstants.defaultTileServerUrl,
      );
    });

    test(
      'skips an invalid server-provided tile URL without throwing',
      () async {
        final settings = ServerSettings.fromJson({
          'tileserver_url': 'not a url',
          'tileserver_attribution': 'OpenStreetMap',
        });

        await repository.saveFromServerSettings(settings, origin: originA);

        // Invalid URL skipped; attribution still saved.
        expect(
          await repository.getTileServerUrl(origin: originA),
          MapConstants.defaultTileServerUrl,
        );
      },
    );

    group('saveFromServerSettings', () {
      test('persists non-empty tile URL, attribution, and map color', () async {
        final settings = ServerSettings.fromJson({
          'tileserver_url': 'https://tiles.test/{z}/{x}/{y}.png',
          'tileserver_attribution': 'OpenStreetMap',
          'map_background_color': '#102030',
        });

        await repository.saveFromServerSettings(settings, origin: originA);

        expect(
          await repository.getTileServerUrl(origin: originA),
          'https://tiles.test/{z}/{x}/{y}.png',
        );
      });

      test('clears the origin value when server settings omit it', () async {
        await repository.saveTileServerUrl(
          'https://tiles.previous.test/{z}/{x}/{y}.png',
          origin: originA,
        );

        // fromJson defaults tileserver_url to null when not present.
        final settings = ServerSettings.fromJson({});

        await repository.saveFromServerSettings(settings, origin: originA);

        // Previous value must still be there.
        expect(
          await repository.getTileServerUrl(origin: originA),
          MapConstants.defaultTileServerUrl,
        );
      });

      test(
        'does not overwrite stored values when fields are empty strings',
        () async {
          await repository.saveTileServerUrl(
            'https://tiles.previous.test/{z}/{x}/{y}.png',
            origin: originA,
          );

          final settings = ServerSettings.fromJson({
            'tileserver_url': '',
            'tileserver_attribution': '',
            'map_background_color': '',
          });

          await repository.saveFromServerSettings(settings, origin: originA);

          expect(
            await repository.getTileServerUrl(origin: originA),
            MapConstants.defaultTileServerUrl,
          );
        },
      );

      test('keeps different connection origins isolated', () async {
        await repository.saveTileServerUrl(
          'https://tiles.a.test/{z}/{x}/{y}.png',
          origin: originA,
        );
        await repository.saveTileServerUrl(
          'https://tiles.b.test/{z}/{x}/{y}.png',
          origin: originB,
        );

        expect(
          await repository.getTileServerUrl(origin: originA),
          'https://tiles.a.test/{z}/{x}/{y}.png',
        );
        expect(
          await repository.getTileServerUrl(origin: originB),
          'https://tiles.b.test/{z}/{x}/{y}.png',
        );
      });
    });
  });
}
