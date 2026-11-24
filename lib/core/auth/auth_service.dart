import 'dart:convert';

import 'package:endurain/core/auth/auth_session_store.dart';
import 'package:endurain/core/auth/secure_storage_service.dart';
import 'package:endurain/core/auth/sign_in_flow.dart';
import 'package:endurain/core/config/api_endpoints.dart';
import 'package:endurain/core/config/app_config.dart';
import 'package:endurain/core/constants/api_constants.dart';
import 'package:endurain/core/diagnostics/diagnostics_service.dart';
import 'package:endurain/core/models/auth_session.dart';
import 'package:endurain/core/network/api_response.dart';
import 'package:endurain/core/network/base_http_client.dart';
import 'package:endurain/core/utils/server_url_resolver.dart';
import 'package:http/http.dart' as http;

export 'package:endurain/core/auth/sign_in_flow.dart'
    show AuthResult, SignInStep;

class AuthService {
  AuthService({
    SecureStorageService? storage,
    AuthSessionStore? sessionStore,
    ServerUrlResolver? urlResolver,
    BaseHttpClient? baseClient,
    http.Client? httpClient,
    AppConfig config = AppConfig.defaults,
    ApiEndpoints? endpoints,
    SignInFlow? signInFlow,
    DiagnosticsRecorder? diagnostics,
  }) : _diagnostics = diagnostics ?? const NoopDiagnosticsRecorder() {
    final resolvedStorage = storage ?? SecureStorageService();
    _sessionStore =
        sessionStore ??
        AuthSessionStore(storage: resolvedStorage, config: config);
    _urlResolver =
        urlResolver ??
        ServerUrlResolver(storage: resolvedStorage, config: config);
    _http =
        baseClient ??
        BaseHttpClient(httpClient: httpClient, diagnostics: _diagnostics);
    _endpoints = endpoints ?? ApiEndpoints(config);
    _signIn =
        signInFlow ??
        SignInFlow(
          sessionStore: _sessionStore,
          http: _http,
          storage: resolvedStorage,
          endpoints: _endpoints,
        );
  }

  late final AuthSessionStore _sessionStore;
  late final ServerUrlResolver _urlResolver;
  late final BaseHttpClient _http;
  late final ApiEndpoints _endpoints;
  late final SignInFlow _signIn;
  final DiagnosticsRecorder _diagnostics;

  // Refreshes are single-flight per session revision. A replacement login may
  // refresh independently without joining a stale request from the old session.
  final Map<String, Future<bool>> _inFlightRefreshes = {};

  /// Starts a password sign-in (PKCE, mobile). The result says whether the
  /// user is signed in or which step comes next ([verifyMfa],
  /// [changePassword]).
  Future<AuthResult> login(
    String username,
    String password, {
    String? serverUrl,
  }) async {
    final url = await _urlResolver.resolve(serverUrl: serverUrl);
    return _signIn.startPassword(
      serverUrl: url,
      username: username,
      password: password,
    );
  }

  /// Answers the pending MFA step, of a password or an SSO sign-in.
  Future<AuthResult> verifyMfa(String mfaCode) => _signIn.verifyMfa(mfaCode);

  /// Answers the pending password-change step with [newPassword].
  Future<AuthResult> changePassword(String newPassword) =>
      _signIn.changePassword(newPassword);

