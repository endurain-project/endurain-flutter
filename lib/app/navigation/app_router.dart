import 'package:endurain/app/navigation/app_routes.dart';
import 'package:endurain/app/navigation/app_screens.dart';
import 'package:endurain/app/widgets/app_bottom_nav.dart';
import 'package:endurain/core/diagnostics/diagnostics_service.dart';
import 'package:endurain/features/auth/controllers/auth_session_controller.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

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
///
/// Every change of the visible route and every redirect is recorded to
/// [diagnostics] by route name only (see [diagnosticRouteLabel]).
GoRouter buildAppRouter({
  required AuthSessionController session,
  required AppScreens screens,
  required Future<void> Function(BuildContext context) onLoginSuccess,
  required VoidCallback onLogout,
  DiagnosticsRecorder diagnostics = const NoopDiagnosticsRecorder(),
}) {
  final router = GoRouter(
    initialLocation: AppRoutes.loading,
    refreshListenable: session,
    redirect: (context, state) {
      final target = resolveRedirect(
        mode: session.mode,
        location: state.matchedLocation,
      );
      if (target != null) {
        diagnostics.recordBreadcrumbSync(
          DiagnosticsEvents.navigationRedirected,
          details: {
            'from': diagnosticRouteLabel(state.uri.path),
            'to': diagnosticRouteLabel(target),
            'mode': session.mode.name,
          },
        );
      }
      return target;
    },
    routes: [
      GoRoute(
        path: AppRoutes.loading,
        builder: (context, state) =>
            const Center(child: AdaptiveLoadingIndicator()),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => screens.login(
          // Awaited before leaving: the callback may ask the user a question
          // on this route (see `LegacyProfileAdoptionService`) before it marks
          // the session authenticated, which redirects to home.
          onLoginSuccess: () async {
            await onLoginSuccess(context);
            if (context.mounted) {
              context.go(AppRoutes.home);
            }
          },
          // Login is pushed on top of home (from the Settings tab), so
          // cancelling pops back to Settings. Fall back to home if login was
          // somehow the initial location (e.g. reached via a deep link).
          onCancel: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.home),
        ),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => ListenableBuilder(
          listenable: session,
          builder: (context, _) => AppBottomNav(
            mapTab: screens.map,
            settingsTab: (context) => screens.settings(
              context,
              onLogout: onLogout,
              isGuest: session.isGuest,
              // Push so the back button returns to the Settings tab underneath.
              onSignIn: () => context.push(AppRoutes.login),
            ),
          ),
        ),
      ),
    ],
  );
  _recordRouteChanges(router, diagnostics);
  return router;
}

/// Records each change of the top-most route, including pushed ones.
void _recordRouteChanges(GoRouter router, DiagnosticsRecorder diagnostics) {
  String? current;
  router.routerDelegate.addListener(() {
    final configuration = router.routerDelegate.currentConfiguration;
    final location = configuration.isError
        ? 'error'
        : configuration.isEmpty
        ? ''
        : diagnosticRouteLabel(configuration.last.matchedLocation);
    if (location == current) {
      return;
    }
    diagnostics.recordBreadcrumbSync(
      DiagnosticsEvents.navigationChanged,
      details: {'from': ?current, 'to': location},
    );
    current = location;
  });
}

/// [path] when it is one of the app's own routes, otherwise `unmatched`, so a
/// link opened from outside never puts its path (which may carry ids or
/// tokens) in a report.
@visibleForTesting
String diagnosticRouteLabel(String path) =>
    _knownRoutes.contains(path) ? path : 'unmatched';

const Set<String> _knownRoutes = {
  AppRoutes.loading,
  AppRoutes.login,
  AppRoutes.home,
};

/// Resolves the destination for [location] given the current session [mode].
///
/// Returns `null` to stay on the current location, or the path to redirect to.
/// While the session is still loading the app stays on the splash. Both
/// [SessionMode.guest] and [SessionMode.authenticated] live on home; a guest
/// may additionally visit login (to connect a server). Extracted as a pure
/// function so the guard contract is unit-testable without a widget tree or
/// services.
@visibleForTesting
String? resolveRedirect({required SessionMode mode, required String location}) {
  switch (mode) {
    case SessionMode.loading:
      return location == AppRoutes.loading ? null : AppRoutes.loading;
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
