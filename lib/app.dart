import 'dart:async';

import 'package:flutter/material.dart';
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
    // The `AppServices.instance` fallback is only reached by tests that build
    // `App()` without supplying services.
    _services = widget.services ?? AppServices.instance;
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
    // A guest may have recorded activities offline; now that a server is
    // connected and authenticated, flush the pending upload backlog.
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
      // Rebuild the localized app tree when the user changes languages.
      child: ListenableBuilder(
        listenable: _services.localeController,
        builder: (context, _) => AdaptiveApp.router(
          title: 'Endurain',
          routerConfig: _router,
          locale: _services.localeController.locale,
        ),
      ),
    );
  }
}
