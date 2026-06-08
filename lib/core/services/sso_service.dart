import 'package:http/http.dart' as http;
import 'package:endurain/core/config/api_endpoints.dart';
import 'package:endurain/core/config/app_config.dart';
import 'package:endurain/core/services/auth_session_store.dart';
import 'package:endurain/core/models/identity_provider.dart';
import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/services/base_http_client.dart';
import 'package:endurain/core/services/pkce_token_exchanger.dart';
import 'package:endurain/core/services/secure_storage_service.dart';
import 'package:endurain/core/constants/api_constants.dart';
import 'package:endurain/core/utils/pkce_utils.dart';
import 'package:endurain/core/utils/server_url_resolver.dart';
import 'package:endurain/core/services/auth_service.dart';

/// Holds in-process state for a pending SSO PKCE flow.
///
/// Bound to a specific server URL so that a stale callback from a different
/// server cannot be exchanged. [createdAt] anchors the TTL check in
/// [SsoService.exchangeSessionForTokens].
///
/// Note: the IdP slug is not stored here because the current callback
/// contract does not echo the IdP identifier, making client-side verification
/// impossible. If a future backend version includes a flow or IdP identifier
/// in the callback, add it here and verify it in [SsoService.exchangeSessionForTokens].
class _SsoPkceState {
  _SsoPkceState({
    required this.verifier,
    required this.serverUrl,
    required this.createdAt,
  });

  final String verifier;
  final String serverUrl;
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
    AppConfig config = AppConfig.defaults,
    ApiEndpoints? endpoints,
  }) {
    final resolvedStorage = storage ?? SecureStorageService();
    _sessionStore = sessionStore ?? AuthSessionStore(storage: resolvedStorage);
    _urlResolver = urlResolver ??
        ServerUrlResolver(storage: resolvedStorage, config: config);
    _http = baseClient ?? BaseHttpClient(httpClient: httpClient);
    _now = now ?? DateTime.now;
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
  late final DateTime Function() _now;
  late final ApiEndpoints _endpoints;
  late final PkceTokenExchanger _exchanger;

  // Pending SSO PKCE flow state; cleared on successful exchange, error, or
  // explicit cancellation via [clearPkce].
  _SsoPkceState? _pendingPkce;

  /// Get list of enabled identity providers from server
  Future<List<IdentityProvider>> getEnabledProviders({
    String? serverUrl,
  }) async {
    final url = await _urlResolver.resolve(serverUrl: serverUrl);
    final apiUrl = Uri.parse('$url${_endpoints.idpListEndpoint}');

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
  /// Binds the generated PKCE state to [serverUrl] and records the creation
  /// time for TTL enforcement. Starting a new flow discards any previously
  /// pending state.
  ///
  /// Returns the system browser URL to open.
  Future<String> initiateOAuth(String idpSlug, {String? serverUrl}) async {
    final url = await _urlResolver.resolve(serverUrl: serverUrl, save: true);

    // Generate PKCE parameters
    final pkce = PkceUtils.generatePkce();

    _pendingPkce = _SsoPkceState(
      verifier: pkce['verifier']!,
      serverUrl: url,
      createdAt: _now(),
    );

    // Build OAuth URL with PKCE challenge
    final oauthUrl = Uri.parse('$url${_endpoints.idpLoginEndpoint}/$idpSlug')
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
  ///
  /// The exchange is performed against [_SsoPkceState.serverUrl] — the server
  /// that initiated the flow — rather than the currently stored server URL.
  /// If the stored server URL has changed since the flow was initiated the
  /// callback is rejected to prevent a stale or cross-server token exchange.
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

    // Reject the callback if the stored server URL no longer matches the
    // server that initiated this flow.
    final currentServerUrl = await _urlResolver.resolve();
    if (currentServerUrl != pending.serverUrl) {
      _pendingPkce = null;
      throw const AppException(AppErrorCode.pkceVerifierMissingRestartLogin);
    }

    try {
      final verifier = pending.verifier;
      // Clear state before the network call — one-time exchange.
      _pendingPkce = null;
      return await _exchanger.exchange(
        serverUrl: pending.serverUrl,
        sessionId: sessionId,
        verifier: verifier,
        failureCode: AppErrorCode.tokenExchangeFailed,
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
