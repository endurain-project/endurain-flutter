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
/// change (sign-in, choosing offline/guest mode, sign-out, revalidation, the
/// initial load completing) re-runs [resolveRedirect] and moves the app between
/// the splash, login, and home destinations. Screens never push these
/// top-level destinations imperatively — they update session state and let the
/// guard react.
///
/// Extending: add new top-level destinations as sibling [GoRoute]s and gate
/// them inside [resolveRedirect]. When the bottom-navigation tabs need their
/// own URLs or deep links, promote [AppRoutes.home] to a `StatefulShellRoute`
/// whose branches map to the existing tabs — the redirect guard stays the same.
GoRouter buildAppRouter({
  required AuthSessionController session,
  required VoidCallback onLoginSuccess,
  required VoidCallback onLogout,
  required VoidCallback onContinueOffline,
}) {
  return GoRouter(
    initialLocation: AppRoutes.loading,
    refreshListenable: session,
    redirect: (context, state) =>
        resolveRedirect(mode: session.mode, location: state.matchedLocation),
    routes: [
      GoRoute(
        path: AppRoutes.loading,
        builder: (context, state) =>
            const Center(child: AdaptiveLoadingIndicator()),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => LoginScreen(
          onLoginSuccess: onLoginSuccess,
          onContinueOffline: onContinueOffline,
          // A guest reaching login came from the app (e.g. Settings) and can
          // return to it; a first-launch user has nowhere to go back to.
          onCancel: session.isGuest ? () => context.go(AppRoutes.home) : null,
        ),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => AppBottomNav(
          onLogout: onLogout,
          isGuest: session.isGuest,
          onSignIn: () => context.go(AppRoutes.login),
        ),
      ),
    ],
  );
}

/// Resolves the destination for [location] given the current session [mode].
///
/// Returns `null` to stay on the current location, or the path to redirect to.
/// While the session is still loading the app stays on the splash; an
/// unauthenticated session is pinned to login; an authenticated one to home. A
/// [SessionMode.guest] session lives on home but may also visit login (to
/// connect a server later). Extracted as a pure function so the guard contract
/// is unit-testable without a widget tree or services.
@visibleForTesting
String? resolveRedirect({required SessionMode mode, required String location}) {
  switch (mode) {
    case SessionMode.loading:
      return location == AppRoutes.loading ? null : AppRoutes.loading;
    case SessionMode.unauthenticated:
      return location == AppRoutes.login ? null : AppRoutes.login;
    case SessionMode.guest:
      // Guests use the app locally and may open login to connect a server.
      if (location == AppRoutes.login) {
        return null;
      }
      return location == AppRoutes.home ? null : AppRoutes.home;
    case SessionMode.authenticated:
      return location == AppRoutes.home ? null : AppRoutes.home;
  }
}
