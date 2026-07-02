import 'package:flutter_test/flutter_test.dart';
import 'package:endurain/core/navigation/app_router.dart';
import 'package:endurain/core/navigation/app_routes.dart';
import 'package:endurain/features/auth/controllers/auth_session_controller.dart';

void main() {
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
}
