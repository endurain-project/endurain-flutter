import 'package:endurain/core/auth/auth_session_store.dart';
import 'package:endurain/core/config/api_endpoints.dart';
import 'package:endurain/core/constants/api_constants.dart';
import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/network/api_response.dart';
import 'package:endurain/core/network/base_http_client.dart';

/// The two server calls that end a sign-in: the PKCE exchange of a sign-in
/// session, and saving the tokens a `tokens` step carries.
///
/// `SignInFlow` decides when each one runs; this class only talks to the
/// server and the [AuthSessionStore].
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

  /// Exchanges the sign-in session [sessionId] with the PKCE [verifier] and
  /// returns the answer, a sign-in step body: `tokens`, or `mfa` for an SSO
  /// session of an account with MFA.
  ///
  /// [deviceId] is sent as `X-Device-Id` when known. [failureCode] is the
  /// [AppException.code] of a non-`200` answer.
  Future<Map<String, dynamic>> exchange({
    required String serverUrl,
    required String sessionId,
    required String verifier,
    String? deviceId,
    required AppErrorCode failureCode,
  }) {
    final url = Uri.parse(
      '$serverUrl${_endpoints.sessionTokensEndpoint(sessionId)}',
    );
    return _http.postJsonObject(
      url,
      extraHeaders: {ApiConstants.deviceIdHeader: ?deviceId},
      jsonBody: {'code_verifier': verifier},
      failureCode: failureCode,
    );
  }

  /// Saves the tokens of a mobile `tokens` step [body] as the session for
  /// [serverUrl], after reading the account id from the profile.
  ///
  /// [username] is stored only for a password sign-in. Nothing is saved when
  /// the body or the profile is unusable.
  Future<void> saveTokens({
    required String serverUrl,
    required Map<String, dynamic> body,
    String? username,
    required AppErrorCode failureCode,
  }) async {
    try {
      final accessToken = ApiResponse.requiredString(body, 'access_token');
      final refreshToken = ApiResponse.requiredString(body, 'refresh_token');
      final sessionId = ApiResponse.requiredString(body, 'session_id');
      final expiresIn = ApiResponse.requiredPositiveInt(body, 'expires_in');
      final profile = await _fetchProfile(
        serverUrl: serverUrl,
        accessToken: accessToken,
        failureCode: failureCode,
      );

      await _sessionStore.saveSession(
        origin: serverUrl,
        accessToken: accessToken,
        refreshToken: refreshToken,
        sessionId: sessionId,
        accountId: _accountIdOf(profile),
        username: username,
        expiresInSeconds: expiresIn,
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException(failureCode, cause: e);
    }
  }

  /// Reads the account id from the profile body.
  ///
  /// Endurain v0.21 identifies accounts by UUID strings; earlier servers used
  /// positive integers. Both are accepted and returned as text, so the
  /// connection profile id stays an opaque string either way.
  static String _accountIdOf(Map<String, dynamic> profile) {
    final id = profile['id'];
    if (id is String) {
      return ApiResponse.requiredString(profile, 'id');
    }
    return ApiResponse.requiredPositiveInt(profile, 'id').toString();
  }

  /// Fetches the authenticated user's profile to derive the stable server-side
  /// account id. The session store origin-qualifies it into the globally-unique
  /// connection profile id (see `ConnectionIdentity`).
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
