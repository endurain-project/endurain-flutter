import 'package:endurain/core/config/api_endpoints.dart';
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
  const PkceTokenExchanger({
    required this._sessionStore,
    required BaseHttpClient http,
    ApiEndpoints? endpoints,
  }) : _http = http,
       _endpoints = endpoints ?? const ApiEndpoints();

  final AuthSessionStore _sessionStore;
  final BaseHttpClient _http;
  final ApiEndpoints _endpoints;

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
      final profile = await _http.getJsonObject(
        Uri.parse('$serverUrl${_endpoints.profileEndpoint}'),
        extraHeaders: {'Authorization': 'Bearer $accessToken'},
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

      return AuthResult(
        success: true,
        mfaRequired: false,
        accessToken: accessToken,
        refreshToken: refreshToken,
        sessionId: returnedSessionId,
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException(failureCode, cause: e);
    }
  }
}
