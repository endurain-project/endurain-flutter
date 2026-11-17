import 'package:endurain/core/auth/auth_session_store.dart';

import 'package:endurain/core/auth/secure_storage_service.dart';
import 'package:endurain/core/auth/sign_in_flow.dart';
import 'package:endurain/core/config/api_endpoints.dart';
import 'package:endurain/core/config/app_config.dart';
import 'package:endurain/core/constants/api_constants.dart';
import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/models/identity_provider.dart';
import 'package:endurain/core/network/base_http_client.dart';
import 'package:endurain/core/utils/pkce_utils.dart';
import 'package:endurain/core/utils/server_url_resolver.dart';
import 'package:http/http.dart' as http;

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
  /// The app's SSO callback address: the default `ALLOWED_REDIRECT_URIS` of an
  /// Endurain (v0.21+) server, in the reverse-DNS form RFC 8252 recommends.
  static const callbackUrl = 'com.endurain.endurain:/auth/sso/callback';

  /// Parsed form of [callbackUrl], the single source of truth for the SSO
  /// deep-link contract. Use [matchesCallback] instead of hardcoding the
  /// scheme/host/path anywhere else.
  static final Uri _callbackUri = Uri.parse(callbackUrl);

  /// Returns `true` when [uri] is the SSO callback deep link, matched by
  /// scheme, host, and path. Query parameters (`session_id`, `error`) are not
  /// inspected here. Keeps the callback contract defined once in [callbackUrl].
  static bool matchesCallback(Uri uri) =>
      uri.scheme == _callbackUri.scheme &&
      uri.host == _callbackUri.host &&
      uri.path == _callbackUri.path;

  /// Whether the server's `allowed_redirect_uris` lists [callbackUrl], matched
  /// as the server does: the scheme case-insensitively, the rest exactly.
  ///
  /// `null` (a server that does not publish the list) counts as allowed, so
  /// the sign-in is tried and the server decides.
  static bool isCallbackAllowed(List<String>? allowedRedirectUris) {
    if (allowedRedirectUris == null) {
      return true;
    }
    final separator = callbackUrl.indexOf(':');
    final scheme = callbackUrl.substring(0, separator).toLowerCase();
    final rest = callbackUrl.substring(separator);
    return allowedRedirectUris.any((entry) {
      final index = entry.indexOf(':');
      return index > 0 &&
          entry.substring(0, index).toLowerCase() == scheme &&
          entry.substring(index) == rest;
    });
  }

  /// The SSO failure codes the server documents for the callback's `error`
  /// parameter. Anything else in the link is treated as a generic failure.
  static const Set<String> knownCallbackErrors = {
    'sso_failed',
    'sso_email_missing',
    'sso_email_unverified',
    'sso_auto_create_disabled',
    'sso_link_by_email_disabled',
    'sso_approval_pending',
    'sso_account_disabled',
  };

  SsoService({
    SecureStorageService? storage,
    AuthSessionStore? sessionStore,
    ServerUrlResolver? urlResolver,
    BaseHttpClient? baseClient,
    http.Client? httpClient,
    DateTime Function()? now,
    AppConfig config = AppConfig.defaults,
    ApiEndpoints? endpoints,
    SignInFlow? signInFlow,
  }) {
    final resolvedStorage = storage ?? SecureStorageService();
    _sessionStore = sessionStore ?? AuthSessionStore(storage: resolvedStorage);
    _urlResolver =
        urlResolver ??
        ServerUrlResolver(storage: resolvedStorage, config: config);
    _http = baseClient ?? BaseHttpClient(httpClient: httpClient);
    _now = now ?? DateTime.now;
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
  late final DateTime Function() _now;
  late final ApiEndpoints _endpoints;
  late final SignInFlow _signIn;

  // Pending SSO PKCE flow state; cleared on successful exchange, error, or
  // explicit cancellation via [clearPkce].
  _SsoPkceState? _pendingPkce;

  /// Get list of enabled identity providers from server
  Future<List<IdentityProvider>> getEnabledProviders({
    String? serverUrl,
  }) async {
    final url = await _urlResolver.resolve(serverUrl: serverUrl);
    // A page (`{items, total, page, num_records, next}`); one page of the
    // largest size covers every realistic number of providers.
    final apiUrl = Uri.parse('$url${_endpoints.idpListEndpoint}')
        .replace(queryParameters: {'num_records': '200'});

    try {
      final data = await _http.getJson(
        apiUrl,
        failureCode: AppErrorCode.fetchProvidersFailed,
      );

      final Object? providers = data is Map ? data['items'] : data;
      if (providers is! List) {
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
      throw AppException(AppErrorCode.fetchProvidersFailed, cause: e);
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
      verifier: pkce.verifier,
      serverUrl: url,
      createdAt: _now(),
    );

    // Build OAuth URL with PKCE challenge
    final oauthUrl = Uri.parse('$url${_endpoints.idpLoginEndpoint}/$idpSlug')
        .replace(
          queryParameters: {
            'code_challenge': pkce.challenge,
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

    final verifier = pending.verifier;
    // Clear state before the network call — one-time exchange.
    _pendingPkce = null;
    // The answer is `tokens`, or `mfa` for an account with MFA, which the
    // shared [SignInFlow] keeps for `AuthService.verifyMfa`.
    return _signIn.startExchange(
      serverUrl: pending.serverUrl,
      sessionId: sessionId,
      verifier: verifier,
      failureCode: AppErrorCode.tokenExchangeFailed,
      fallbackCode: AppErrorCode.ssoTokenExchangeError,
    );
  }

  /// Clears any pending PKCE flow (e.g. when the user cancels SSO).
  void clearPkce() {
    _pendingPkce = null;
  }
}
