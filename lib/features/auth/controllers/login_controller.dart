import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:endurain/core/config/app_config.dart';
import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/models/identity_provider.dart';
import 'package:endurain/core/models/server_settings.dart';
import 'package:endurain/core/services/platform/app_links_service.dart';
import 'package:endurain/core/services/diagnostics_service.dart';
import 'package:endurain/core/services/sso_service.dart';
import 'package:endurain/core/utils/server_url_resolver.dart';
import 'package:endurain/features/auth/services/auth_coordinator.dart';
import 'package:endurain/features/map/repositories/map_settings_repository.dart';

class LoginController extends ChangeNotifier {
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

  final formKey = GlobalKey<FormState>();
  final serverUrlController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final mfaCodeController = TextEditingController();

  StreamSubscription<Uri>? _linkSubscription;
  VoidCallback? _onLoginSuccess;
  ValueChanged<Object>? _onError;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _showMfaInput = false;
  bool _isStep2 = false;
  String? _mfaUsername;
  List<IdentityProvider> _availableIdPs = const [];
  ServerSettings? _serverSettings;

  bool get isLoading => _isLoading;
  bool get obscurePassword => _obscurePassword;
  bool get showMfaInput => _showMfaInput;
  bool get isStep2 => _isStep2;
  List<IdentityProvider> get availableIdPs => List.unmodifiable(_availableIdPs);
  ServerSettings? get serverSettings => _serverSettings;

  bool get localLoginEnabled => _serverSettings?.localLoginEnabled ?? true;

  /// The transport and build configuration for this controller.
  AppConfig get config => _config;

  /// Returns `true` when the current server URL uses plain HTTP (not HTTPS)
  /// AND the transport policy permits insecure transport for that URL.
  ///
  /// Evaluated per-URL via [AppConfig.allowInsecureTransportFor], so the
  /// managed cloud origin (and any managed build) yields `false`: the UI then
  /// hides the "proceed anyway" warning and the submit path rejects the URL
  /// instead.
  bool get serverUrlIsHttp {
    final raw = serverUrlController.text.trim();
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

  Future<IdentityProvider?> submitServerUrl() async {
    _setLoading(true);

    try {
      final serverUrl = serverUrlController.text.trim();
      final settings = await _authCoordinator.getServerSettings(serverUrl);

      List<IdentityProvider> providers = const [];
      if (settings.ssoEnabled) {
        try {
          providers = await _authCoordinator.getEnabledProviders(serverUrl);
        } catch (error) {
          // SSO discovery is best-effort: the server settings already loaded,
          // so fall back to local login. Record a sanitized breadcrumb so the
          // failure is observable in diagnostics.
          providers = const [];
          _diagnostics.recordBreadcrumbSync(
            DiagnosticsEvents.ssoProvidersFetchFailed,
            details: {'error': error.runtimeType.toString()},
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
    } catch (error) {
      _setLoading(false);
      _notifyError(error);
      return null;
    }
  }

  Future<String?> beginSsoLogin(IdentityProvider provider) async {
    _setLoading(true);

    try {
      final oauthUrl = await _authCoordinator.initiateSsoLogin(
        provider,
        serverUrl: serverUrlController.text.trim(),
      );
      _setLoading(false);
      return oauthUrl;
    } catch (error) {
      _setLoading(false);
      _notifyError(error);
      return null;
    }
  }

  Future<void> submitLogin() async {
    _setLoading(true);

    try {
      final result = await _authCoordinator.login(
        username: usernameController.text.trim(),
        password: passwordController.text,
        serverUrl: serverUrlController.text.trim(),
      );

      if (result.mfaRequired) {
        _showMfaInput = true;
        _mfaUsername = result.username;
        _setLoading(false);
      } else {
        await _commitServerSettings();
        _onLoginSuccess?.call();
      }
    } catch (error) {
      _setLoading(false);
      _notifyError(error);
    }
  }

  Future<void> submitMfa() async {
    final username = _mfaUsername;
    if (username == null || username.isEmpty) {
      _notifyError(const AppException(AppErrorCode.noSessionIdReceived));
      return;
    }

    _setLoading(true);

    try {
      await _authCoordinator.verifyMfa(
        username: username,
        mfaCode: mfaCodeController.text.trim(),
      );
      await _commitServerSettings();
      _onLoginSuccess?.call();
    } catch (error) {
      _setLoading(false);
      _notifyError(error);
    }
  }

  void backToServerStep() {
    _isStep2 = false;
    _availableIdPs = const [];
    _serverSettings = null;
    notifyListeners();
  }

  void backFromMfa() {
    _showMfaInput = false;
    mfaCodeController.clear();
    notifyListeners();
  }

  void setPasswordVisible(bool visible) {
    _obscurePassword = !visible;
    notifyListeners();
  }

  void clearSsoPkce() {
    _authCoordinator.clearSsoPkce();
  }

  Future<void> _handleSsoCallbackUri(Uri uri) async {
    if (!SsoService.matchesCallback(uri)) {
      return;
    }

    final sessionId = uri.queryParameters['session_id'];
    final error =
        uri.queryParameters['message'] ?? uri.queryParameters['error'];

    if (error != null && error.isNotEmpty) {
      clearSsoPkce();
      _setLoading(false);
      _notifyError(error);
      return;
    }

    if (sessionId == null || sessionId.isEmpty) {
      clearSsoPkce();
      _setLoading(false);
      _notifyError(const AppException(AppErrorCode.noSessionIdReceived));
      return;
    }

    _setLoading(true);

    try {
      await _authCoordinator.exchangeSsoSessionForTokens(sessionId);
      await _commitServerSettings();
      _onLoginSuccess?.call();
    } catch (error) {
      _setLoading(false);
      _notifyError(error);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _notifyError(Object error) {
    _onError?.call(error);
  }

  Future<void> _commitServerSettings() async {
    final settings = _serverSettings;
    final origin = ServerUrlResolver.normalize(
      serverUrlController.text,
      config: _config,
    );
    if (settings == null || origin.isEmpty) return;
    await _mapSettingsRepository?.saveFromServerSettings(
      settings,
      origin: origin,
    );
  }

  @override
  void dispose() {
    serverUrlController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    mfaCodeController.dispose();
    _linkSubscription?.cancel();
    super.dispose();
  }
}
