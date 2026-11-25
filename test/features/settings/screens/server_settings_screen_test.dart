import 'package:endurain/core/auth/auth_service.dart';
import 'package:endurain/core/auth/secure_storage_service.dart';
import 'package:endurain/core/localization/app_locales.dart';
import 'package:endurain/core/utils/platform_utils.dart';
import 'package:endurain/features/settings/repositories/server_settings_repository.dart';
import 'package:endurain/features/settings/screens/server_settings_screen.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:endurain/l10n/app_localizations_en.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/widget_test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final l10n = AppLocalizationsEn();

  setUp(() {
    PlatformUtils.debugIsApplePlatformOverride = false;
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  tearDown(PlatformUtils.debugResetOverrides);

  group('ServerSettingsScreen', () {
    testWidgets('shows the stored account and no tile server field', (
      tester,
    ) async {
      final storage = SecureStorageService();
      await storage.setServerUrl('https://endurain.example.test');
      await storage.setUsername('joao');

      await tester.pumpWidget(
        _SettingsTestApp(
          child: ServerSettingsScreen(repository: _repository(storage)),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text(l10n.serverSettingsTitle), findsOneWidget);
      expect(find.text(l10n.loggedIn), findsOneWidget);
      expect(find.text('https://endurain.example.test'), findsOneWidget);
      expect(find.text('joao'), findsOneWidget);
      expect(find.text(l10n.logout), findsOneWidget);
      // The tile server URL has its own Map tiles screen now.
      expect(find.byType(TextFormField), findsNothing);
      expect(find.text(l10n.save), findsNothing);
    });

    testWidgets('falls back to placeholders when nothing is stored', (
      tester,
    ) async {
      await tester.pumpWidget(
        _SettingsTestApp(
          child: ServerSettingsScreen(
            repository: _repository(SecureStorageService()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text(l10n.notConfigured), findsOneWidget);
      expect(find.text(l10n.notLoggedIn), findsOneWidget);
    });
  });
}

ServerSettingsRepository _repository(SecureStorageService storage) {
  return ServerSettingsRepository(
    storage: storage,
    authService: AuthService(storage: storage),
  );
}

class _SettingsTestApp extends StatelessWidget {
  const _SettingsTestApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: TestAppScope(child: child),
    );
  }
}
