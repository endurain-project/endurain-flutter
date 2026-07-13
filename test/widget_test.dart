import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:endurain/app.dart';
import 'package:endurain/core/config/app_config.dart';
import 'package:endurain/core/services/app_services.dart';
import 'package:endurain/core/services/auth_service.dart';
import 'package:endurain/core/services/secure_storage_service.dart';
import 'package:endurain/features/auth/controllers/auth_session_controller.dart';
import 'package:endurain/features/auth/screens/login_screen.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
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

  testWidgets('App safely handles foreground lifecycle transitions', (
    WidgetTester tester,
  ) async {
    final services = AppServices(
      config: const AppConfig(healthSyncEnabled: false),
    );
    final sessionController = AuthSessionController(
      authService: AuthService(storage: services.secureStorage),
    );
    addTearDown(sessionController.dispose);

    await tester.pumpWidget(
      App(services: services, sessionController: sessionController),
    );
    await tester.pump();

    WidgetsBinding.instance.handleAppLifecycleStateChanged(
      AppLifecycleState.paused,
    );
    WidgetsBinding.instance.handleAppLifecycleStateChanged(
      AppLifecycleState.resumed,
    );
    await tester.pump();

    expect(find.byType(AdaptiveLoadingIndicator), findsOneWidget);
  });
}
