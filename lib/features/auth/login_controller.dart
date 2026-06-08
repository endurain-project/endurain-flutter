import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/models/identity_provider.dart';
import 'package:endurain/core/models/server_settings.dart';
import 'package:endurain/core/services/app_links_service.dart';
import 'package:endurain/features/auth/auth_coordinator.dart';
import 'package:endurain/features/map/map_settings_repository.dart';

class LoginController extends ChangeNotifier {
  LoginController({
    required AuthCoordinator authCoordinator,
    AppLinksService? appLinksService,
    MapSettingsRepository? mapSettingsRepository,
  }) : _authCoordinator = authCoordinator,
       _appLinksService = appLinksService ?? DefaultAppLinksService(),
       _mapSettingsRepository = mapSettingsRepository;

  final AuthCoordinator _authCoordinator;
  final AppLinksService _appLinksService;
  final MapSettingsRepository? _mapSettingsRepository;

  final formKey = GlobalKey<FormState>();
  final serverUrlController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final mfaCodeController = TextEditingController();

  StreamSubscription<Uri>? _linkSubscription;
  VoidCallback? _onLoginSuccess;
  ValueChanged<Object>? _onError;

  bool isLoading = false;
  bool obscurePassword = true;
  bool showMfaInput = false;
  bool isStep2 = false;
  String? _mfaUsername;
  List<IdentityProvider> availableIdPs = [];
  ServerSettings? serverSettings;

  bool get localLoginEnabled => serverSettings?.localLoginEnabled ?? true;

  /// Returns `true` when the current server URL uses plain HTTP (not HTTPS).
  ///
  /// Callers should show a localized warning and ask the user to confirm
  /// before calling [submitServerUrl].
  bool get serverUrlIsHttp {
    final raw = serverUrlController.text.trim();
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
      await _mapSettingsRepository?.saveFromServerSettings(settings);

      List<IdentityProvider> providers = [];
      if (settings.ssoEnabled) {
        try {
          providers = await _authCoordinator.getEnabledProviders(serverUrl);
        } catch (_) {
          providers = [];
        }
      }

      serverSettings = settings;
      availableIdPs = providers;
      isStep2 = true;
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
        showMfaInput = true;
        _mfaUsername = result.username;
        _setLoading(false);
      } else {
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
      _onLoginSuccess?.call();
    } catch (error) {
      _setLoading(false);
      _notifyError(error);
    }
  }

  void backToServerStep() {
    isStep2 = false;
    availableIdPs = [];
    serverSettings = null;
    notifyListeners();
  }

  void backFromMfa() {
    showMfaInput = false;
    mfaCodeController.clear();
    notifyListeners();
  }

  void setPasswordVisible(bool visible) {
    obscurePassword = !visible;
    notifyListeners();
  }

  void clearSsoPkce() {
    _authCoordinator.clearSsoPkce();
  }

  Future<void> _handleSsoCallbackUri(Uri uri) async {
    if (uri.scheme != 'endurain' ||
        uri.host != 'auth' ||
        uri.path != '/sso/callback') {
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
      _onLoginSuccess?.call();
    } catch (error) {
      _setLoading(false);
      _notifyError(error);
    }
  }

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  void _notifyError(Object error) {
    _onError?.call(error);
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
