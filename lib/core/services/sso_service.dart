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

/// Holds in-process state for a pending SSO PKCE flow.
///
/// Bound to a specific server URL and IdP slug so that a stale callback
/// from a different server or a replayed session ID cannot be exchanged.
/// [createdAt] anchors the TTL check in [SsoService.exchangeSessionForTokens].
class _SsoPkceState {
  _SsoPkceState({
    required this.verifier,
    required this.serverUrl,
    required this.idpSlug,
    required this.createdAt,
  });

  final String verifier;
  final String serverUrl;
  final String idpSlug;
  final DateTime createdAt;

  bool isExpired(DateTime now, Duration ttl) =>
      now.difference(createdAt) >= ttl;
}

/// Service for SSO/OAuth authentication
class SsoService {
  static const callbackUrl = 'endurain://auth/sso/callback';

  SsoService({
    SecureStorageService? storage,
    AuthSessionStore? sessionStore,
    ServerUrlResolver? urlResolver,
    BaseHttpClient? baseClient,
    http.Client? httpClient,
    DateTime Function()? now,
  }) {
    final resolvedStorage = storage ?? SecureStorageService();
    _sessionStore =
        sessionStore ?? AuthSessionStore(storage: resolvedStorage);
    _urlResolver =
        urlResolver ?? ServerUrlResolver(storage: resolvedStorage);
    _http = baseClient ?? BaseHttpClient(httpClient: httpClient);
    _now = now ?? DateTime.now;
  }

  late final AuthSessionStore _sessionStore;
  late final ServerUrlResolver _urlResolver;
  late final BaseHttpClient _http;
  late final DateTime Function() _now;

  // Pending SSO PKCE flow state; cleared on successful exchange, error, or
  // explicit cancellation via [clearPkce].
  _SsoPkceState? _pendingPkce;

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

  /// Initiate OAuth flow with PKCE.
  ///
  /// Binds the generated PKCE state to [serverUrl] and [idpSlug] and records
  /// the creation time for TTL enforcement. Starting a new flow discards any
  /// previously pending state.
  ///
  /// Returns the system browser URL to open.
  Future<String> initiateOAuth(String idpSlug, {String? serverUrl}) async {
    final url = await _urlResolver.resolve(serverUrl: serverUrl, save: true);

    // Generate PKCE parameters
    final pkce = PkceUtils.generatePkce();

    _pendingPkce = _SsoPkceState(
      verifier: pkce['verifier']!,
      serverUrl: url,
      idpSlug: idpSlug,
      createdAt: _now(),
    );

    // Build OAuth URL with PKCE challenge
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

  /// Exchange session ID for tokens using PKCE code verifier.
  ///
  /// Validates that a pending flow exists and has not expired before calling
  /// the token endpoint. Called after the deep-link callback provides a
  /// [sessionId].
  Future<AuthResult> exchangeSessionForTokens(String sessionId) async {
    // Guard before any network or storage access: no pending flow = restart.
    final pending = _pendingPkce;
    if (pending == null) {
      throw const AppException(AppErrorCode.pkceVerifierMissingRestartLogin);
    }

    if (pending.isExpired(_now(), ApiConstants.ssoPkceTtl)) {
      _pendingPkce = null;
      throw const AppException(AppErrorCode.pkceVerifierMissingRestartLogin);
    }

    final serverUrl = await _urlResolver.resolve();

    final url = Uri.parse(
      '$serverUrl${ApiConstants.idpSessionTokenExchangeEndpoint}/$sessionId/tokens',
    );

    try {
      final verifier = pending.verifier;
      // Clear state before the network call — one-time exchange.
      _pendingPkce = null;
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
      _pendingPkce = null;
      rethrow;
    } catch (e) {
      _pendingPkce = null;
      throw AppException(AppErrorCode.ssoTokenExchangeError, cause: e);
    }
  }

  /// Clears any pending PKCE flow (e.g. when the user cancels SSO).
  void clearPkce() {
    _pendingPkce = null;
  }
}
