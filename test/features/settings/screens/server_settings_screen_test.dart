import 'package:endurain/core/auth/auth_service.dart';
import 'package:endurain/core/auth/secure_storage_service.dart';
import 'package:endurain/core/localization/app_locales.dart';
import 'package:endurain/core/models/app_exception.dart';
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

    testWidgets('flags a plain HTTP server as not secure', (tester) async {
      final storage = SecureStorageService();
      await storage.setServerUrl('http://192.168.1.10:8080');

      await tester.pumpWidget(
        _SettingsTestApp(
          child: ServerSettingsScreen(repository: _repository(storage)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n.serverNotSecure), findsOneWidget);
    });

    testWidgets('shows no insecure badge for an HTTPS server', (tester) async {
      final storage = SecureStorageService();
      await storage.setServerUrl('https://endurain.example.test');

      await tester.pumpWidget(
        _SettingsTestApp(
          child: ServerSettingsScreen(repository: _repository(storage)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n.serverNotSecure), findsNothing);
    });

    testWidgets('signs out of the app even when the local clear fails', (
      tester,
    ) async {
      final storage = SecureStorageService();
      var loggedOut = false;
      final repository = ServerSettingsRepository(
        storage: storage,
        authService: _FailingLogoutAuthService(storage),
      );

      // The screen is pushed, so the scope sits above the navigator.
      await tester.pumpWidget(
        TestMaterialApp(
          child: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => ServerSettingsScreen(
                      repository: repository,
                      onLogout: () => loggedOut = true,
                    ),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.logout));
      await tester.pumpAndSettle();
      // Confirm in the dialog.
      await tester.tap(find.text(l10n.logout).last);
      await tester.pumpAndSettle();

      expect(loggedOut, isTrue);
      expect(find.text(l10n.errorSecureStorageDeleteFailed), findsOneWidget);
      expect(find.byType(ServerSettingsScreen), findsNothing);
    });
  });
}

/// An [AuthService] whose local session clear fails.
class _FailingLogoutAuthService extends AuthService {
  _FailingLogoutAuthService(SecureStorageService storage)
    : super(storage: storage);

  @override
  Future<bool> logout() async {
    throw const AppException(AppErrorCode.secureStorageDeleteFailed);
  }
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
      home: child,
    );
  }
}
