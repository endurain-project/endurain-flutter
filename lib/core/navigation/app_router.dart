import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:endurain/core/navigation/app_routes.dart';
import 'package:endurain/features/auth/controllers/auth_session_controller.dart';
import 'package:endurain/features/auth/screens/login_screen.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:endurain/shared/widgets/app_bottom_nav.dart';

/// Builds the application's top-level [GoRouter].
///
/// Routing is driven declaratively by [AuthSessionController]: the session
/// controller is wired as the router's `refreshListenable`, so every session
/// change (sign-in, sign-out, revalidation, the initial load completing) re-runs
/// [resolveRedirect] and moves the app between the splash, login, and home
/// destinations. Screens never push these top-level destinations imperatively —
/// they update session state and let the guard react.
///
/// Extending: add new top-level destinations as sibling [GoRoute]s and gate
/// them inside [resolveRedirect]. When the bottom-navigation tabs need their
/// own URLs or deep links, promote [AppRoutes.home] to a `StatefulShellRoute`
/// whose branches map to the existing tabs — the redirect guard stays the same.
GoRouter buildAppRouter({
  required AuthSessionController session,
  required VoidCallback onLoginSuccess,
  required VoidCallback onLogout,
}) {
  return GoRouter(
    initialLocation: AppRoutes.loading,
    refreshListenable: session,
    redirect: (context, state) => resolveRedirect(
      isLoading: session.isLoading,
      isAuthenticated: session.isAuthenticated,
      location: state.matchedLocation,
    ),
    routes: [
      GoRoute(
        path: AppRoutes.loading,
        builder: (context, state) =>
            const Center(child: AdaptiveLoadingIndicator()),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) =>
            LoginScreen(onLoginSuccess: onLoginSuccess),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => AppBottomNav(onLogout: onLogout),
      ),
    ],
  );
}

/// Resolves the destination for [location] given the current session flags.
///
/// Returns `null` to stay on the current location, or the path to redirect to.
/// While the session is still loading the app stays on the splash; an
/// unauthenticated session is pinned to login and an authenticated one to home.
/// Extracted as a pure function so the guard contract is unit-testable without
/// a widget tree or services.
@visibleForTesting
String? resolveRedirect({
  required bool isLoading,
  required bool isAuthenticated,
  required String location,
}) {
  if (isLoading) {
    return location == AppRoutes.loading ? null : AppRoutes.loading;
  }
  if (!isAuthenticated) {
    return location == AppRoutes.login ? null : AppRoutes.login;
  }
  return location == AppRoutes.home ? null : AppRoutes.home;
}
