import 'dart:async';

import 'package:endurain/core/auth/auth_service.dart';
import 'package:endurain/core/auth/sso_service.dart';
import 'package:endurain/core/config/api_endpoints.dart';
import 'package:endurain/core/config/app_config.dart';
import 'package:endurain/core/diagnostics/diagnostics_service.dart';
import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/models/identity_provider.dart';
import 'package:endurain/core/models/server_settings.dart';
import 'package:endurain/core/services/platform/app_links_service.dart';
import 'package:endurain/core/utils/server_url_resolver.dart';
import 'package:endurain/features/auth/services/auth_coordinator.dart';
import 'package:endurain/features/map/repositories/map_settings_repository.dart';
import 'package:endurain/shared/state/safe_notifier.dart';
import 'package:flutter/foundation.dart' show ValueChanged, VoidCallback;

class LoginController extends SafeNotifier {
  LoginController({
    required this._authCoordinator,
    AppLinksService? appLinksService,
    this._mapSettingsRepository,
    AppConfig? config,
    DiagnosticsRecorder? diagnostics,
  }) : _appLinksService = appLinksService ?? DefaultAppLinksService(),
       _config = config ?? AppConfig.defaults,
       _diagnostics = diagnostics ?? const NoopDiagnosticsRecorder();

  final AuthCoordinator _authCoordinator;
  final AppLinksService _appLinksService;
  final MapSettingsRepository? _mapSettingsRepository;
  final AppConfig _config;
  final DiagnosticsRecorder _diagnostics;

  StreamSubscription<Uri>? _linkSubscription;
  VoidCallback? _onLoginSuccess;
  ValueChanged<Object>? _onError;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isStep2 = false;

  /// The step a sign-in waits on (MFA or a new password), or `null` while the
  /// user is entering credentials.
  SignInStep? _pendingStep;
  List<String> _mfaMethods = const [];
  List<IdentityProvider> _availableIdPs = const [];
  ServerSettings? _serverSettings;
  String _serverUrl = '';

  bool get isLoading => _isLoading;
  bool get obscurePassword => _obscurePassword;
  bool get showMfaInput => _pendingStep == SignInStep.mfa;
  bool get showPasswordChange => _pendingStep == SignInStep.passwordChange;

  /// Whether the MFA step accepts a backup code, which is not only digits.
  bool get mfaAcceptsBackupCodes => _mfaMethods.contains('backup_code');
  bool get isStep2 => _isStep2;
  List<IdentityProvider> get availableIdPs => List.unmodifiable(_availableIdPs);
  ServerSettings? get serverSettings => _serverSettings;

  /// The server origin submitted for the current login flow.
  String get serverUrl => _serverUrl;

  bool get localLoginEnabled => _serverSettings?.localLoginEnabled ?? true;

  /// The transport and build configuration for this controller.
  AppConfig get config => _config;

  /// Returns `true` when [rawUrl] uses plain HTTP (not HTTPS) AND the transport
  /// policy permits insecure transport for that URL.
  ///
  /// Evaluated per-URL via [AppConfig.allowInsecureTransportFor], so the
  /// managed cloud origin (and any managed build) yields `false`: the UI then
  /// hides the "proceed anyway" warning and the submit path rejects the URL
  /// instead.
  bool isInsecureHttpUrl(String rawUrl) {
    final raw = rawUrl.trim();
    if (!_config.allowInsecureTransportFor(raw)) return false;
    final uri = Uri.tryParse(raw);
    return uri != null && uri.isScheme('http');
  }

  void startSsoCallbackListener({
    required VoidCallback onLoginSuccess,
    required ValueChanged<Object> onError,
  }) {
    _onLoginSuccess = onLoginSuccess;
    _onError = onError;
    _linkSubscription ??= _appLinksService.uriLinkStream.listen(
      _handleSsoCallbackUri,
      onError: _notifyError,
    );
  }

