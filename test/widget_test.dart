import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:endurain/app.dart';
import 'package:endurain/core/services/auth_service.dart';
import 'package:endurain/core/services/secure_storage_service.dart';
import 'package:endurain/features/auth/controllers/auth_session_controller.dart';
import 'package:endurain/features/auth/screens/login_screen.dart';
import 'package:endurain/l10n/app_localizations_en.dart';

import 'helpers/fake_preferences_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  testWidgets('App shows login when unauthenticated', (
    WidgetTester tester,
  ) async {
    // Inject an in-memory preferences store: real file I/O does not complete
    // under `pumpAndSettle`, which would otherwise leave the session stuck on
    // the splash screen.
    final sessionController = AuthSessionController(
      authService: AuthService(storage: SecureStorageService()),
      preferences: FakePreferencesStore(),
    );
    addTearDown(sessionController.dispose);

    await tester.pumpWidget(App(sessionController: sessionController));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text(AppLocalizationsEn().loginTitle), findsWidgets);
  });
}
