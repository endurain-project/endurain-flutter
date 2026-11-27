import 'dart:async';

import 'package:endurain/core/auth/auth_service.dart';
import 'package:endurain/core/diagnostics/diagnostics_service.dart';
import 'package:endurain/shared/state/safe_notifier.dart';

/// The high-level session state that drives top-level routing.
///
/// The app is local-first: recording and local storage never require a server,
/// so the app launches straight into local-only [guest] mode. Users connect a
/// server later (from Settings) to enable uploads and server features, and
/// signing out simply drops back to [guest].
enum SessionMode {
  /// The initial session check is still running (splash).
  loading,

  /// Local-only mode with no server session: activities are recorded and
  /// stored locally and uploads are deferred until sign-in. This is the
  /// default whenever there is no valid server session (launch, sign-out,
  /// session expiry).
  guest,

  /// A valid server session exists; uploads and server features are enabled.
  authenticated,
}

class AuthSessionController extends SafeNotifier {
  AuthSessionController({
    required this._authService,
    DiagnosticsRecorder? diagnostics,
  }) : _diagnostics = diagnostics ?? const NoopDiagnosticsRecorder() {
    // A session the auth layer ends by itself (a refresh the server rejected
    // during any API call) must drop the app to guest, not only a resume.
    _sessionEndedSubscription = _authService.sessionEnded.listen((_) {
      if (_mode == SessionMode.authenticated) {
        _setMode(SessionMode.guest, reason: 'session_cleared');
      }
    });
  }

  final AuthService _authService;
  final DiagnosticsRecorder _diagnostics;
  late final StreamSubscription<void> _sessionEndedSubscription;

  /// Bumped on every mode decision, so a [revalidate] that started before a
  /// sign-in, sign-out or session end does not apply its stale answer.
  int _epoch = 0;

  /// Upper bound for the launch session read so a stalled secure-storage call
  /// can never pin the app on the splash.
  static const _initializeTimeout = Duration(seconds: 3);

  SessionMode _mode = SessionMode.loading;

  /// Set when the stored session could not be read (secure storage
  /// unavailable). The session may still exist, so [revalidate] retries.
  bool _sessionUnreadable = false;

  SessionMode get mode => _mode;
  bool get isGuest => _mode == SessionMode.guest;

  /// Resolves the initial session on launch. A valid server session restores
  /// the authenticated experience; otherwise the app starts local-first in
  /// [SessionMode.guest] so the user lands on the map without a login gate.
  Future<void> initialize() async {
    _mode = SessionMode.loading;
    notify();

    try {
      final stored = await _authService.hasStoredSession().timeout(
        _initializeTimeout,
      );
      _sessionUnreadable = false;
      _setMode(
        stored ? SessionMode.authenticated : SessionMode.guest,
        reason: stored ? 'launch_stored_session' : 'launch_no_session',
      );
    } catch (error) {
      // Secure storage unavailable, or the read stalled past
      // [_initializeTimeout]: start usable in guest mode instead of hanging on
      // the splash, and retry when the app resumes.
      _sessionUnreadable = true;
      _setMode(
        SessionMode.guest,
        reason: 'launch_session_unreadable',
        error: error,
      );
    }
    // Confirm a restored session with the server off the launch path. A
    // definitive rejection drops to guest; a transient failure keeps the session.
    if (_mode == SessionMode.authenticated) {
      unawaited(revalidate());
    }
  }

  void markAuthenticated() {
    _sessionUnreadable = false;
    _setMode(SessionMode.authenticated, reason: 'signed_in');
  }

  /// Drops to local-only "guest" mode (used on launch, after signing out, and
  /// when a server session expires). Activities keep recording locally and
  /// uploads resume once the user signs in again.
  void continueAsGuest() {
    _setMode(SessionMode.guest, reason: 'signed_out');
  }

  /// Re-checks the active session when the app resumes from background.
  ///
  /// Only acts on an authenticated session, so it is safe to call on every
  /// app-resumed lifecycle event (guest/loading are left untouched). When the
  /// session has expired the mode drops back to [SessionMode.guest] so the app
  /// stays usable locally until the user signs in again.
  ///
  /// If the stored session was unreadable at launch, the check is retried here
  /// and the mode is promoted to [SessionMode.authenticated] once it succeeds.
  /// A read failure while authenticated keeps the current mode.
  Future<void> revalidate() async {
    final retryingUnreadable = _mode == SessionMode.guest && _sessionUnreadable;
    if (_mode != SessionMode.authenticated && !retryingUnreadable) {
      return;
    }
    final epoch = _epoch;
    final bool stillAuthenticated;
    try {
      stillAuthenticated = await _authService.isAuthenticated();
    } catch (error) {
      _diagnostics.recordBreadcrumbSync(
        DiagnosticsEvents.sessionRevalidateFailed,
        details: diagnosticErrorDetails(error),
      );
      return;
    }
    if (epoch != _epoch || isDisposed) {
      // The session or mode changed while the check ran; its answer is about
      // a session that is no longer the current one.
      return;
    }
    _sessionUnreadable = false;
    if (retryingUnreadable) {
      if (stillAuthenticated) {
        _setMode(SessionMode.authenticated, reason: 'session_readable_again');
      }
    } else if (!stillAuthenticated) {
      _setMode(SessionMode.guest, reason: 'session_ended');
    }
  }

  /// Moves to [mode] and records why, so a report shows each sign-in, sign-out
  /// and expiry that moved the app between guest and authenticated.
  void _setMode(SessionMode mode, {required String reason, Object? error}) {
    _epoch++;
    if (_mode == mode) {
      return;
    }
    _diagnostics.recordBreadcrumbSync(
      DiagnosticsEvents.sessionModeChanged,
      details: {
        'from': _mode.name,
        'to': mode.name,
        'reason': reason,
        if (error != null) ...diagnosticErrorDetails(error),
      },
    );
    _mode = mode;
    notify();
  }

  @override
  void dispose() {
    unawaited(_sessionEndedSubscription.cancel());
    super.dispose();
  }
}
