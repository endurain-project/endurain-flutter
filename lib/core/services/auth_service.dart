import 'package:http/http.dart' as http;
import 'package:endurain/core/services/auth_session_store.dart';
import 'package:endurain/core/services/api_response.dart';
import 'package:endurain/core/services/base_http_client.dart';
import 'package:endurain/core/services/pkce_token_exchanger.dart';
import 'package:endurain/core/services/secure_storage_service.dart';
import 'package:endurain/core/constants/api_constants.dart';
import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/utils/pkce_utils.dart';
import 'package:endurain/core/utils/server_url_resolver.dart';

class AuthService {
  AuthService({
    SecureStorageService? storage,
    AuthSessionStore? sessionStore,
    ServerUrlResolver? urlResolver,
    BaseHttpClient? baseClient,
    http.Client? httpClient,
  }) {
    final resolvedStorage = storage ?? SecureStorageService();
    _sessionStore =
        sessionStore ?? AuthSessionStore(storage: resolvedStorage);
    _urlResolver =
        urlResolver ?? ServerUrlResolver(storage: resolvedStorage);
    _http = baseClient ?? BaseHttpClient(httpClient: httpClient);
    _exchanger = PkceTokenExchanger(
      sessionStore: _sessionStore,
      http: _http,
    );
  }

  late final AuthSessionStore _sessionStore;
  late final ServerUrlResolver _urlResolver;
  late final BaseHttpClient _http;
  late final PkceTokenExchanger _exchanger;

  // Store PKCE temporarily during auth flow
  Map<String, String>? _pkce;

  /// Login with username and password using PKCE flow
  /// Returns AuthResult with MFA status or session ID for token exchange
  Future<AuthResult> login(
    String username,
    String password, {
    String? serverUrl,
  }) async {
    final url = await _urlResolver.resolve(serverUrl: serverUrl, save: true);

    // Generate PKCE parameters
    _pkce = PkceUtils.generatePkce();

    final apiUrl = Uri.parse(
      '$url${ApiConstants.tokenEndpoint}?code_challenge=${_pkce!['challenge']}&code_challenge_method=S256',
    );

    try {
      final data = await _http.postJsonObject(
        apiUrl,
        extraHeaders: {
          ApiConstants.contentTypeHeader:
              ApiConstants.contentTypeFormUrlEncoded,
        },
        rawBody: {'username': username, 'password': password},
        failureCode: AppErrorCode.loginFailed,
      );

      // Check if MFA is required
      if (data['mfa_required'] == true) {
        // Store username for MFA verification
        await _sessionStore.saveLoginUsername(username);

        return AuthResult(
          success: true,
          mfaRequired: true,
          username: data['username'] as String?,
          message: data['message'] as String?,
        );
      }

      // PKCE flow returns session_id for token exchange
      final sessionId = ApiResponse.optionalString(data, 'session_id');

      if (sessionId != null) {
        // Exchange session for tokens
        return await _exchangeSessionForTokens(url, sessionId, username);
      }

      throw const AppException(AppErrorCode.noSessionIdReceived);
    } on AppException {
      _pkce = null;
      rethrow;
    } catch (e) {
      _pkce = null; // Clear verifier on error
      throw AppException(AppErrorCode.loginError, cause: e);
    }
  }

  /// Verify MFA code after initial login using PKCE flow
  Future<AuthResult> verifyMfa(String username, String mfaCode) async {
    final serverUrl = await _urlResolver.resolve();

    if (_pkce == null || _pkce!['verifier'] == null) {
      throw const AppException(AppErrorCode.pkceVerifierMissingRestartLogin);
    }

    // MFA verification with PKCE uses query parameters
    final url = Uri.parse(
      '$serverUrl${ApiConstants.mfaVerifyEndpoint}?code_challenge=${_pkce!['challenge']}&code_challenge_method=S256',
    );

    try {
      final data = await _http.postJsonObject(
        url,
        jsonBody: {'username': username, 'mfa_code': mfaCode},
        failureCode: AppErrorCode.mfaVerificationFailed,
      );

      // PKCE flow returns session_id for token exchange
      final sessionId = ApiResponse.optionalString(data, 'session_id');

      if (sessionId != null) {
        // Exchange session for tokens
        return await _exchangeSessionForTokens(
          serverUrl,
          sessionId,
          username,
        );
      }

      throw const AppException(AppErrorCode.noSessionIdReceived);
    } on AppException {
      _pkce = null;
      rethrow;
    } catch (e) {
      _pkce = null; // Clear verifier on error
      throw AppException(AppErrorCode.mfaVerificationError, cause: e);
    }
  }

