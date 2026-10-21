import 'package:endurain/core/services/auth_service.dart';
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
  AuthSessionController({required this._authService});

  final AuthService _authService;

  SessionMode _mode = SessionMode.loading;

  /// Set when the stored session could not be read (secure storage
  /// unavailable). The session may still exist, so [revalidate] retries.
  bool _sessionUnreadable = false;

  SessionMode get mode => _mode;
  bool get isLoading => _mode == SessionMode.loading;
  bool get isAuthenticated => _mode == SessionMode.authenticated;
  bool get isGuest => _mode == SessionMode.guest;

  /// Resolves the initial session on launch. A valid server session restores
  /// the authenticated experience; otherwise the app starts local-first in
  /// [SessionMode.guest] so the user lands on the map without a login gate.
  Future<void> initialize() async {
    _mode = SessionMode.loading;
    notify();

    try {
      _mode = await _authService.isAuthenticated()
          ? SessionMode.authenticated
          : SessionMode.guest;
      _sessionUnreadable = false;
    } catch (_) {
      // Secure storage unavailable: start usable in guest mode instead of
      // hanging on the splash, and retry when the app resumes.
      _mode = SessionMode.guest;
      _sessionUnreadable = true;
    }
    notify();
  }

  void markAuthenticated() {
    _sessionUnreadable = false;
    _setMode(SessionMode.authenticated);
  }

  /// Drops to local-only "guest" mode (used on launch, after signing out, and
  /// when a server session expires). Activities keep recording locally and
  /// uploads resume once the user signs in again.
  void continueAsGuest() {
    _setMode(SessionMode.guest);
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
    final bool stillAuthenticated;
    try {
      stillAuthenticated = await _authService.isAuthenticated();
    } catch (_) {
      return;
    }
    _sessionUnreadable = false;
    if (retryingUnreadable) {
      if (stillAuthenticated) {
        _setMode(SessionMode.authenticated);
      }
    } else if (!stillAuthenticated) {
      _setMode(SessionMode.guest);
    }
  }

  void _setMode(SessionMode mode) {
    if (_mode == mode) {
      return;
    }
    _mode = mode;
    notify();
  }
}