  /// Abandons a sign-in waiting for [verifyMfa] or [changePassword].
  void cancelSignIn() => _signIn.cancel();

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
      // A mobile client sends its refresh token in the body; the
      // `Authorization` header carries access tokens only.
      response = await _http.post(
        url,
        extraHeaders: const {
          ApiConstants.contentTypeHeader: ApiConstants.contentTypeJson,
        },
        body: jsonEncode({'refresh_token': refreshToken}),
      );
    } catch (error) {
      // Transport-level failure (no connectivity, timeout, DNS). This is
      // transient: the refresh token is almost certainly still valid, so keep
      // the session and let the next attempt retry rather than logging the
      // user out on a flaky network.
      _recordRefreshFailure('transport', error: error);
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

        final replaced = await _sessionStore.replaceSessionIfCurrent(
          expected: session,
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
          sessionId: returnedSessionId,
          expiresInSeconds: expiresIn,
        );
        if (!replaced) {
          // Another sign-in or sign-out replaced the session mid-refresh.
          _recordRefreshFailure('session_superseded');
        }
        return replaced;
      } catch (error) {
        // 200 with a malformed body is a definitive contract failure, not a
        // transient blip: the stored tokens cannot be trusted. Clear them.
        _recordRefreshFailure('malformed_response', error: error);
        return _clearSessionAfterRefreshFailure(
          session,
          reason: 'refresh_malformed_response',
        );
      }
    }

    // The server explicitly rejected the refresh token (e.g. revoked, expired,
    // rotated away): every refusal is a final `401` with
    // `urn:endurain:error:session-ended`. Clear the session and force
    // re-login; do not retry.
    if (response.statusCode == 401 || response.statusCode == 403) {
      _recordRefreshFailure('rejected', status: response.statusCode);
      return _clearSessionAfterRefreshFailure(
        session,
        reason: 'refresh_rejected',
      );
    }

    // Other non-success statuses (5xx, 429, 408, ...) are transient: keep the
    // session so a temporary server problem does not log the user out.
    _recordRefreshFailure('server_error', status: response.statusCode);
    return false;
  }

  Future<bool> _clearSessionAfterRefreshFailure(
    AuthSession session, {
    required String reason,
  }) async {
    // Recorded only once the store confirms it: a session another sign-in
    // replaced meanwhile is left alone, and a failed clear throws.
    if (await _sessionStore.clearIfProfileCurrent(session)) {
      _diagnostics.recordBreadcrumbSync(
        DiagnosticsEvents.authSessionCleared,
        details: {'reason': reason},
      );
    }
    return false;
  }

  void _recordRefreshFailure(String reason, {Object? error, int? status}) {
    _diagnostics.recordBreadcrumbSync(
      DiagnosticsEvents.authRefreshFailed,
      details: {
        'reason': reason,
        'status': ?status,
        if (error != null) ...diagnosticErrorDetails(error),
      },
    );
  }

  /// Logout and clear all tokens
  /// Returns true if server logout succeeded, false if it failed
  /// Local tokens are always cleared regardless of server response
  Future<bool> logout() async {
    // An unreadable store must not block sign-out: treat it as no session so
    // the local clear below still runs.
    final session = await _sessionStore.readSession().then<AuthSession?>(
      (value) => value,
      onError: (Object _) => null,
    );

    bool serverLogoutSuccess = true;

    // Call server-side logout if we have credentials
    if (session != null && session.refreshToken.isNotEmpty) {
      try {
        final serverUrl = await _urlResolver.resolve(serverUrl: session.origin);
        final url = Uri.parse('$serverUrl${_endpoints.logoutEndpoint}');
        final response = await _http.post(
          url,
          extraHeaders: const {
            ApiConstants.contentTypeHeader: ApiConstants.contentTypeJson,
          },
          body: jsonEncode({'refresh_token': session.refreshToken}),
        );
        // `200` with `{"idp_logout_url": …}`, also for a token the server
        // already ended. The provider's own session is left as it is.
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

  /// Whether a session is stored locally. Never touches the network, so it is
  /// safe to await on the launch path; use [isAuthenticated] to also confirm
  /// the session is still accepted by the server.
  Future<bool> hasStoredSession() async =>
      await _sessionStore.readSession() != null;

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
      if (await _sessionStore.clearIfCurrent(session)) {
        _diagnostics.recordBreadcrumbSync(
          DiagnosticsEvents.authSessionCleared,
          details: const {'reason': 'no_refresh_token'},
        );
      }
      return false;
    }

    // refreshToken() clears the session itself on a definitive rejection and
    // keeps it on a transient failure, so do not clear here — that would log
    // the user out on a temporary network/server blip.
    final refreshed = await refreshToken();
    return refreshed || await _sessionStore.readSession() != null;
  }
}
