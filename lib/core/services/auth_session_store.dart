import 'package:endurain/core/services/secure_storage_service.dart';

class AuthSessionStore {
  const AuthSessionStore({required SecureStorageService storage})
    : _storage = storage;

  final SecureStorageService _storage;

  Future<String?> getServerUrl() => _storage.getServerUrl();

  Future<String?> getAccessToken() => _storage.getAccessToken();

  Future<String?> getRefreshToken() => _storage.getRefreshToken();

  Future<bool> isAccessTokenExpiringSoon({
    Duration threshold = const Duration(minutes: 2),
  }) {
    return _storage.isAccessTokenExpiringSoon(threshold: threshold);
  }

  Future<void> saveLoginUsername(String username) {
    return _storage.setUsername(username);
  }

  Future<void> saveSession({
    String? accessToken,
    String? refreshToken,
    String? sessionId,
    String? username,
    int? expiresInSeconds,
  }) async {
    if (accessToken != null) {
      await _storage.setAccessToken(accessToken);
    }
    if (refreshToken != null) {
      await _storage.setRefreshToken(refreshToken);
    }
    if (sessionId != null) {
      await _storage.setSessionId(sessionId);
    }
    if (username != null) {
      await _storage.setUsername(username);
    }
    if (expiresInSeconds != null) {
      await _storage.setAccessTokenExpiresAt(
        DateTime.now().toUtc().add(Duration(seconds: expiresInSeconds)),
      );
    }
  }

  Future<void> clear() {
    return _storage.clearAuthTokens();
  }
}
