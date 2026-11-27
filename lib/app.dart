import 'dart:async';

import 'package:endurain/app/app_services.dart';
import 'package:endurain/app/measurement_system_scope.dart';
import 'package:endurain/app/navigation/app_router.dart';
import 'package:endurain/app/navigation/app_screens.dart';
import 'package:endurain/core/auth/auth_service.dart';
import 'package:endurain/core/diagnostics/diagnostics_scope.dart';
import 'package:endurain/core/diagnostics/diagnostics_service.dart';
import 'package:endurain/features/account_migration/widgets/legacy_profile_adoption_dialog.dart';
import 'package:endurain/features/auth/controllers/auth_session_controller.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

class App extends StatefulWidget {
  const App({
    super.key,
    this.services,
    this.authService,
    this.sessionController,
  });

  final AppServices? services;
  final AuthService? authService;
  final AuthSessionController? sessionController;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  late final AppServices _services;
  late final AuthSessionController _sessionController;
  late final bool _ownsSessionController;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // Production always injects `services` from the composition root (`main`).
    // A locally-constructed fallback keeps `App()` self-sufficient for tests
    // that build it without supplying services — there is no shared global.
    _services = widget.services ?? AppServices();
    WidgetsBinding.instance.addObserver(this);
    _ownsSessionController = widget.sessionController == null;
    _sessionController =
        widget.sessionController ??
        AuthSessionController(
          authService: widget.authService ?? _services.auth.service,
          diagnostics: _services.infra.diagnostics,
        );
    // Screens kept alive across sign-in/out (the map and settings tabs) refresh
    // their server-scoped values from this signal.
    _sessionController.addListener(_services.notifyConnectionChanged);
    // The router redirects declaratively off the session state; no manual
    // listener/setState is needed here (see `app_router.dart`).
    _router = buildAppRouter(
      session: _sessionController,
      screens: AppScreens(_services),
      onLoginSuccess: _onLoginSuccess,
      onLogout: _onLogout,
      diagnostics: _services.infra.diagnostics,
    );
    // Bootstrap the initial session only for controllers we own; an injected
    // controller (in tests) is set up by whoever supplied it.
    if (_ownsSessionController) {
      unawaited(_sessionController.initialize());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _router.dispose();
    _sessionController.removeListener(_services.notifyConnectionChanged);
    if (_ownsSessionController) {
      _sessionController.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _services.infra.diagnostics.recordBreadcrumbSync(
      DiagnosticsEvents.appLifecycleChanged,
      details: {'state': state.name},
    );
    if (state == AppLifecycleState.resumed) {
      unawaited(_sessionController.revalidate());
      // Durably retry any activity uploads that did not reach the server
      // (e.g. recorded with no connectivity). Best-effort; errors are handled
      // and recorded inside the queue.
      unawaited(_services.activity.uploadQueue.drain());
      // If the user enabled auto-sync, import any new workouts from the health
      // platform silently. Best-effort failures are contained and recorded
      // without depending on mutable Health Sync screen state.
      if (_services.config.healthSyncEnabled) {
        unawaited(_autoSyncHealthOnResume());
      }
      // Reconnect any remembered heart-rate, power, and cadence sensors that
      // may have dropped while backgrounded. Best-effort and self-guarded: each
      // no-ops when none is paired, Bluetooth is off, or a recording currently
      // owns the sensor.
      unawaited(_services.sensors.reconnectRemembered());
      // Pull any workout a paired companion watch finished while the phone app
      // was backgrounded. Inert (and cheap) on builds and platforms without a
      // watch transport; ingested sessions trigger the upload queue themselves.
      unawaited(_services.watch.companion.syncPendingSessions());
    }
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      // Persist any buffered diagnostics before the OS can reclaim the
      // backgrounded process. Best-effort; a no-op when diagnostics is off.
      unawaited(_services.infra.diagnostics.flush());
    }
  }

  Future<void> _autoSyncHealthOnResume() async {
    try {
      await _services.health.syncService.autoSyncOnResume();
    } catch (error) {
      _services.infra.diagnostics.recordBreadcrumbSync(
        DiagnosticsEvents.healthAutoSyncFailed,
        details: diagnosticErrorDetails(error),
      );
    }
  }

  Future<void> _onLoginSuccess(BuildContext context) async {
    // Before the session is marked authenticated (which leaves the login
    // route): move local data recorded under this account's pre-v0.21 integer
    // id, asking the user when the account cannot be matched for certain.
    await _services.legacyProfileAdoption.resolveAfterSignIn(
      confirm: (candidate) => confirmLegacyProfileAdoption(context, candidate),
    );
    _sessionController.markAuthenticated();
    // Activities recorded in guest mode have no connection yet. Draining now
    // binds that offline backlog to the newly-connected account and uploads it.
    unawaited(_services.activity.uploadQueue.drain());
  }

  void _onLogout() {
    // Local-first: signing out drops back to the map in guest mode rather than
    // gating the app behind the login screen.
    _sessionController.continueAsGuest();
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild the localized app tree when the user changes languages. The
    // unit preference travels in its own scope, so changing it rebuilds only
    // the widgets that read it, not the router.
    return DiagnosticsScope(
      recorder: _services.infra.diagnostics,
      child: MeasurementSystemScope(
        controller: _services.infra.measurementSystemController,
        child: ListenableBuilder(
          listenable: _services.infra.localeController,
          builder: (context, _) => AdaptiveApp.router(
            title: 'Endurain',
            routerConfig: _router,
            locale: _services.infra.localeController.locale,
          ),
        ),
      ),
    );
  }
}
