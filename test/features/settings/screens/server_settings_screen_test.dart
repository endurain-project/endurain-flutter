import 'package:endurain/core/config/app_config.dart';
import 'package:endurain/core/services/auth_service.dart';
import 'package:endurain/core/services/secure_storage_service.dart';
import 'package:endurain/core/utils/platform_utils.dart';
import 'package:endurain/features/map/repositories/map_settings_repository.dart';
import 'package:endurain/features/settings/repositories/server_settings_repository.dart';
import 'package:endurain/features/settings/screens/server_settings_screen.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:endurain/l10n/app_localizations_en.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_preferences_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final l10n = AppLocalizationsEn();

  setUp(() {
    PlatformUtils.debugIsApplePlatformOverride = false;
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  tearDown(PlatformUtils.debugResetOverrides);

  group('ServerSettingsScreen', () {
    testWidgets('loads stored account and tile server settings', (
      tester,
    ) async {
      final storage = SecureStorageService();
      await storage.setServerUrl('https://endurain.example.test');
      await storage.setUsername('joao');
      final prefs = FakePreferencesStore();
      await prefs.write(
        key: 'tile_server_url',
        value: 'https://tiles.example.test/{z}/{x}/{y}.png',
      );

      await tester.pumpWidget(
        _SettingsTestApp(
          child: ServerSettingsScreen(repository: _repository(storage, prefs)),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text(l10n.serverSettingsTitle), findsOneWidget);
      expect(find.text(l10n.loggedIn), findsOneWidget);
      expect(find.text('https://endurain.example.test'), findsOneWidget);
      expect(find.text('joao'), findsOneWidget);
      expect(
        find.widgetWithText(TextFormField, l10n.tileServerUrl),
        findsOneWidget,
      );
    });

    testWidgets('validates and saves tile server settings', (tester) async {
      final storage = SecureStorageService();
      final prefs = FakePreferencesStore();

      await tester.pumpWidget(
        _SettingsTestApp(
          child: ServerSettingsScreen(repository: _repository(storage, prefs)),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'not a url');
      await tester.tap(find.text(l10n.save));
      await tester.pump();

      expect(find.text(l10n.invalidUrl), findsOneWidget);

      const tileServerUrl = 'https://tiles.example.test/{z}/{x}/{y}.png';
      await tester.enterText(find.byType(TextFormField), tileServerUrl);
      await tester.tap(find.text(l10n.save));
      await tester.pumpAndSettle();

      expect(await prefs.read(key: 'tile_server_url'), tileServerUrl);
    });

    testWidgets('saves without warning when tile host matches server host', (
      tester,
    ) async {
      final storage = SecureStorageService();
      await storage.setServerUrl('https://endurain.example.test');
      final prefs = FakePreferencesStore();
      const sameTileUrl = 'https://endurain.example.test/tiles/{z}/{x}/{y}.png';

      await tester.pumpWidget(
        _SettingsTestApp(
          child: ServerSettingsScreen(repository: _repository(storage, prefs)),
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
        final storage = SecureStorageService();
        await storage.setServerUrl('https://endurain.example.test');
        final prefs = FakePreferencesStore();
        const differentTileUrl = 'https://tiles.other.test/{z}/{x}/{y}.png';

        await tester.pumpWidget(
          _SettingsTestApp(
            child: ServerSettingsScreen(
              repository: _repository(storage, prefs),
            ),
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
      final storage = SecureStorageService();
      await storage.setServerUrl('https://endurain.example.test');
      final prefs = FakePreferencesStore();
      const differentTileUrl = 'https://tiles.other.test/{z}/{x}/{y}.png';

      await tester.pumpWidget(
        _SettingsTestApp(
          child: ServerSettingsScreen(repository: _repository(storage, prefs)),
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
      final storage = SecureStorageService();
      await storage.setServerUrl('https://endurain.example.test');
      final prefs = FakePreferencesStore();
      const blockedTileUrl = 'https://not-allowed.test/{z}/{x}/{y}.png';
      const config = AppConfig(
        allowedTileServerHosts: {'endurain.example.test'},
      );

      await tester.pumpWidget(
        _SettingsTestApp(
          child: ServerSettingsScreen(
            repository: _repository(storage, prefs),
            config: config,
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

ServerSettingsRepository _repository(
  SecureStorageService storage,
  FakePreferencesStore prefs,
) {
  return ServerSettingsRepository(
    storage: storage,
    authService: AuthService(storage: storage),
    mapSettingsRepository: MapSettingsRepository(preferences: prefs),
  );
}

class _SettingsTestApp extends StatelessWidget {
  const _SettingsTestApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );
  }
}
