import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:endurain/app.dart';
import 'package:endurain/core/services/auth_service.dart';
import 'package:endurain/core/services/secure_storage_service.dart';
import 'package:endurain/features/auth/controllers/auth_session_controller.dart';
import 'package:endurain/features/auth/screens/login_screen.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  testWidgets('App wires the router and shows the splash while loading', (
    WidgetTester tester,
  ) async {
    // App does not initialise an injected controller, so it stays on the
    // splash. This smoke-tests App + router wiring without rendering the map
    // or login destinations, which need heavier services.
    final sessionController = AuthSessionController(
      authService: AuthService(storage: SecureStorageService()),
    );
    addTearDown(sessionController.dispose);

    await tester.pumpWidget(App(sessionController: sessionController));
    await tester.pump();

    expect(find.byType(AdaptiveLoadingIndicator), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
  });
}