  Future<IdentityProvider?> submitServerUrl(String serverUrl) {
    return _guarded<IdentityProvider?>(() async {
      final url = serverUrl.trim();
      _serverUrl = url;
      final settings = await _authCoordinator.getServerSettings(url);

      List<IdentityProvider> providers = const [];
      if (settings.ssoEnabled) {
        try {
          providers = await _authCoordinator.getEnabledProviders(url);
        } catch (error) {
          // SSO discovery is best-effort: the server settings already loaded,
          // so fall back to local login. Record a sanitized breadcrumb so the
          // failure is observable in diagnostics.
          providers = const [];
          _diagnostics.recordBreadcrumbSync(
            DiagnosticsEvents.ssoProvidersFetchFailed,
            details: diagnosticErrorDetails(error),
          );
        }
      }

      _serverSettings = settings;
      _availableIdPs = providers;
      _isStep2 = true;
      _setLoading(false);

      if (settings.ssoEnabled &&
          settings.ssoAutoRedirect &&
          providers.length == 1) {
        return providers.first;
      }
      return null;
    });
  }

  Future<String?> beginSsoLogin(
    IdentityProvider provider, {
    required String serverUrl,
  }) {
    return _guarded<String?>(() async {
      _serverUrl = serverUrl.trim();
      // Refuse before the browser opens: a callback the server does not list
      // would end on the server's error page, out of the app's reach.
      if (!SsoService.isCallbackAllowed(_serverSettings?.allowedRedirectUris)) {
        _diagnostics.recordBreadcrumbSync(
          DiagnosticsEvents.ssoRedirectNotAllowed,
        );
        throw const AppException(AppErrorCode.ssoRedirectNotAllowed);
      }
      final oauthUrl = await _authCoordinator.initiateSsoLogin(
        provider,
        serverUrl: _serverUrl,
      );
      _diagnostics.recordBreadcrumbSync(DiagnosticsEvents.ssoLoginStarted);
      _setLoading(false);
      return oauthUrl;
    });
  }

  Future<void> submitLogin({
    required String serverUrl,
    required String username,
    required String password,
  }) {
    return _guarded(() async {
      _serverUrl = serverUrl.trim();
      final result = await _authCoordinator.login(
        username: username.trim(),
        password: password,
        serverUrl: _serverUrl,
      );

      await _applyResult(result);
    });
  }

  /// Answers the MFA step of a password or an SSO sign-in.
  Future<void> submitMfa(String mfaCode) {
    return _guarded(() async {
      final result = await _authCoordinator.verifyMfa(mfaCode.trim());
      await _applyResult(result);
    });
  }

  /// Answers the password-change step with [newPassword].
  Future<void> submitPasswordChange(String newPassword) {
    return _guarded(() async {
      final result = await _authCoordinator.changePassword(newPassword);
      await _applyResult(result);
    });
  }

  void backToServerStep() {
    _isStep2 = false;
    _availableIdPs = const [];
    _serverSettings = null;
    notify();
  }

  /// Leaves the MFA step, abandoning the sign-in.
  void backFromMfa() => _cancelPendingStep();

  /// Leaves the password-change step, abandoning the sign-in.
  void backFromPasswordChange() => _cancelPendingStep();

  void _cancelPendingStep() {
    _authCoordinator.cancelSignIn();
    _pendingStep = null;
    _mfaMethods = const [];
    notify();
  }

  /// The address of the icon an administrator uploaded for [provider], or
  /// `null` when it has none or the server address is unusable.
  Uri? uploadedIconUrl(IdentityProvider provider) {
    if (!provider.iconUploaded) {
      return null;
    }
    try {
      final origin = ServerUrlResolver.normalize(_serverUrl, config: _config);
      return Uri.parse(
        '$origin${ApiEndpoints(_config).idpIconEndpoint(provider.slug)}',
      );
    } on AppException {
      return null;
    }
  }

  void setPasswordVisible(bool visible) {
    _obscurePassword = !visible;
    notify();
  }

  void clearSsoPkce() {
    _authCoordinator.clearSsoPkce();
  }

  /// Abandons an SSO sign-in whose browser could not be opened.
  void ssoBrowserLaunchFailed() {
    _diagnostics.recordBreadcrumbSync(DiagnosticsEvents.ssoBrowserLaunchFailed);
    clearSsoPkce();
  }

