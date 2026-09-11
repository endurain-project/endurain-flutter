import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:endurain/core/navigation/app_router.dart';
import 'package:endurain/core/services/app_scope.dart';
import 'package:endurain/core/services/app_services.dart';
import 'package:endurain/core/services/auth_service.dart';
import 'package:endurain/core/services/diagnostics_service.dart';
import 'package:endurain/features/auth/controllers/auth_session_controller.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';

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
          authService: widget.authService ?? _services.auth,
        );
    // The router redirects declaratively off the session state; no manual
    // listener/setState is needed here (see `app_router.dart`).
    _router = buildAppRouter(
      session: _sessionController,
      onLoginSuccess: _onLoginSuccess,
      onLogout: _onLogout,
    );
    // Bootstrap the initial session only for controllers we own; an injected
    // controller (in tests) is set up by whoever supplied it.
    if (_ownsSessionController) {
      _sessionController.initialize();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _router.dispose();
    if (_ownsSessionController) {
      _sessionController.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _services.diagnostics.recordBreadcrumbSync(
      DiagnosticsEvents.appLifecycleChanged,
      details: {'state': state.name},
    );
    if (state == AppLifecycleState.resumed) {
      unawaited(_sessionController.revalidate());
      // Durably retry any activity uploads that did not reach the server
      // (e.g. recorded with no connectivity). Best-effort; errors are handled
      // and recorded inside the queue.
      unawaited(_services.activityUploadQueue.drain());
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
      unawaited(_services.reconnectRememberedSensors());
      // Pull any workout a paired companion watch finished while the phone app
      // was backgrounded. Inert (and cheap) on builds and platforms without a
      // watch transport; ingested sessions trigger the upload queue themselves.
      unawaited(_services.watchCompanion.syncPendingSessions());
    }
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      // Persist any buffered diagnostics before the OS can reclaim the
      // backgrounded process. Best-effort; a no-op when diagnostics is off.
      unawaited(_services.diagnostics.flush());
    }
  }

  Future<void> _autoSyncHealthOnResume() async {
    try {
      await _services.healthSyncService.autoSyncOnResume();
    } catch (error) {
      _services.diagnostics.recordBreadcrumbSync(
        DiagnosticsEvents.healthAutoSyncFailed,
        details: {'type': error.runtimeType.toString()},
      );
    }
  }

  void _onLoginSuccess() {
    _sessionController.markAuthenticated();
    // Activities recorded in guest mode have no connection yet. Draining now
    // binds that offline backlog to the newly-connected account and uploads it.
    unawaited(_services.activityUploadQueue.drain());
  }

  void _onLogout() {
    // Local-first: signing out drops back to the map in guest mode rather than
    // gating the app behind the login screen.
    _sessionController.continueAsGuest();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      services: _services,
      // Rebuild the localized app tree when the user changes languages, and the
      // whole tree when the unit preference changes so every stat re-renders.
      child: ListenableBuilder(
        listenable: Listenable.merge([
          _services.localeController,
          _services.measurementSystemController,
        ]),
        builder: (context, _) => AdaptiveApp.router(
          title: 'Endurain',
          routerConfig: _router,
          locale: _services.localeController.locale,
        ),
      ),
    );
  }
}
