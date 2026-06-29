import 'package:http/http.dart' as http;
import 'package:endurain/core/config/api_endpoints.dart';
import 'package:endurain/core/config/app_config.dart';
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
    AppConfig config = AppConfig.defaults,
    ApiEndpoints? endpoints,
  }) {
    final resolvedStorage = storage ?? SecureStorageService();
    _sessionStore = sessionStore ?? AuthSessionStore(storage: resolvedStorage);
    _urlResolver =
        urlResolver ??
        ServerUrlResolver(storage: resolvedStorage, config: config);
    _http = baseClient ?? BaseHttpClient(httpClient: httpClient);
    _endpoints = endpoints ?? ApiEndpoints(config);
    _exchanger = PkceTokenExchanger(
      sessionStore: _sessionStore,
      http: _http,
      endpoints: _endpoints,
    );
  }

  late final AuthSessionStore _sessionStore;
  late final ServerUrlResolver _urlResolver;
  late final BaseHttpClient _http;
  late final ApiEndpoints _endpoints;
  late final PkceTokenExchanger _exchanger;

  // Store PKCE temporarily during auth flow
  Map<String, String>? _pkce;

  // Tracks an in-progress refresh so concurrent callers share a single
  // network round-trip (see [refreshToken]).
  Future<bool>? _inFlightRefresh;

  /// Runs [action], always clearing the in-flight PKCE verifier afterwards.
  /// Re-throws [AppException]s unchanged; wraps any other error in an
  /// [AppException] with [fallbackCode].
  Future<T> _withPkceCleanup<T>(
    Future<T> Function() action, {
    required AppErrorCode fallbackCode,
  }) async {
    try {
      return await action();
    } on AppException {
      _pkce = null;
      rethrow;
    } catch (e) {
      _pkce = null;
      throw AppException(fallbackCode, cause: e);
    }
  }

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
      '$url${_endpoints.tokenEndpoint}?code_challenge=${_pkce!['challenge']}&code_challenge_method=S256',
    );

    return _withPkceCleanup(() async {
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
        return _exchangeSessionForTokens(url, sessionId, username);
      }

      throw const AppException(AppErrorCode.noSessionIdReceived);
    }, fallbackCode: AppErrorCode.loginError);
  }

  /// Verify MFA code after initial login using PKCE flow
  Future<AuthResult> verifyMfa(String username, String mfaCode) async {
    final serverUrl = await _urlResolver.resolve();

    if (_pkce == null || _pkce!['verifier'] == null) {
      throw const AppException(AppErrorCode.pkceVerifierMissingRestartLogin);
    }

    // MFA verification with PKCE uses query parameters
    final url = Uri.parse(
      '$serverUrl${_endpoints.mfaVerifyEndpoint}?code_challenge=${_pkce!['challenge']}&code_challenge_method=S256',
    );

    return _withPkceCleanup(() async {
      final data = await _http.postJsonObject(
        url,
        jsonBody: {'username': username, 'mfa_code': mfaCode},
        failureCode: AppErrorCode.mfaVerificationFailed,
      );

      // PKCE flow returns session_id for token exchange
      final sessionId = ApiResponse.optionalString(data, 'session_id');

      if (sessionId != null) {
        // Exchange session for tokens
        return _exchangeSessionForTokens(serverUrl, sessionId, username);
      }

      throw const AppException(AppErrorCode.noSessionIdReceived);
    }, fallbackCode: AppErrorCode.mfaVerificationError);
  }

  /// Exchange session ID for tokens using PKCE code verifier
  Future<AuthResult> _exchangeSessionForTokens(
    String serverUrl,
    String sessionId,
    String username,
  ) async {
    if (_pkce == null || _pkce!['verifier'] == null) {
      throw const AppException(AppErrorCode.pkceVerifierMissingRestartLogin);
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

  /// Refresh access token using refresh token.
  ///
  /// Refresh is single-flight: concurrent callers share the same in-progress
  /// future and only the first triggers a network round-trip. Because the
  /// server rotates the refresh token on every refresh, allowing parallel
  /// refreshes would let one rotation invalidate the token the others are
  /// using and spuriously clear the session.
  Future<bool> refreshToken() {
    return _inFlightRefresh ??= _refreshToken().whenComplete(() {
      _inFlightRefresh = null;
    });
  }

  Future<bool> _refreshToken() async {
    final serverUrl = await _sessionStore.getServerUrl();
    final refreshToken = await _sessionStore.getRefreshToken();

    if (serverUrl == null || serverUrl.isEmpty || refreshToken == null) {
      return _clearSessionAfterRefreshFailure();
    }

    final url = Uri.parse('$serverUrl${_endpoints.refreshEndpoint}');

    final http.Response response;
    try {
      response = await _http.post(
        url,
        extraHeaders: {
          ApiConstants.authorizationHeader: 'Bearer $refreshToken',
        },
      );
    } catch (_) {
      // Transport-level failure (no connectivity, timeout, DNS). This is
      // transient: the refresh token is almost certainly still valid, so keep
      // the session and let the next attempt retry rather than logging the
      // user out on a flaky network.
      return false;
    }

    if (response.statusCode == 200) {
      try {
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
      } catch (_) {
        // 200 with a malformed body is a definitive contract failure, not a
        // transient blip: the stored tokens cannot be trusted. Clear them.
        return _clearSessionAfterRefreshFailure();
      }
    }

    // The server explicitly rejected the refresh token (e.g. revoked, expired,
    // rotated away): clear the session and force re-login.
    if (response.statusCode == 401 || response.statusCode == 403) {
      return _clearSessionAfterRefreshFailure();
    }

    // Other non-success statuses (5xx, 429, 408, ...) are transient: keep the
    // session so a temporary server problem does not log the user out.
    return false;
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
        final url = Uri.parse('$serverUrl${_endpoints.logoutEndpoint}');
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

    // refreshToken() clears the session itself on a definitive rejection and
    // keeps it on a transient failure, so do not clear here — that would log
    // the user out on a temporary network/server blip.
    return refreshToken();
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
