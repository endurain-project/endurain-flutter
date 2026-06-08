import 'package:flutter/foundation.dart';
import 'package:endurain/core/services/auth_service.dart';

class AuthSessionController extends ChangeNotifier {
  AuthSessionController({required AuthService authService})
    : _authService = authService;

  final AuthService _authService;

  bool isLoading = true;
  bool isAuthenticated = false;

  Future<void> initialize() async {
    isLoading = true;
    notifyListeners();

    isAuthenticated = await _authService.isAuthenticated();
    isLoading = false;
    notifyListeners();
  }

  void markAuthenticated() {
    isAuthenticated = true;
    isLoading = false;
    notifyListeners();
  }

  void markUnauthenticated() {
    isAuthenticated = false;
    isLoading = false;
    notifyListeners();
  }

  /// Re-checks the active session when the app resumes from background.
  ///
  /// Does nothing when unauthenticated, so it is safe to call on every
  /// [AppLifecycleState.resumed] event. On success the state is updated
  /// (authenticated or unauthenticated) and listeners are notified.
  Future<void> revalidate() async {
    if (!isAuthenticated) {
      return;
    }
    final stillAuthenticated = await _authService.isAuthenticated();
    if (isAuthenticated != stillAuthenticated) {
      isAuthenticated = stillAuthenticated;
      notifyListeners();
    }
  }
}
