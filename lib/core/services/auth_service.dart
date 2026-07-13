import 'package:http/http.dart' as http;
import 'package:endurain/core/config/api_endpoints.dart';
import 'package:endurain/core/config/app_config.dart';
import 'package:endurain/core/services/auth_session_store.dart';
import 'package:endurain/core/services/api_response.dart';
import 'package:endurain/core/services/base_http_client.dart';
import 'package:endurain/core/services/pkce_token_exchanger.dart';
import 'package:endurain/core/services/secure_storage_service.dart';
import 'package:endurain/core/constants/api_constants.dart';
import 'package:endurain/core/models/auth_session.dart';
import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/utils/pkce_utils.dart';
import 'package:endurain/core/utils/run_with_cleanup.dart';
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
    _sessionStore =
        sessionStore ??
        AuthSessionStore(storage: resolvedStorage, config: config);
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
  String? _pendingLoginOrigin;

  // Refreshes are single-flight per session revision. A replacement login may
  // refresh independently without joining a stale request from the old session.
  final Map<String, Future<bool>> _inFlightRefreshes = {};

  /// Runs [action], always clearing the in-flight PKCE verifier on failure.
  /// Re-throws [AppException]s unchanged; wraps any other error in an
  /// [AppException] with [fallbackCode].
  Future<T> _withPkceCleanup<T>(
    Future<T> Function() action, {
    required AppErrorCode fallbackCode,
  }) => runWithCleanup(
    action,
    onCleanup: () {
      _pkce = null;
      _pendingLoginOrigin = null;
    },
    fallbackCode: fallbackCode,
  );

  /// Login with username and password using PKCE flow
  /// Returns AuthResult with MFA status or session ID for token exchange
  Future<AuthResult> login(
    String username,
    String password, {
    String? serverUrl,
  }) async {
    final url = await _urlResolver.resolve(serverUrl: serverUrl);
    _pendingLoginOrigin = url;

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
    final serverUrl = _pendingLoginOrigin ?? await _urlResolver.resolve();

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
    _pendingLoginOrigin = null;

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
  Future<bool> refreshToken() async {
    final session = await _sessionStore.readSession();
    if (session == null) {
      await _sessionStore.clear();
      return false;
    }
    final existing = _inFlightRefreshes[session.revision];
    if (existing != null) {
      return existing;
    }
    final refresh = _refreshToken(session).whenComplete(() {
      _inFlightRefreshes.remove(session.revision);
    });
    _inFlightRefreshes[session.revision] = refresh;
    return refresh;
  }

  Future<bool> _refreshToken(AuthSession session) async {
    final serverUrl = await _urlResolver.resolve(serverUrl: session.origin);
    final refreshToken = session.refreshToken;

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

        return _sessionStore.replaceSessionIfCurrent(
          expected: session,
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
          sessionId: returnedSessionId,
          expiresInSeconds: expiresIn,
        );
      } catch (_) {
        // 200 with a malformed body is a definitive contract failure, not a
        // transient blip: the stored tokens cannot be trusted. Clear them.
        return _clearSessionAfterRefreshFailure(session);
      }
    }

    // The server explicitly rejected the refresh token (e.g. revoked, expired,
    // rotated away): clear the session and force re-login.
    if (response.statusCode == 401 || response.statusCode == 403) {
      return _clearSessionAfterRefreshFailure(session);
    }

    // Other non-success statuses (5xx, 429, 408, ...) are transient: keep the
    // session so a temporary server problem does not log the user out.
    return false;
  }

  Future<bool> _clearSessionAfterRefreshFailure(AuthSession session) async {
    await _sessionStore.clearIfProfileCurrent(session);
    return false;
  }

  /// Logout and clear all tokens
  /// Returns true if server logout succeeded, false if it failed
  /// Local tokens are always cleared regardless of server response
  Future<bool> logout() async {
    final session = await _sessionStore.readSession();

    bool serverLogoutSuccess = true;

    // Call server-side logout if we have credentials
    if (session != null && session.refreshToken.isNotEmpty) {
      try {
        final serverUrl = await _urlResolver.resolve(serverUrl: session.origin);
        final url = Uri.parse('$serverUrl${_endpoints.logoutEndpoint}');
        final response = await _http.post(
          url,
          extraHeaders: {
            ApiConstants.authorizationHeader: 'Bearer ${session.refreshToken}',
          },
        );
        serverLogoutSuccess = response.statusCode == 200;
      } catch (e) {
        // Server logout failed (network error, server down, token expired)
        serverLogoutSuccess = false;
      }
    }

    // Always clear local tokens
    if (session == null) {
      await _sessionStore.clear();
    } else {
      await _sessionStore.clearIfProfileCurrent(session);
    }

    return serverLogoutSuccess;
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final session = await _sessionStore.readSession();
    if (session == null) {
      return false;
    }

    if (session.accessToken.isNotEmpty &&
        !DateTime.now()
            .toUtc()
            .add(const Duration(minutes: 2))
            .isAfter(session.accessTokenExpiresAt)) {
      return true;
    }

    if (session.refreshToken.isEmpty) {
      await _sessionStore.clearIfCurrent(session);
      return false;
    }

    // refreshToken() clears the session itself on a definitive rejection and
    // keeps it on a transient failure, so do not clear here — that would log
    // the user out on a temporary network/server blip.
    final refreshed = await refreshToken();
    return refreshed || await _sessionStore.readSession() != null;
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
