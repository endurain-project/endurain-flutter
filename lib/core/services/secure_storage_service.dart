import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/utils/json_parsing.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  // Keys for stored values
  static const _serverUrlKey = 'server_url';
  static const _usernameKey = 'username';
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _sessionIdKey = 'session_id';
  static const _accessTokenExpiresAtKey = 'access_token_expires_at';

  // Read a value. Returns null when the key is absent.
  // Throws [AppException] with [AppErrorCode.secureStorageReadFailed] when the
  // platform storage itself is unavailable (e.g. keychain locked, hardware
  // failure) — a distinct condition from a missing key.
  Future<String?> read({required String key}) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      throw AppException(AppErrorCode.secureStorageReadFailed, cause: e);
    }
  }

  // Write a value
  Future<void> write({required String key, required String value}) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      rethrow;
    }
  }

  // Delete a value
  Future<void> delete({required String key}) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      rethrow;
    }
  }

  // Delete all values
  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      rethrow;
    }
  }

  // Server-specific methods
  Future<String?> getServerUrl() => read(key: _serverUrlKey);
  Future<void> setServerUrl(String url) =>
      write(key: _serverUrlKey, value: url);
  Future<void> deleteServerUrl() => delete(key: _serverUrlKey);

  Future<String?> getUsername() => read(key: _usernameKey);
  Future<void> setUsername(String username) =>
      write(key: _usernameKey, value: username);
  Future<void> deleteUsername() => delete(key: _usernameKey);

  // Token-specific methods
  Future<String?> getAccessToken() => read(key: _accessTokenKey);
  Future<void> setAccessToken(String token) =>
      write(key: _accessTokenKey, value: token);
  Future<void> deleteAccessToken() => delete(key: _accessTokenKey);

  Future<String?> getRefreshToken() => read(key: _refreshTokenKey);
  Future<void> setRefreshToken(String token) =>
      write(key: _refreshTokenKey, value: token);
  Future<void> deleteRefreshToken() => delete(key: _refreshTokenKey);

  Future<String?> getSessionId() => read(key: _sessionIdKey);
  Future<void> setSessionId(String sessionId) =>
      write(key: _sessionIdKey, value: sessionId);
  Future<void> deleteSessionId() => delete(key: _sessionIdKey);

  Future<DateTime?> getAccessTokenExpiresAt() async {
    final value = await read(key: _accessTokenExpiresAtKey);
    if (value == null || value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }

  Future<void> setAccessTokenExpiresAt(DateTime expiresAt) =>
      write(key: _accessTokenExpiresAtKey, value: expiresAt.toUtcIso8601());

  Future<void> deleteAccessTokenExpiresAt() =>
      delete(key: _accessTokenExpiresAtKey);

  Future<bool> isAccessTokenExpiringSoon({
    Duration threshold = const Duration(minutes: 2),
  }) async {
    final expiresAt = await getAccessTokenExpiresAt();
    if (expiresAt == null) {
      return false;
    }
    return DateTime.now().toUtc().add(threshold).isAfter(expiresAt);
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final accessToken = await getAccessToken();
    return accessToken != null && accessToken.isNotEmpty;
  }

  // Clear all auth tokens
  Future<void> clearAuthTokens() async {
    await deleteAccessToken();
    await deleteRefreshToken();
    await deleteSessionId();
    await deleteAccessTokenExpiresAt();
  }
}