  /// Exchange session ID for tokens using PKCE code verifier
  Future<AuthResult> _exchangeSessionForTokens(
    String serverUrl,
    String sessionId,
    String username,
  ) async {
    if (_pkce == null || _pkce!['verifier'] == null) {
      throw const AppException(AppErrorCode.pkceVerifierMissing);
    }

    final verifier = _pkce!['verifier']!;
    // Clear verifier before the network call — one-time exchange.
    _pkce = null;

    return _exchanger.exchange(
      serverUrl: serverUrl,
      sessionId: sessionId,
      verifier: verifier,
      username: username,
      failureCode: AppErrorCode.tokenExchangeFailed,
    );
  }

  /// Refresh access token using refresh token
  Future<bool> refreshToken() async {
    final serverUrl = await _sessionStore.getServerUrl();
    final refreshToken = await _sessionStore.getRefreshToken();

    if (serverUrl == null || serverUrl.isEmpty || refreshToken == null) {
      return _clearSessionAfterRefreshFailure();
    }

    final url = Uri.parse('$serverUrl${ApiConstants.refreshEndpoint}');

    try {
      final response = await _http.post(
        url,
        extraHeaders: {
          ApiConstants.authorizationHeader: 'Bearer $refreshToken',
        },
      );

      if (response.statusCode == 200) {
        final data = ApiResponse.decodeJsonObject(response);
        final newAccessToken = ApiResponse.requiredString(data, 'access_token');
        final newRefreshToken = ApiResponse.requiredString(
          data,
          'refresh_token',
        );
        final returnedSessionId = ApiResponse.requiredString(
          data,
          'session_id',
        );
        final expiresIn = ApiResponse.requiredPositiveInt(data, 'expires_in');

        await _sessionStore.saveSession(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
          sessionId: returnedSessionId,
          expiresInSeconds: expiresIn,
        );
        return true;
      }

      return _clearSessionAfterRefreshFailure();
    } catch (e) {
      return _clearSessionAfterRefreshFailure();
    }
  }

  Future<bool> _clearSessionAfterRefreshFailure() async {
    await _sessionStore.clear();
    return false;
  }

  /// Logout and clear all tokens
  /// Returns true if server logout succeeded, false if it failed
  /// Local tokens are always cleared regardless of server response
  Future<bool> logout() async {
    final serverUrl = await _sessionStore.getServerUrl();
    final refreshToken = await _sessionStore.getRefreshToken();

    bool serverLogoutSuccess = true;

    // Call server-side logout if we have credentials
    if (serverUrl != null && refreshToken != null && refreshToken.isNotEmpty) {
      try {
        final url = Uri.parse('$serverUrl${ApiConstants.logoutEndpoint}');
        final response = await _http.post(
          url,
          extraHeaders: {
            ApiConstants.authorizationHeader: 'Bearer $refreshToken',
          },
        );
        serverLogoutSuccess = response.statusCode == 200;
      } catch (e) {
        // Server logout failed (network error, server down, token expired)
        serverLogoutSuccess = false;
      }
    }

    // Always clear local tokens
    await _sessionStore.clear();

    return serverLogoutSuccess;
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final accessToken = await _sessionStore.getAccessToken();
    final storedRefreshToken = await _sessionStore.getRefreshToken();

    if (accessToken != null &&
        accessToken.isNotEmpty &&
        !await _sessionStore.isAccessTokenExpiringSoon()) {
      return true;
    }

    if (storedRefreshToken == null || storedRefreshToken.isEmpty) {
      await _sessionStore.clear();
      return false;
    }

    final refreshed = await refreshToken();
    if (refreshed) {
      return true;
    }

    await _sessionStore.clear();
    return false;
  }
}

/// Authentication result model
class AuthResult {
  final bool success;
  final bool mfaRequired;
  final String? username;
  final String? message;
  final String? accessToken;
  final String? refreshToken;
  final String? sessionId;

  AuthResult({
    required this.success,
    this.mfaRequired = false,
    this.username,
    this.message,
    this.accessToken,
    this.refreshToken,
    this.sessionId,
  });
}
