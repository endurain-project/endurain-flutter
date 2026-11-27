import 'package:endurain/core/config/app_config.dart';
import 'package:endurain/core/localization/app_locales.dart';
import 'package:endurain/core/services/map_settings_repository.dart';
import 'package:endurain/core/utils/platform_utils.dart';
import 'package:endurain/features/map/controllers/tile_server_settings_controller.dart';
import 'package:endurain/features/map/screens/tile_server_settings_screen.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:endurain/l10n/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/fake_preferences_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final l10n = AppLocalizationsEn();

  // The screen leaves disposal of an injected controller to its owner.
  late List<TileServerSettingsController> controllers;

  setUp(() {
    PlatformUtils.debugIsApplePlatformOverride = false;
    controllers = [];
  });

  tearDown(() {
    for (final controller in controllers) {
      controller.dispose();
    }
    PlatformUtils.debugResetOverrides();
  });

  TileServerSettingsController buildController(
    FakePreferencesStore prefs, {
    AppConfig config = AppConfig.defaults,
    String? serverUrl = 'https://endurain.example.test',
  }) {
    final controller = TileServerSettingsController(
      repository: MapSettingsRepository(preferences: prefs, config: config),
      config: config,
      loadServerUrl: () async => serverUrl,
    );
    controllers.add(controller);
    return controller;
  }

  group('TileServerSettingsScreen', () {
    testWidgets('pre-fills the stored tile server URL', (tester) async {
      final prefs = FakePreferencesStore();
      const tileUrl = 'https://tiles.example.test/{z}/{x}/{y}.png';
      await prefs.write(key: 'tile_server_url', value: tileUrl);

      await tester.pumpWidget(
        _SettingsTestApp(
          child: TileServerSettingsScreen(controller: buildController(prefs)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n.mapTilesSettingsTitle), findsOneWidget);
      expect(
        find.widgetWithText(TextFormField, l10n.tileServerUrl),
        findsOneWidget,
      );
      expect(find.text(tileUrl), findsOneWidget);
      expect(find.text(l10n.mapTilesSettingsNote), findsOneWidget);
    });

    testWidgets('offers a retry when the setting cannot be loaded', (
      tester,
    ) async {
      final prefs = FakePreferencesStore();
      var failServerUrl = true;
      final controller = TileServerSettingsController(
        repository: MapSettingsRepository(preferences: prefs),
        config: AppConfig.defaults,
        loadServerUrl: () async {
          if (failServerUrl) {
            throw StateError('keychain locked');
          }
          return 'https://endurain.example.test';
        },
      );
      controllers.add(controller);

      await tester.pumpWidget(
        _SettingsTestApp(
          child: TileServerSettingsScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n.mapTilesSettingsLoadFailed), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);

      failServerUrl = false;
      await tester.tap(find.text(l10n.tryAgain));
      await tester.pumpAndSettle();

      expect(find.text(l10n.mapTilesSettingsLoadFailed), findsNothing);
      expect(
        find.widgetWithText(TextFormField, l10n.tileServerUrl),
        findsOneWidget,
      );
    });

    testWidgets('validates and saves tile server settings', (tester) async {
      final prefs = FakePreferencesStore();

      await tester.pumpWidget(
        _SettingsTestApp(
          child: TileServerSettingsScreen(
            controller: buildController(prefs, serverUrl: null),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'not a url');
      await tester.tap(find.text(l10n.save));
      await tester.pump();

      expect(find.text(l10n.invalidUrl), findsOneWidget);

      // A URL the map cannot fill per tile is rejected before saving.
      await tester.enterText(
        find.byType(TextFormField),
        'https://tiles.example.test/{z}/{x}/{y}.png?key={apikey}',
      );
      await tester.tap(find.text(l10n.save));
      await tester.pump();

      expect(find.text(l10n.invalidUrl), findsOneWidget);
      expect(await prefs.read(key: 'tile_server_url'), isNull);

      const tileServerUrl = 'https://tiles.example.test/{z}/{x}/{y}.png';
      await tester.enterText(find.byType(TextFormField), tileServerUrl);
      await tester.tap(find.text(l10n.save));
      await tester.pumpAndSettle();

      expect(await prefs.read(key: 'tile_server_url'), tileServerUrl);
    });

    testWidgets('saves without warning when tile host matches server host', (
      tester,
    ) async {
      final prefs = FakePreferencesStore();
      const sameTileUrl = 'https://endurain.example.test/tiles/{z}/{x}/{y}.png';

      await tester.pumpWidget(
        _SettingsTestApp(
          child: TileServerSettingsScreen(controller: buildController(prefs)),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), sameTileUrl);
      await tester.tap(find.text(l10n.save));
      await tester.pumpAndSettle();

      // No warning dialog visible — save succeeds directly.
      expect(find.text(l10n.tileServerHostWarningTitle), findsNothing);
      expect(await prefs.read(key: 'tile_server_url'), sameTileUrl);
    });

    testWidgets(
      'shows warning dialog when tile host differs from server host',
      (tester) async {
        final prefs = FakePreferencesStore();
        const differentTileUrl = 'https://tiles.other.test/{z}/{x}/{y}.png';

        await tester.pumpWidget(
          _SettingsTestApp(
            child: TileServerSettingsScreen(controller: buildController(prefs)),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextFormField), differentTileUrl);
        await tester.tap(find.text(l10n.save));
        await tester.pumpAndSettle();

        expect(find.text(l10n.tileServerHostWarningTitle), findsOneWidget);
        expect(find.text(l10n.tileServerHostWarningMessage), findsOneWidget);
        // Cancel — value should not be saved.
        await tester.tap(find.text(l10n.cancel));
        await tester.pumpAndSettle();

        expect(await prefs.read(key: 'tile_server_url'), isNull);
      },
    );

    testWidgets('saves when user confirms tile host warning', (tester) async {
      final prefs = FakePreferencesStore();
      const differentTileUrl = 'https://tiles.other.test/{z}/{x}/{y}.png';

      await tester.pumpWidget(
        _SettingsTestApp(
          child: TileServerSettingsScreen(controller: buildController(prefs)),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), differentTileUrl);
      await tester.tap(find.text(l10n.save));
      await tester.pumpAndSettle();

      expect(find.text(l10n.tileServerHostWarningTitle), findsOneWidget);
      // Confirm — value should be saved.
      await tester.tap(find.text(l10n.save).last);
      await tester.pumpAndSettle();

      expect(await prefs.read(key: 'tile_server_url'), differentTileUrl);
    });

    testWidgets('rejects tile host not in managed allowlist', (tester) async {
      final prefs = FakePreferencesStore();
      const blockedTileUrl = 'https://not-allowed.test/{z}/{x}/{y}.png';
      const config = AppConfig(
        allowedTileServerHosts: {'endurain.example.test'},
      );

      await tester.pumpWidget(
        _SettingsTestApp(
          child: TileServerSettingsScreen(
            controller: buildController(prefs, config: config),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), blockedTileUrl);
      await tester.tap(find.text(l10n.save));
      await tester.pumpAndSettle();

      // Error dialog shown, value not saved.
      expect(find.text(l10n.tileServerHostWarningTitle), findsOneWidget);
      expect(await prefs.read(key: 'tile_server_url'), isNull);
      // Dismiss error dialog.
      await tester.tap(find.text(l10n.ok));
      await tester.pumpAndSettle();
    });
  });
}

class _SettingsTestApp extends StatelessWidget {
  const _SettingsTestApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );
  }
}
