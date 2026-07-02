import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:endurain/app.dart';
import 'package:endurain/core/services/auth_service.dart';
import 'package:endurain/core/services/secure_storage_service.dart';
import 'package:endurain/features/auth/controllers/auth_session_controller.dart';
import 'package:endurain/features/auth/screens/login_screen.dart';
import 'package:endurain/l10n/app_localizations_en.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  testWidgets('App shows the login screen for a signed-out session', (
    WidgetTester tester,
  ) async {
    // The app is local-first, so a fresh launch goes straight to the map
    // (guest). Drive the injected controller into the signed-out state to
    // assert that the login screen still renders after a user signs out.
    final sessionController = AuthSessionController(
      authService: AuthService(storage: SecureStorageService()),
    )..markUnauthenticated();
    addTearDown(sessionController.dispose);

    await tester.pumpWidget(App(sessionController: sessionController));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text(AppLocalizationsEn().loginTitle), findsWidgets);
  });
}
