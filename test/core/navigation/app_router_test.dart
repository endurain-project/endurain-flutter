import 'dart:async';

import 'package:endurain/core/navigation/app_router.dart';
import 'package:endurain/core/navigation/app_routes.dart';
import 'package:endurain/core/services/app_scope.dart';
import 'package:endurain/core/services/app_services.dart';
import 'package:endurain/core/services/auth_service.dart';
import 'package:endurain/features/auth/controllers/auth_session_controller.dart';
import 'package:endurain/features/auth/screens/login_screen.dart';
import 'package:endurain/l10n/app_localizations_en.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  group('resolveRedirect', () {
    test('pins to the splash while the session is loading', () {
      expect(
        resolveRedirect(mode: SessionMode.loading, location: AppRoutes.login),
        AppRoutes.loading,
      );
      expect(
        resolveRedirect(mode: SessionMode.loading, location: AppRoutes.loading),
        isNull,
      );
    });

    test('sends an authenticated session to home', () {
      expect(
        resolveRedirect(
          mode: SessionMode.authenticated,
          location: AppRoutes.login,
        ),
        AppRoutes.home,
      );
      expect(
        resolveRedirect(
          mode: SessionMode.authenticated,
          location: AppRoutes.home,
        ),
        isNull,
      );
    });

    test('moves an authenticated session off the splash to home', () {
      expect(
        resolveRedirect(
          mode: SessionMode.authenticated,
          location: AppRoutes.loading,
        ),
        AppRoutes.home,
      );
    });

    group('guest mode', () {
      test('lands on home from the splash', () {
        expect(
          resolveRedirect(mode: SessionMode.guest, location: AppRoutes.loading),
          AppRoutes.home,
        );
      });

      test('stays on home', () {
        expect(
          resolveRedirect(mode: SessionMode.guest, location: AppRoutes.home),
          isNull,
        );
      });

      test('may visit login to connect a server later', () {
        expect(
          resolveRedirect(mode: SessionMode.guest, location: AppRoutes.login),
          isNull,
        );
      });
    });
  });

  testWidgets('updates Settings when logout enters guest mode', (tester) async {
    final session = AuthSessionController(
      authService: AuthService(storage: AppServices().secureStorage),
    );
    addTearDown(session.dispose);
    session.markAuthenticated();
    final router = buildAppRouter(
      session: session,
      onLoginSuccess: () {},
      onLogout: session.continueAsGuest,
    );
    addTearDown(router.dispose);
    final services = AppServices();
    final l10n = AppLocalizationsEn();

    await tester.pumpWidget(
      AppScope(
        services: services,
        child: AdaptiveApp.router(title: 'Test', routerConfig: router),
      ),
    );
    await tester.pump();

    await tester.tap(find.text(l10n.settingsTab));
    await tester.pump();
    expect(find.text(l10n.serverSettings), findsOneWidget);

    session.continueAsGuest();
    await tester.pump();

    expect(find.text(l10n.serverSettings), findsNothing);
    expect(find.text(l10n.signInConnectServer), findsOneWidget);
  });

  testWidgets('returns home after a pushed login succeeds', (tester) async {
    final services = AppServices();
    final session = AuthSessionController(
      authService: AuthService(storage: services.secureStorage),
    );
    addTearDown(session.dispose);
    session.continueAsGuest();
    final router = buildAppRouter(
      session: session,
      onLoginSuccess: session.markAuthenticated,
      onLogout: session.continueAsGuest,
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      AppScope(
        services: services,
        child: AdaptiveApp.router(title: 'Test', routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump();

    unawaited(router.push<void>(AppRoutes.login));
    await tester.pump();
    await tester.pump();
    expect(find.byType(LoginScreen), findsOneWidget);

    tester.widget<LoginScreen>(find.byType(LoginScreen)).onLoginSuccess!();
    await tester.pump();

    expect(session.isAuthenticated, isTrue);
    expect(find.byType(LoginScreen), findsNothing);
  });
}
