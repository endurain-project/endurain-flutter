import 'package:http/http.dart' as http;
import 'package:endurain/core/services/auth_session_store.dart';
import 'package:endurain/core/models/identity_provider.dart';
import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/services/api_response.dart';
import 'package:endurain/core/services/base_http_client.dart';
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
    BaseHttpClient? baseClient,
    http.Client? httpClient,
  }) {
    final resolvedStorage = storage ?? SecureStorageService();
    _sessionStore =
        sessionStore ?? AuthSessionStore(storage: resolvedStorage);
    _urlResolver =
        urlResolver ?? ServerUrlResolver(storage: resolvedStorage);
    _http = baseClient ?? BaseHttpClient(httpClient: httpClient);
  }

  late final AuthSessionStore _sessionStore;
  late final ServerUrlResolver _urlResolver;
  late final BaseHttpClient _http;

  // Store PKCE temporarily during SSO flow
  Map<String, String>? _ssoPkce;

  /// Get list of enabled identity providers from server
  Future<List<IdentityProvider>> getEnabledProviders({
    String? serverUrl,
  }) async {
    final url = await _urlResolver.resolve(serverUrl: serverUrl);
    final apiUrl = Uri.parse('$url${ApiConstants.idpListEndpoint}');

    try {
      final data = await _http.getJson(
        apiUrl,
        failureCode: AppErrorCode.fetchProvidersFailed,
      );

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
      final verifier = _ssoPkce!['verifier'];
      // Clear verifier before the network call — one-time exchange.
      _ssoPkce = null;
      final data = await _http.postJsonObject(
        url,
        jsonBody: {'code_verifier': verifier},
        failureCode: AppErrorCode.tokenExchangeFailed,
      );

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
