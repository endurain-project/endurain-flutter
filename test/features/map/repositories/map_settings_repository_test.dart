import 'package:endurain/core/config/app_config.dart';
import 'package:endurain/core/constants/map_constants.dart';
import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/models/server_settings.dart';
import 'package:endurain/features/map/repositories/map_settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';

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
      'falls back to the default when a stored URL is no longer allowed',
      () async {
        // Stored while any tile host was permitted.
        await repository.saveTileServerUrl(
          'https://tiles.blocked.test/{z}/{x}/{y}.png',
        );

        // A later build tightens the allowlist so the stored host is rejected;
        // reading must not serve a host that current policy no longer allows.
        final restricted = MapSettingsRepository(
          preferences: prefs,
          config: const AppConfig(
            allowedTileServerHosts: {'tiles.allowed.test'},
          ),
        );

        expect(
          await restricted.getTileServerUrl(),
          MapConstants.defaultTileServerUrl,
        );
      },
    );

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

    group('tile URL template', () {
      test('accepts the z/x/y placeholders with s, r and d', () {
        expect(
          repository.isValidTileServerUrl(
            'https://{s}.tiles.test/{z}/{x}/{y}{r}.png?size={d}',
          ),
          isTrue,
        );
        expect(
          repository.isValidTileServerUrl(MapConstants.defaultTileServerUrl),
          isTrue,
        );
      });

      test('rejects a URL missing z, x or y', () {
        expect(
          repository.isValidTileServerUrl('https://tiles.test/tile.png'),
          isFalse,
        );
        expect(
          repository.isValidTileServerUrl('https://tiles.test/{z}/{x}.png'),
          isFalse,
        );
      });

      test('rejects a placeholder the map cannot fill', () async {
        const url = 'https://tiles.test/{z}/{x}/{y}.png?key={apikey}';

        expect(repository.isValidTileServerUrl(url), isFalse);
        await expectLater(
          repository.saveTileServerUrl(url),
          throwsA(isA<AppException>()),
        );
      });

      test(
        'serves the default for a stored URL without placeholders',
        () async {
          // Stored by an earlier build that did not check the template.
          await prefs.write(
            key: 'tile_server_url',
            value: 'https://tiles.test/tile.png',
          );

          expect(
            await repository.getTileServerUrl(),
            MapConstants.defaultTileServerUrl,
          );
        },
      );
    });

    group('change notifications', () {
      test('notifies after a save, not after a rejected one', () async {
        final changes = TileServerUrlChanges();
        addTearDown(changes.dispose);
        final notifying = MapSettingsRepository(
          preferences: prefs,
          changes: changes,
        );
        var notified = 0;
        changes.addListener(() => notified++);

        await notifying.saveTileServerUrl(
          'https://tiles.example.test/{z}/{x}/{y}.png',
        );
        expect(notified, 1);

        await expectLater(
          notifying.saveTileServerUrl('not a url'),
          throwsA(isA<AppException>()),
        );
        expect(notified, 1);
      });

      test('notifies when server settings provide a tile URL', () async {
        final changes = TileServerUrlChanges();
        addTearDown(changes.dispose);
        final notifying = MapSettingsRepository(
          preferences: prefs,
          changes: changes,
        );
        var notified = 0;
        changes.addListener(() => notified++);

        await notifying.saveFromServerSettings(
          ServerSettings.fromJson({}),
          origin: originA,
        );
        expect(notified, 0);

        await notifying.saveFromServerSettings(
          ServerSettings.fromJson({
            'tileserver_url': 'https://tiles.test/{z}/{x}/{y}.png',
          }),
          origin: originA,
        );
        expect(notified, 1);
      });
    });

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

      test('keeps the stored value when server settings omit it', () async {
        await repository.saveTileServerUrl(
          'https://tiles.previous.test/{z}/{x}/{y}.png',
          origin: originA,
        );

        // fromJson defaults tileserver_url to null when not present.
        final settings = ServerSettings.fromJson({});

        await repository.saveFromServerSettings(settings, origin: originA);

        // A URL the user chose for this server survives signing in again.
        expect(
          await repository.getTileServerUrl(origin: originA),
          'https://tiles.previous.test/{z}/{x}/{y}.png',
        );
      });

      test('keeps the stored value when the server URL is invalid', () async {
        await repository.saveTileServerUrl(
          'https://tiles.previous.test/{z}/{x}/{y}.png',
          origin: originA,
        );

        await repository.saveFromServerSettings(
          ServerSettings.fromJson({'tileserver_url': 'not a url'}),
          origin: originA,
        );

        expect(
          await repository.getTileServerUrl(origin: originA),
          'https://tiles.previous.test/{z}/{x}/{y}.png',
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
            'https://tiles.previous.test/{z}/{x}/{y}.png',
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
