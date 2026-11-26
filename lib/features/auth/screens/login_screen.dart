import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:endurain/core/constants/ui_constants.dart';
import 'package:endurain/core/diagnostics/diagnostics_scope.dart';
import 'package:endurain/core/diagnostics/diagnostics_service.dart';
import 'package:endurain/core/models/identity_provider.dart';
import 'package:endurain/core/services/platform/url_launcher_service.dart';
import 'package:endurain/core/utils/dialog_utils.dart';
import 'package:endurain/core/utils/error_localizations.dart';
import 'package:endurain/core/utils/platform_utils.dart';
import 'package:endurain/core/utils/validators.dart';
import 'package:endurain/features/auth/controllers/login_controller.dart';
import 'package:endurain/features/auth/widgets/mfa_code_field.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:endurain/shared/layout/readable_content.dart';
import 'package:endurain/shared/state/owned_controllers.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.onLoginSuccess,
    this.onCancel,
    required this.urlLauncherService,
    this.controller,
    this.createController,
  }) : assert(
         controller != null || createController != null,
         'Pass a controller or a factory for one.',
       );

  final VoidCallback? onLoginSuccess;

  /// Invoked to dismiss the login screen and return to the app. Provided only
  /// when there is somewhere to return to (i.e. an existing guest session).
  final VoidCallback? onCancel;

  final UrlLauncherService urlLauncherService;

  /// Injected controller (tests); otherwise one is built with
  /// [createController] and owned by the screen.
  final LoginController? controller;
  final LoginController Function()? createController;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with OwnedControllers {
  late final LoginController _controller;
  final _formKey = GlobalKey<FormState>();
  final _serverHostController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _mfaCodeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _serverScheme = 'https';
  MfaCodeKind _mfaCodeKind = MfaCodeKind.totp;

  /// Why the last MFA code failed, shown under the code boxes.
  String? _mfaError;

  @override
  void initState() {
    super.initState();
    _controller = registerController(
      widget.controller,
      () => widget.createController!(),
      onChanged: _handleControllerChanged,
    );
    _mfaCodeController.addListener(_clearMfaErrorOnInput);
    _controller.startSsoCallbackListener(
      onLoginSuccess: () => widget.onLoginSuccess?.call(),
      onError: _showError,
    );
  }

  String _serverUrlFor(String host) => '$_serverScheme://${host.trim()}';

  void _handleControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  /// Step 1: Validate server URL, fetch server settings and available IdPs
  Future<void> _handleServerUrlNext() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final serverUrl = _serverUrlFor(_serverHostController.text);
    if (_controller.isInsecureHttpUrl(serverUrl) && mounted) {
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

    final autoRedirectProvider = await _controller.submitServerUrl(serverUrl);
    if (autoRedirectProvider != null) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        await _handleSsoLogin(autoRedirectProvider);
      }
    }
  }

  /// Handle SSO provider selection
  Future<void> _handleSsoLogin(IdentityProvider idp) async {
    final oauthUrl = await _controller.beginSsoLogin(
      idp,
      serverUrl: _serverUrlFor(_serverHostController.text),
    );
    if (oauthUrl == null || !mounted) {
      return;
    }

    final launched = await widget.urlLauncherService.launchExternalApplication(
      Uri.parse(oauthUrl),
    );

    if (!launched && mounted) {
      final l10n = AppLocalizations.of(context)!;
      _controller.ssoBrowserLaunchFailed();
      await _showError(l10n.ssoBrowserLaunchFailed);
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    await _controller.submitLogin(
      serverUrl: _serverUrlFor(_serverHostController.text),
      username: _usernameController.text,
      password: _passwordController.text,
    );
  }

  /// Sends the MFA code: by the Verify button, the keyboard, or on its own
  /// once the last box is filled. The boxes are emptied afterwards, so a
  /// rejected code leaves them ready for the next try under its reason.
  Future<void> _handleMfaVerification() async {
    if (_controller.isLoading) {
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final code = _mfaCodeKind.normalize(_mfaCodeController.text);
    if (code.length != _mfaCodeKind.length) {
      await _showError(l10n.mfaCodeRequired);
      return;
    }

    setState(() => _mfaError = null);
    await _controller.submitMfa(_mfaCodeKind.toSubmission(code));
    if (mounted) {
      _mfaCodeController.clear();
    }
  }

  void _clearMfaErrorOnInput() {
    if (_mfaError != null && _mfaCodeController.text.isNotEmpty) {
      setState(() => _mfaError = null);
    }
  }

  void _toggleMfaCodeKind() {
    setState(() {
      _mfaError = null;
      _mfaCodeController.clear();
      _mfaCodeKind = _mfaCodeKind == MfaCodeKind.totp
          ? MfaCodeKind.backupCode
          : MfaCodeKind.totp;
    });
  }

  Future<void> _handlePasswordChange() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    await _controller.submitPasswordChange(_newPasswordController.text);
  }

  /// Reports [message]. While the MFA step stays open (a wrong or
  /// incomplete code) it shows under the code boxes; otherwise, including
  /// when the error ended the sign-in, in a dialog.
  Future<void> _showError(Object message) async {
    if (!mounted) {
      return;
    }
    if (_controller.showMfaInput) {
      if (message is! String) {
        DiagnosticsScope.of(context).recordBreadcrumbSync(
          DiagnosticsEvents.uiErrorShown,
          details: diagnosticErrorDetails(message),
        );
      }
      final l10n = AppLocalizations.of(context)!;
      setState(() => _mfaError = localizedErrorMessage(message, l10n));
      return;
    }
    await DialogUtils.showErrorDialog(context, message);
  }

  void _goBackToServerStep() {
    _controller.backToServerStep();
  }

  void _goBackFromMfa() {
    _mfaCodeController.clear();
    _mfaCodeKind = MfaCodeKind.totp;
    _mfaError = null;
    _controller.backFromMfa();
  }

  void _goBackFromPasswordChange() {
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    _controller.backFromPasswordChange();
  }

  /// Leading app-bar control for the current step:
  /// - back to the server step from the login/SSO step,
  /// - dismiss to the app from the first step when a guest session can return.
  Widget? _buildLeading() {
    if (_controller.showMfaInput || _controller.showPasswordChange) {
      return null;
    }
    if (_controller.isStep2) {
      return AdaptiveBackButton(onPressed: _goBackToServerStep);
    }
    if (widget.onCancel != null) {
      return AdaptiveBackButton(onPressed: widget.onCancel!);
    }
    return null;
  }

  /// Build SSO provider icon widget
  /// Checks for local asset first, then tries URL, with fallback icon
  Widget _buildSsoIcon(IdentityProvider idp) {
    if (idp.icon == null || idp.icon!.isEmpty) {
      return _buildUploadedOrDefaultIcon(idp);
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
      // These SVGs are bundled assets declared in pubspec.yaml and the
      // [localAssets] allowlist guarantees the file exists, so no synchronous
      // failure path applies here.
      return SvgPicture.asset(
        assetPath,
        width: 24,
        height: 24,
        fit: BoxFit.contain,
      );
    }

    return _buildUploadedOrDefaultIcon(idp);
  }

  /// The icon an administrator uploaded for [idp], or the default person icon.
  /// Endurain v0.21 serves an uploaded icon from its own public route; the
  /// `icon` field holds only a built-in key.
  Widget _buildUploadedOrDefaultIcon(IdentityProvider idp) {
    const fallback = AdaptiveIcon(
      materialIcon: Icons.person_outline,
      cupertinoIcon: CupertinoIcons.person_circle,
      size: 24,
    );
    final url = _controller.uploadedIconUrl(idp);
    if (url == null) {
      return fallback;
    }
    return Image.network(
      url.toString(),
      width: 24,
      height: 24,
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }

  @override
  void dispose() {
    _serverHostController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _mfaCodeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AdaptiveScaffold(
      title: _controller.showMfaInput
          ? l10n.mfaTitle
          : _controller.showPasswordChange
          ? l10n.passwordChangeTitle
          : l10n.loginTitle,
      leading: _buildLeading(),
      body: _controller.isLoading
          ? const Center(child: AdaptiveLoadingIndicator())
          : Form(
              key: _formKey,
              child: AutofillGroup(
                child: ListView(
                  padding: readableContentPadding(context),
                  children: [
                    const SizedBox(height: 40),
                    Center(
                      child: Image.asset(
                        MediaQuery.platformBrightnessOf(context) ==
                                Brightness.dark
                            ? 'assets/logo/brand_logo_dark_theme.png'
                            : 'assets/logo/brand_logo_light_theme.png',
                        width: 120,
                        height: 120,
                      ),
                    ),
                    const SizedBox(height: 40),
                    if (_controller.showMfaInput)
                      ..._buildMfaFields(l10n)
                    else if (_controller.showPasswordChange)
                      ..._buildPasswordChangeFields(l10n)
                    else if (_controller.isStep2)
                      ..._buildLoginFields(l10n)
                    else
                      ..._buildServerUrlFields(l10n),
                  ],
                ),
              ),
            ),
    );
  }

  List<Widget> _buildServerUrlFields(AppLocalizations l10n) {
    return [
      _ServerProtocolSelector(
        label: l10n.serverProtocol,
        value: _serverScheme,
        onChanged: (value) {
          setState(() {
            _serverScheme = value;
          });
        },
      ),
      const SizedBox(height: UIConstants.paddingStandard),
      AdaptiveTextFormField(
        label: l10n.serverUrl,
        placeholder: l10n.serverUrlHint,
        controller: _serverHostController,
        keyboardType: TextInputType.url,
        textInputAction: TextInputAction.done,
        prefixIcon: const AdaptiveIcon(
          materialIcon: Icons.dns,
          cupertinoIcon: CupertinoIcons.globe,
        ),
        validator: (value) {
          final host = value?.trim() ?? '';
          if (host.isEmpty) {
            return l10n.requiredField;
          }
          if (host.contains(RegExp(r'\s')) || host.contains('://')) {
            return l10n.invalidUrl;
          }
          return Validators.validateUrl(
            _serverUrlFor(host),
            l10n,
            config: _controller.config,
          );
        },
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
          controller: _usernameController,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.username],
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
          controller: _passwordController,
          obscureText: _controller.obscurePassword,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          autocorrect: false,
          enableSuggestions: false,
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

  List<Widget> _buildPasswordChangeFields(AppLocalizations l10n) {
    return [
      Text(l10n.passwordChangeMessage),
      const SizedBox(height: UIConstants.paddingStandard),
      AdaptiveTextFormField(
        label: l10n.newPassword,
        controller: _newPasswordController,
        obscureText: _controller.obscurePassword,
        textInputAction: TextInputAction.next,
        autofillHints: const [AutofillHints.newPassword],
        autocorrect: false,
        enableSuggestions: false,
        prefixIcon: const AdaptiveIcon(
          materialIcon: Icons.lock,
          cupertinoIcon: CupertinoIcons.lock,
        ),
        validator: (value) =>
            Validators.validateRequired(value, l10n, l10n.newPassword),
      ),
      const SizedBox(height: UIConstants.paddingStandard),
      AdaptiveTextFormField(
        label: l10n.confirmNewPassword,
        controller: _confirmPasswordController,
        obscureText: _controller.obscurePassword,
        textInputAction: TextInputAction.done,
        autofillHints: const [AutofillHints.newPassword],
        autocorrect: false,
        enableSuggestions: false,
        prefixIcon: const AdaptiveIcon(
          materialIcon: Icons.lock,
          cupertinoIcon: CupertinoIcons.lock,
        ),
        validator: (value) => value == _newPasswordController.text
            ? null
            : l10n.passwordsDoNotMatch,
        onFieldSubmitted: (_) => _handlePasswordChange(),
      ),
      AdaptiveSwitchListTile(
        title: l10n.showPassword,
        value: !_controller.obscurePassword,
        onChanged: _controller.setPasswordVisible,
      ),
      const SizedBox(height: UIConstants.paddingLarge),
      AdaptiveButton(
        label: l10n.changePassword,
        onPressed: _handlePasswordChange,
        expand: true,
      ),
      const SizedBox(height: UIConstants.paddingStandard),
      AdaptiveButton(
        label: l10n.back,
        onPressed: _goBackFromPasswordChange,
        variant: AdaptiveButtonVariant.secondary,
        expand: true,
      ),
    ];
  }

  List<Widget> _buildMfaFields(AppLocalizations l10n) {
    final usingBackupCode = _mfaCodeKind == MfaCodeKind.backupCode;
    return [
      MfaCodeField(
        // A new field per kind, so the keyboard switches with it.
        key: ValueKey(_mfaCodeKind),
        controller: _mfaCodeController,
        kind: _mfaCodeKind,
        label: usingBackupCode ? l10n.mfaBackupCode : l10n.mfaCode,
        instruction: usingBackupCode
            ? l10n.mfaBackupCodeHint
            : l10n.mfaCodeHint,
        errorText: _mfaError,
        autofocus: true,
        onCompleted: _handleMfaVerification,
        onSubmitted: _handleMfaVerification,
      ),
      if (_controller.mfaAcceptsBackupCodes || usingBackupCode) ...[
        const SizedBox(height: UIConstants.paddingCompact),
        Center(
          child: AdaptiveButton(
            label: usingBackupCode
                ? l10n.mfaUseAuthenticatorCode
                : l10n.mfaUseBackupCode,
            onPressed: _toggleMfaCodeKind,
            variant: AdaptiveButtonVariant.secondary,
          ),
        ),
      ],
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

class _ServerProtocolSelector extends StatelessWidget {
  const _ServerProtocolSelector({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isApplePlatform) {
      return CupertinoFormRow(
        prefix: Text(label),
        child: CupertinoSlidingSegmentedControl<String>(
          groupValue: value,
          children: const {'https': Text('HTTPS'), 'http': Text('HTTP')},
          onValueChanged: (selected) {
            if (selected != null) {
              onChanged(selected);
            }
          },
        ),
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 'https', child: Text('HTTPS')),
        DropdownMenuItem(value: 'http', child: Text('HTTP')),
      ],
      onChanged: (selected) {
        if (selected != null) {
          onChanged(selected);
        }
      },
    );
  }
}
