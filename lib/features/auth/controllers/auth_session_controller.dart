import 'package:flutter/foundation.dart';
import 'package:endurain/core/services/auth_service.dart';

class AuthSessionController extends ChangeNotifier {
  AuthSessionController({required AuthService authService})
    : _authService = authService;

  final AuthService _authService;

  bool _isLoading = true;
  bool _isAuthenticated = false;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    _isAuthenticated = await _authService.isAuthenticated();
    _isLoading = false;
    notifyListeners();
  }

  void markAuthenticated() {
    _isAuthenticated = true;
    _isLoading = false;
    notifyListeners();
  }

  void markUnauthenticated() {
    _isAuthenticated = false;
    _isLoading = false;
    notifyListeners();
  }

  /// Re-checks the active session when the app resumes from background.
  ///
  /// Does nothing when unauthenticated, so it is safe to call on every
  /// app-resumed lifecycle event. On success the state is updated
  /// (authenticated or unauthenticated) and listeners are notified.
  Future<void> revalidate() async {
    if (!_isAuthenticated) {
      return;
    }
    final stillAuthenticated = await _authService.isAuthenticated();
    if (_isAuthenticated != stillAuthenticated) {
      _isAuthenticated = stillAuthenticated;
      notifyListeners();
    }
  }
}
