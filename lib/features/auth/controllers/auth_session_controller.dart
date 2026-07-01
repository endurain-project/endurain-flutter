import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:endurain/core/services/app_preferences_store.dart';
import 'package:endurain/core/services/auth_service.dart';

/// The high-level session state that drives top-level routing.
///
/// The app is local-first: recording and local storage never require a server,
/// so an unauthenticated user can opt into [guest] mode and use the app
/// offline, connecting a server later.
enum SessionMode {
  /// The initial session check is still running (splash).
  loading,

  /// No server is configured and the user has not opted into offline use yet;
  /// the app shows the login/onboarding screen.
  unauthenticated,

  /// The user chose to use the app offline without a server. Activities are
  /// recorded and stored locally; uploads are deferred until sign-in.
  guest,

  /// A valid server session exists; uploads and server features are enabled.
  authenticated,
}

class AuthSessionController extends ChangeNotifier {
  AuthSessionController({
    required AuthService authService,
    AppPreferencesStore? preferences,
  }) : _authService = authService,
       _preferences = preferences ?? AppPreferencesStore();

  /// Preferences key that records the user's choice to use the app offline, so
  /// the app does not prompt for login again on the next launch.
  static const String offlineOptInKey = 'session_offline_opted_in';

  final AuthService _authService;
  final AppPreferencesStore _preferences;

  SessionMode _mode = SessionMode.loading;

  SessionMode get mode => _mode;
  bool get isLoading => _mode == SessionMode.loading;
  bool get isAuthenticated => _mode == SessionMode.authenticated;
  bool get isGuest => _mode == SessionMode.guest;

  Future<void> initialize() async {
    _mode = SessionMode.loading;
    notifyListeners();

    if (await _authService.isAuthenticated()) {
      _mode = SessionMode.authenticated;
    } else if (await _readOfflineOptIn()) {
      _mode = SessionMode.guest;
    } else {
      _mode = SessionMode.unauthenticated;
    }
    notifyListeners();
  }

  void markAuthenticated() {
    _setMode(SessionMode.authenticated);
  }

  void markUnauthenticated() {
    _setMode(SessionMode.unauthenticated);
    // Logging out returns the user to onboarding; forget the offline opt-in so
    // the next launch shows login rather than silently re-entering guest mode.
    unawaited(_writeOfflineOptIn(false));
  }

  /// Enters local-only "guest" mode so the user can record activities without
  /// configuring a server. The choice is persisted so the app does not prompt
  /// for login again on the next launch (until the user signs in or logs out).
  Future<void> continueAsGuest() async {
    _setMode(SessionMode.guest);
    await _writeOfflineOptIn(true);
  }

  /// Re-checks the active session when the app resumes from background.
  ///
  /// Only acts on an authenticated session, so it is safe to call on every
  /// app-resumed lifecycle event (guest/loading are left untouched). When the
  /// session has expired the mode drops to [SessionMode.unauthenticated].
  Future<void> revalidate() async {
    if (_mode != SessionMode.authenticated) {
      return;
    }
    final stillAuthenticated = await _authService.isAuthenticated();
    if (!stillAuthenticated) {
      _setMode(SessionMode.unauthenticated);
    }
  }

  void _setMode(SessionMode mode) {
    if (_mode == mode) {
      return;
    }
    _mode = mode;
    notifyListeners();
  }

  Future<bool> _readOfflineOptIn() async {
    try {
      final value = await _preferences.read(key: offlineOptInKey);
      return value == 'true';
    } catch (_) {
      // A missing/unreadable preference simply means "not opted in".
      return false;
    }
  }

  Future<void> _writeOfflineOptIn(bool value) async {
    try {
      if (value) {
        await _preferences.write(key: offlineOptInKey, value: 'true');
      } else {
        await _preferences.delete(key: offlineOptInKey);
      }
    } catch (_) {
      // Best-effort: an unpersisted opt-in only means the user may see the
      // login screen again on the next launch.
    }
  }
}