  // Breadcrumbs below never carry the link's text: any app can fire it, and
  // the session id is a credential. Only documented error codes are kept.
  Future<void> _handleSsoCallbackUri(Uri uri) async {
    if (!SsoService.matchesCallback(uri)) {
      _diagnostics.recordBreadcrumbSync(DiagnosticsEvents.ssoCallbackIgnored);
      return;
    }

    final sessionId = uri.queryParameters['session_id'];
    final error =
        uri.queryParameters['error'] ?? uri.queryParameters['message'];

    if (error != null && error.isNotEmpty) {
      // Any app can fire this deep link, so never surface its text to the
      // user: only a documented failure code selects a specific message.
      final knownError = SsoService.knownCallbackErrors.contains(error)
          ? error
          : null;
      _diagnostics.recordBreadcrumbSync(
        DiagnosticsEvents.ssoCallbackError,
        details: {'code': knownError ?? 'unknown'},
      );
      clearSsoPkce();
      _setLoading(false);
      _notifyError(
        AppException(AppErrorCode.ssoCallbackFailed, details: knownError),
      );
      return;
    }

    if (sessionId == null || sessionId.isEmpty) {
      _diagnostics.recordBreadcrumbSync(
        DiagnosticsEvents.ssoCallbackMissingSession,
      );
      clearSsoPkce();
      _setLoading(false);
      _notifyError(const AppException(AppErrorCode.noSessionIdReceived));
      return;
    }

    _diagnostics.recordBreadcrumbSync(DiagnosticsEvents.ssoCallbackReceived);
    _setLoading(true);

    try {
      // `tokens`, or the MFA step for an account with MFA.
      final result = await _authCoordinator.exchangeSsoSessionForTokens(
        sessionId,
      );
      _diagnostics.recordBreadcrumbSync(
        DiagnosticsEvents.ssoExchangeSucceeded,
        details: {'step': result.step.name},
      );
      await _applyResult(result);
    } catch (error) {
      _diagnostics.recordBreadcrumbSync(
        DiagnosticsEvents.ssoExchangeFailed,
        details: diagnosticErrorDetails(error),
      );
      _resetIfSignInEnded(error);
      _setLoading(false);
      _notifyError(error);
    }
  }

  /// Moves the UI to the step [result] names, or finishes the sign-in.
  Future<void> _applyResult(AuthResult result) async {
    switch (result.step) {
      case SignInStep.signedIn:
        _pendingStep = null;
        _mfaMethods = const [];
        await _commitServerSettings();
        _onLoginSuccess?.call();
      case SignInStep.mfa:
        _pendingStep = SignInStep.mfa;
        _mfaMethods = result.mfaMethods;
        _setLoading(false);
      case SignInStep.passwordChange:
        _pendingStep = SignInStep.passwordChange;
        _setLoading(false);
    }
  }

  /// Returns to the credentials when [error] ended the pending sign-in (a
  /// dead challenge, an unknown step, a lost verifier), so the user starts
  /// over instead of retrying a step that no longer exists.
  void _resetIfSignInEnded(Object error) {
    if (error is AppException &&
        const {
          AppErrorCode.mfaSessionMissing,
          AppErrorCode.signInStepUnsupported,
          AppErrorCode.pkceVerifierMissingRestartLogin,
        }.contains(error.code)) {
      _pendingStep = null;
      _mfaMethods = const [];
    }
  }

  /// Runs [action] with the loading flag raised. On failure the flag is lowered
  /// and the error reported; on success [action] owns lowering the flag, since
  /// some flows stay busy (e.g. while navigating away after sign-in).
  Future<T?> _guarded<T>(Future<T> Function() action) async {
    _setLoading(true);
    try {
      return await action();
    } catch (error) {
      _resetIfSignInEnded(error);
      _setLoading(false);
      _notifyError(error);
      return null;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notify();
  }

  void _notifyError(Object error) {
    _onError?.call(error);
  }

  /// Saves the signed-in server's map settings. Best-effort: the session is
  /// already stored, so a preferences failure here must not turn a completed
  /// sign-in into an error. The settings are saved again at the next sign-in.
  Future<void> _commitServerSettings() async {
    final settings = _serverSettings;
    final origin = ServerUrlResolver.normalize(_serverUrl, config: _config);
    if (settings == null || origin.isEmpty) return;
    try {
      await _mapSettingsRepository?.saveFromServerSettings(
        settings,
        origin: origin,
      );
    } catch (error) {
      _diagnostics.recordBreadcrumbSync(
        DiagnosticsEvents.authServerSettingsSaveFailed,
        details: diagnosticErrorDetails(error),
      );
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }
}
