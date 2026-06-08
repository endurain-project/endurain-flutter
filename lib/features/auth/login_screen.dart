import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:endurain/core/services/app_scope.dart';
import 'package:endurain/core/services/app_links_service.dart';
import 'package:endurain/core/services/auth_service.dart';
import 'package:endurain/core/services/sso_service.dart';
import 'package:endurain/core/services/server_settings_service.dart';
import 'package:endurain/core/services/url_launcher_service.dart';
import 'package:endurain/core/models/identity_provider.dart';
import 'package:endurain/core/utils/validators.dart';
import 'package:endurain/core/utils/dialog_utils.dart';
import 'package:endurain/core/constants/ui_constants.dart';
import 'package:endurain/features/auth/auth_coordinator.dart';
import 'package:endurain/features/auth/login_controller.dart';
import 'package:endurain/features/map/map_settings_repository.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:endurain/shared/state/owned_controllers.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.onLoginSuccess,
    this.authService,
    this.ssoService,
    this.serverSettingsService,
    this.appLinksService,
    this.urlLauncherService,
    this.controller,
  });

  final VoidCallback? onLoginSuccess;
  final AuthService? authService;
  final SsoService? ssoService;
  final ServerSettingsService? serverSettingsService;
  final AppLinksService? appLinksService;
  final UrlLauncherService? urlLauncherService;
  final LoginController? controller;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with OwnedControllers {
  late final LoginController _controller;
  late final UrlLauncherService _urlLauncherService;

  @override
  void initState() {
    super.initState();
    _urlLauncherService =
        widget.urlLauncherService ??
        AppScope.servicesOf(context, listen: false).urlLauncher;
    _controller = registerController(
      widget.controller,
      _createController,
      onChanged: _handleControllerChanged,
    );
    _controller.startSsoCallbackListener(
      onLoginSuccess: () => widget.onLoginSuccess?.call(),
      onError: _showError,
    );
  }

  LoginController _createController() {
    final services = AppScope.servicesOf(context, listen: false);
    return LoginController(
      authCoordinator: AuthCoordinator(
        authService: widget.authService ?? services.auth,
        ssoService: widget.ssoService ?? services.sso,
        serverSettingsService:
            widget.serverSettingsService ?? services.serverSettings,
      ),
      appLinksService: widget.appLinksService ?? services.appLinks,
      mapSettingsRepository: MapSettingsRepository(
        preferences: services.preferences,
      ),
    );
  }

  void _handleControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  /// Step 1: Validate server URL, fetch server settings and available IdPs
  Future<void> _handleServerUrlNext() async {
    if (!_controller.formKey.currentState!.validate()) {
      return;
    }

    if (_controller.serverUrlIsHttp && mounted) {
      final l10n = AppLocalizations.of(context)!;
      final confirmed = await DialogUtils.showConfirmDialog(
        context,
        title: l10n.warnHttpServerUrlTitle,
        message: l10n.warnHttpServerUrlMessage,
        confirmText: l10n.warnHttpServerUrlConfirm,
        isDestructive: true,
      );
      if (!confirmed || !mounted) {
        return;
      }
    }

    final autoRedirectProvider = await _controller.submitServerUrl();
    if (autoRedirectProvider != null) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        await _handleSsoLogin(autoRedirectProvider);
      }
    }
  }

  /// Handle SSO provider selection
  Future<void> _handleSsoLogin(IdentityProvider idp) async {
    final oauthUrl = await _controller.beginSsoLogin(idp);
    if (oauthUrl == null || !mounted) {
      return;
    }

    final launched = await _urlLauncherService.launchExternalApplication(
      Uri.parse(oauthUrl),
    );

    if (!launched && mounted) {
      final l10n = AppLocalizations.of(context)!;
      _controller.clearSsoPkce();
      _showError(l10n.ssoBrowserLaunchFailed);
    }
  }

  Future<void> _handleLogin() async {
    if (!_controller.formKey.currentState!.validate()) {
      return;
    }

    await _controller.submitLogin();
  }

  Future<void> _handleMfaVerification() async {
    final l10n = AppLocalizations.of(context)!;
    if (_controller.mfaCodeController.text.trim().isEmpty) {
      _showError(l10n.mfaCodeRequired);
      return;
    }

    await _controller.submitMfa();
  }

  void _showError(Object message) {
    if (mounted) {
      DialogUtils.showErrorDialog(context, message);
    }
  }

  void _goBackToServerStep() {
    _controller.backToServerStep();
  }

  void _goBackFromMfa() {
    _controller.backFromMfa();
  }

  /// Build SSO provider icon widget
  /// Checks for local asset first, then tries URL, with fallback icon
  Widget _buildSsoIcon(IdentityProvider idp) {
    if (idp.icon == null || idp.icon!.isEmpty) {
      return const AdaptiveIcon(
        materialIcon: Icons.person_outline,
        cupertinoIcon: CupertinoIcons.person_circle,
        size: 24,
      );
    }

    // List of available local assets
    const localAssets = [
      'authelia',
      'authentik',
      'casdoor',
      'keycloak',
      'pocketid',
    ];

    // Check if icon matches a local asset (case-insensitive)
    final iconLower = idp.icon!.toLowerCase();

    if (localAssets.contains(iconLower)) {
      final assetPath = 'assets/sso/$iconLower.svg';
      try {
        return SvgPicture.asset(
          assetPath,
          width: 24,
          height: 24,
          fit: BoxFit.contain,
        );
      } catch (e) {
        return const AdaptiveIcon(
          materialIcon: Icons.person_outline,
          cupertinoIcon: CupertinoIcons.person_circle,
          size: 24,
        );
      }
    }

    // Try to load from URL
    return Image.network(
      idp.icon!,
      width: 24,
      height: 24,
      errorBuilder: (context, error, stackTrace) => const AdaptiveIcon(
        materialIcon: Icons.person_outline,
        cupertinoIcon: CupertinoIcons.person_circle,
        size: 24,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AdaptiveScaffold(
      title: _controller.showMfaInput ? l10n.mfaTitle : l10n.loginTitle,
      leading: _controller.isStep2 && !_controller.showMfaInput
          ? AdaptiveBackButton(onPressed: _goBackToServerStep)
          : null,
      body: _controller.isLoading
          ? const Center(child: AdaptiveLoadingIndicator())
          : Form(
              key: _controller.formKey,
              child: ListView(
                padding: const EdgeInsets.all(UIConstants.paddingStandard),
                children: [
                  const SizedBox(height: 40),
                  Center(
                    child: Image.asset(
                      'assets/logo/logo.png',
                      width: 120,
                      height: 120,
                    ),
                  ),
                  const SizedBox(height: 40),
                  if (_controller.showMfaInput)
                    ..._buildMfaFields(l10n)
                  else if (_controller.isStep2)
                    ..._buildLoginFields(l10n)
                  else
                    ..._buildServerUrlFields(l10n),
                ],
              ),
            ),
    );
  }

  List<Widget> _buildServerUrlFields(AppLocalizations l10n) {
    return [
      AdaptiveTextFormField(
        label: l10n.serverUrl,
        placeholder: l10n.serverUrlHint,
        controller: _controller.serverUrlController,
        keyboardType: TextInputType.url,
        textInputAction: TextInputAction.done,
        prefixIcon: const AdaptiveIcon(
          materialIcon: Icons.dns,
          cupertinoIcon: CupertinoIcons.globe,
        ),
        validator: (value) => Validators.validateUrl(value, l10n),
        onFieldSubmitted: (_) => _handleServerUrlNext(),
      ),
      const SizedBox(height: UIConstants.paddingLarge),
      AdaptiveButton(
        label: l10n.next,
        onPressed: _handleServerUrlNext,
        expand: true,
      ),
    ];
  }

  List<Widget> _buildLoginFields(AppLocalizations l10n) {
    return [
      if (_controller.localLoginEnabled) ...[
        AdaptiveTextFormField(
          label: l10n.username,
          placeholder: l10n.usernameHint,
          controller: _controller.usernameController,
          textInputAction: TextInputAction.next,
          prefixIcon: const AdaptiveIcon(
            materialIcon: Icons.person,
            cupertinoIcon: CupertinoIcons.person,
          ),
          validator: (value) =>
              Validators.validateRequired(value, l10n, l10n.username),
        ),
        const SizedBox(height: UIConstants.paddingStandard),
        AdaptiveTextFormField(
          label: l10n.password,
          placeholder: l10n.passwordHint,
          controller: _controller.passwordController,
          obscureText: _controller.obscurePassword,
          textInputAction: TextInputAction.done,
          prefixIcon: const AdaptiveIcon(
            materialIcon: Icons.lock,
            cupertinoIcon: CupertinoIcons.lock,
          ),
          validator: (value) =>
              Validators.validateRequired(value, l10n, l10n.password),
          onFieldSubmitted: (_) => _handleLogin(),
        ),
        AdaptiveSwitchListTile(
          title: l10n.showPassword,
          value: !_controller.obscurePassword,
          onChanged: _controller.setPasswordVisible,
        ),
        const SizedBox(height: UIConstants.paddingLarge),
        AdaptiveButton(
          label: l10n.login,
          onPressed: _handleLogin,
          expand: true,
        ),
      ],
      if (_controller.availableIdPs.isNotEmpty) ...[
        if (_controller.localLoginEnabled) ...[
          const SizedBox(height: UIConstants.paddingLarge),
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: UIConstants.paddingStandard,
                ),
                child: Text(l10n.ssoOrDivider),
              ),
              const Expanded(child: Divider()),
            ],
          ),
        ],
        const SizedBox(height: UIConstants.paddingStandard),
        for (final idp in _controller.availableIdPs) ...[
          AdaptiveButton(
            label: l10n.ssoSignInWith(idp.name),
            icon: _buildSsoIcon(idp),
            onPressed: () => _handleSsoLogin(idp),
            expand: true,
          ),
          const SizedBox(height: UIConstants.paddingMedium),
        ],
      ],
    ];
  }

  List<Widget> _buildMfaFields(AppLocalizations l10n) {
    return [
      AdaptiveTextFormField(
        label: l10n.mfaCode,
        placeholder: l10n.mfaCodeHint,
        controller: _controller.mfaCodeController,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        prefixIcon: const AdaptiveIcon(
          materialIcon: Icons.security,
          cupertinoIcon: CupertinoIcons.shield,
        ),
        validator: (value) =>
            Validators.validateRequired(value, l10n, l10n.mfaCode),
        onFieldSubmitted: (_) => _handleMfaVerification(),
      ),
      const SizedBox(height: UIConstants.paddingLarge),
      AdaptiveButton(
        label: l10n.verify,
        onPressed: _handleMfaVerification,
        expand: true,
      ),
      const SizedBox(height: UIConstants.paddingStandard),
      AdaptiveButton(
        label: l10n.back,
        onPressed: _goBackFromMfa,
        variant: AdaptiveButtonVariant.secondary,
        expand: true,
      ),
    ];
  }
}
