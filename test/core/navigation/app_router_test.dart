import 'package:flutter_test/flutter_test.dart';
import 'package:endurain/core/navigation/app_router.dart';
import 'package:endurain/core/navigation/app_routes.dart';

void main() {
  group('resolveRedirect', () {
    test('pins to the splash while the session is loading', () {
      expect(
        resolveRedirect(
          isLoading: true,
          isAuthenticated: false,
          location: AppRoutes.login,
        ),
        AppRoutes.loading,
      );
      expect(
        resolveRedirect(
          isLoading: true,
          isAuthenticated: false,
          location: AppRoutes.loading,
        ),
        isNull,
      );
    });

    test('sends an unauthenticated session to login', () {
      expect(
        resolveRedirect(
          isLoading: false,
          isAuthenticated: false,
          location: AppRoutes.home,
        ),
        AppRoutes.login,
      );
      expect(
        resolveRedirect(
          isLoading: false,
          isAuthenticated: false,
          location: AppRoutes.login,
        ),
        isNull,
      );
    });

    test('sends an authenticated session to home', () {
      expect(
        resolveRedirect(
          isLoading: false,
          isAuthenticated: true,
          location: AppRoutes.login,
        ),
        AppRoutes.home,
      );
      expect(
        resolveRedirect(
          isLoading: false,
          isAuthenticated: true,
          location: AppRoutes.home,
        ),
        isNull,
      );
    });

    test('moves an authenticated session off the splash to home', () {
      expect(
        resolveRedirect(
          isLoading: false,
          isAuthenticated: true,
          location: AppRoutes.loading,
        ),
        AppRoutes.home,
      );
    });
  });
}
