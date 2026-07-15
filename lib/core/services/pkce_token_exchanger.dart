import 'package:endurain/core/config/api_endpoints.dart';
import 'package:endurain/core/constants/api_constants.dart';
import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/services/api_response.dart';
import 'package:endurain/core/services/auth_session_store.dart';
import 'package:endurain/core/services/auth_service.dart';
import 'package:endurain/core/services/base_http_client.dart';

/// Owns the shared POST-exchange-save path for PKCE session token exchanges.
///
/// Both `AuthService` (local login + MFA) and `SsoService` (OAuth callback)
/// POST to the same endpoint with a `code_verifier`, parse identical response
/// fields, and persist tokens through [AuthSessionStore]. Only the error code
/// and whether a username is persisted differ between the two flows.
class PkceTokenExchanger {
  PkceTokenExchanger({
    required this._sessionStore,
    required BaseHttpClient http,
    ApiEndpoints? endpoints,
    int profileFetchAttempts = 3,
    Future<void> Function(int attempt)? retryDelay,
  }) : _http = http,
       _endpoints = endpoints ?? const ApiEndpoints(),
       _profileFetchAttempts = profileFetchAttempts < 1
           ? 1
           : profileFetchAttempts,
       _retryDelay = retryDelay ?? _defaultProfileRetryDelay;

  final AuthSessionStore _sessionStore;
  final BaseHttpClient _http;
  final ApiEndpoints _endpoints;

  /// How many times to attempt the post-exchange profile fetch before giving
  /// up. The tokens have just been issued, so a failure here is almost always
  /// a transient blip; retrying avoids discarding valid credentials.
  final int _profileFetchAttempts;
  final Future<void> Function(int attempt) _retryDelay;

  static Future<void> _defaultProfileRetryDelay(int attempt) =>
      Future<void>.delayed(Duration(milliseconds: 200 * attempt));

  /// Exchanges [sessionId] for bearer tokens using the PKCE [verifier].
  ///
  /// [serverUrl] must be a valid base URL for the current server.
  /// [username] is optional and only stored for local-login flows.
  /// [failureCode] is surfaced as the [AppException.code] on non-success HTTP
  /// responses, so callers can preserve flow-specific UI messaging.
  Future<AuthResult> exchange({
    required String serverUrl,
    required String sessionId,
    required String verifier,
    String? username,
    required AppErrorCode failureCode,
  }) async {
    final url = Uri.parse(
      '$serverUrl${_endpoints.idpSessionTokenExchangeEndpoint}/$sessionId/tokens',
    );

    try {
      final data = await _http.postJsonObject(
        url,
        jsonBody: {'code_verifier': verifier},
        failureCode: failureCode,
      );

      final accessToken = ApiResponse.requiredString(data, 'access_token');
      final refreshToken = ApiResponse.requiredString(data, 'refresh_token');
      final returnedSessionId = ApiResponse.requiredString(data, 'session_id');
      final expiresIn = ApiResponse.requiredPositiveInt(data, 'expires_in');
      final profile = await _fetchProfile(
        serverUrl: serverUrl,
        accessToken: accessToken,
        failureCode: failureCode,
      );
      final profileId = ApiResponse.requiredPositiveInt(
        profile,
        'id',
      ).toString();

      await _sessionStore.saveSession(
        origin: serverUrl,
        accessToken: accessToken,
        refreshToken: refreshToken,
        sessionId: returnedSessionId,
        profileId: profileId,
        username: username,
        expiresInSeconds: expiresIn,
      );

      return AuthResult(success: true, mfaRequired: false);
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException(failureCode, cause: e);
    }
  }

  /// Fetches the authenticated user's profile to derive the stable server-side
  /// account id used as the connection profile id.
  ///
  /// Retries transient failures with a short backoff. The bearer token was
  /// issued moments earlier, so a failure here is almost always a temporary
  /// network hiccup; retrying prevents a single blip from discarding valid
  /// credentials and forcing the user to sign in again. After the final
  /// attempt the underlying error propagates so the caller can surface it.
  Future<Map<String, dynamic>> _fetchProfile({
    required String serverUrl,
    required String accessToken,
    required AppErrorCode failureCode,
  }) async {
    final profileUrl = Uri.parse('$serverUrl${_endpoints.profileEndpoint}');
    Object? lastError;
    StackTrace? lastStackTrace;
    for (var attempt = 0; attempt < _profileFetchAttempts; attempt++) {
      if (attempt > 0) {
        await _retryDelay(attempt);
      }
      try {
        return await _http.getJsonObject(
          profileUrl,
          extraHeaders: {
            ApiConstants.authorizationHeader: 'Bearer $accessToken',
          },
          failureCode: failureCode,
        );
      } catch (error, stackTrace) {
        lastError = error;
        lastStackTrace = stackTrace;
      }
    }
    Error.throwWithStackTrace(lastError!, lastStackTrace!);
  }
}
