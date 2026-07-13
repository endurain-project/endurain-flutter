import 'package:flutter/foundation.dart';
import 'package:endurain/core/services/auth_service.dart';

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

class AuthSessionController extends ChangeNotifier {
  AuthSessionController({required this._authService});

  final AuthService _authService;

  SessionMode _mode = SessionMode.loading;

  SessionMode get mode => _mode;
  bool get isLoading => _mode == SessionMode.loading;
  bool get isAuthenticated => _mode == SessionMode.authenticated;
  bool get isGuest => _mode == SessionMode.guest;

  /// Resolves the initial session on launch. A valid server session restores
  /// the authenticated experience; otherwise the app starts local-first in
  /// [SessionMode.guest] so the user lands on the map without a login gate.
  Future<void> initialize() async {
    _mode = SessionMode.loading;
    notifyListeners();

    _mode = await _authService.isAuthenticated()
        ? SessionMode.authenticated
        : SessionMode.guest;
    notifyListeners();
  }

  void markAuthenticated() {
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
  Future<void> revalidate() async {
    if (_mode != SessionMode.authenticated) {
      return;
    }
    final stillAuthenticated = await _authService.isAuthenticated();
    if (!stillAuthenticated) {
      _setMode(SessionMode.guest);
    }
  }

  void _setMode(SessionMode mode) {
    if (_mode == mode) {
      return;
    }
    _mode = mode;
    notifyListeners();
  }
}
