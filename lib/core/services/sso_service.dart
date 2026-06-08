import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:endurain/core/services/auth_session_store.dart';
import 'package:endurain/core/models/identity_provider.dart';
import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/services/api_response.dart';
import 'package:endurain/core/services/secure_storage_service.dart';
import 'package:endurain/core/constants/api_constants.dart';
import 'package:endurain/core/utils/pkce_utils.dart';
import 'package:endurain/core/utils/server_url_resolver.dart';
import 'package:endurain/core/services/auth_service.dart';

/// Service for SSO/OAuth authentication
class SsoService {
  static const callbackUrl = 'endurain://auth/sso/callback';

  SsoService({
    SecureStorageService? storage,
    AuthSessionStore? sessionStore,
    ServerUrlResolver? urlResolver,
    http.Client? httpClient,
  }) {
    final resolvedStorage = storage ?? SecureStorageService();
    _sessionStore =
        sessionStore ?? AuthSessionStore(storage: resolvedStorage);
    _urlResolver =
        urlResolver ?? ServerUrlResolver(storage: resolvedStorage);
    _httpClient = httpClient ?? http.Client();
  }

  late final AuthSessionStore _sessionStore;
  late final ServerUrlResolver _urlResolver;
  late final http.Client _httpClient;

  // Store PKCE temporarily during SSO flow
  Map<String, String>? _ssoPkce;

  /// Get list of enabled identity providers from server
  Future<List<IdentityProvider>> getEnabledProviders({
    String? serverUrl,
  }) async {
    final url = await _urlResolver.resolve(serverUrl: serverUrl);
    final apiUrl = Uri.parse('$url${ApiConstants.idpListEndpoint}');

    try {
      final response = await _httpClient.get(
        apiUrl,
        headers: {ApiConstants.clientTypeHeader: ApiConstants.clientTypeValue},
      );

      if (response.statusCode == 200) {
        final data = ApiResponse.decodeJson(response);

        // Handle both array and object responses
        final List<dynamic> providers;
        if (data is List) {
          providers = data;
        } else if (data is Map && data.containsKey('providers')) {
          providers = data['providers'] as List<dynamic>;
        } else {
          throw const AppException(AppErrorCode.unexpectedResponseFormat);
        }

        return providers
            .map(
              (provider) =>
                  IdentityProvider.fromJson(provider as Map<String, dynamic>),
            )
            .toList();
      } else {
        throw ApiResponse.failure(response, AppErrorCode.fetchProvidersFailed);
      }
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException(AppErrorCode.fetchIdentityProvidersFailed, cause: e);
    }
  }

  /// Initiate OAuth flow with PKCE
  /// Returns the system browser URL to open
  Future<String> initiateOAuth(String idpSlug, {String? serverUrl}) async {
    final url = await _urlResolver.resolve(serverUrl: serverUrl, save: true);

    // Generate PKCE parameters
    _ssoPkce = PkceUtils.generatePkce();

    // Build OAuth URL with PKCE challenge
    final pkce = _ssoPkce!;
    final oauthUrl = Uri.parse('$url${ApiConstants.idpLoginEndpoint}/$idpSlug')
        .replace(
          queryParameters: {
            'code_challenge': pkce['challenge'],
            'code_challenge_method': 'S256',
            'redirect': callbackUrl,
          },
        );
    return oauthUrl.toString();
  }

  /// Exchange session ID for tokens using PKCE code verifier
  /// Called after the deep-link callback provides a session_id
  Future<AuthResult> exchangeSessionForTokens(String sessionId) async {
    final serverUrl = await _urlResolver.resolve();

    if (_ssoPkce == null || _ssoPkce!['verifier'] == null) {
      throw const AppException(AppErrorCode.pkceVerifierMissingRestartLogin);
    }

    final url = Uri.parse(
      '$serverUrl${ApiConstants.idpSessionTokenExchangeEndpoint}/$sessionId/tokens',
    );

    try {
      final response = await _httpClient.post(
        url,
        headers: {
          ApiConstants.contentTypeHeader: ApiConstants.contentTypeJson,
          ApiConstants.clientTypeHeader: ApiConstants.clientTypeValue,
        },
        body: jsonEncode({'code_verifier': _ssoPkce!['verifier']}),
      );

      // Clear verifier after use (one-time exchange)
      _ssoPkce = null;

      if (response.statusCode == 200) {
        final data = ApiResponse.decodeJsonObject(response);

        // Store tokens
        final accessToken = ApiResponse.requiredString(data, 'access_token');
        final refreshToken = ApiResponse.requiredString(data, 'refresh_token');
        final returnedSessionId = ApiResponse.requiredString(
          data,
          'session_id',
        );
        final expiresIn = ApiResponse.requiredPositiveInt(data, 'expires_in');

        await _sessionStore.saveSession(
          accessToken: accessToken,
          refreshToken: refreshToken,
          sessionId: returnedSessionId,
          expiresInSeconds: expiresIn,
        );

        return AuthResult(
          success: true,
          mfaRequired: false,
          accessToken: accessToken,
          refreshToken: refreshToken,
          sessionId: returnedSessionId,
        );
      } else {
        throw ApiResponse.failure(response, AppErrorCode.tokenExchangeFailed);
      }
    } on AppException {
      _ssoPkce = null;
      rethrow;
    } catch (e) {
      _ssoPkce = null; // Clear verifier on error
      throw AppException(AppErrorCode.ssoTokenExchangeError, cause: e);
    }
  }

  /// Clear PKCE verifier (e.g., when user cancels SSO)
  void clearPkce() {
    _ssoPkce = null;
  }
}
