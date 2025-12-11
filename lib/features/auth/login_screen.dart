import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:endurain/core/services/auth_service.dart';
import 'package:endurain/core/utils/platform_utils.dart';
import 'package:endurain/core/utils/validators.dart';
import 'package:endurain/core/utils/dialog_utils.dart';
import 'package:endurain/core/constants/ui_constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.onLoginSuccess});

  final VoidCallback? onLoginSuccess;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serverUrlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _mfaCodeController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _showMfaInput = false;
  String? _mfaUsername;

  @override
  void dispose() {
    _serverUrlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _mfaCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _authService.login(
        _usernameController.text.trim(),
        _passwordController.text,
        serverUrl: _serverUrlController.text.trim(),
      );

      if (mounted) {
        if (result.mfaRequired) {
          // Show MFA input
          setState(() {
            _showMfaInput = true;
            _mfaUsername = result.username;
            _isLoading = false;
          });
        } else {
          // Login successful, notify parent or navigate
          widget.onLoginSuccess?.call();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showError(e.toString());
      }
    }
  }

  Future<void> _handleMfaVerification() async {
    final l10n = AppLocalizations.of(context)!;
    if (_mfaCodeController.text.trim().isEmpty) {
      _showError(l10n.mfaCodeRequired);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.verifyMfa(
        _mfaUsername!,
        _mfaCodeController.text.trim(),
      );

      if (mounted) {
        widget.onLoginSuccess?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showError(e.toString());
      }
    }
  }

  void _showError(String message) {
    DialogUtils.showErrorDialog(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Cupertino style for iOS/macOS
    if (PlatformUtils.isApplePlatform) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(_showMfaInput ? l10n.mfaTitle : l10n.loginTitle),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CupertinoActivityIndicator())
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(UIConstants.paddingStandard),
                    children: [
                      const SizedBox(height: 40),
                      // App logo or title
                      Center(
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 120,
                          height: 120,
                        ),
                      ),
                      const SizedBox(height: 40),
                      if (!_showMfaInput) ...[
                        // Server URL field
                        CupertinoListSection.insetGrouped(
                          header: Text(l10n.serverUrl.toUpperCase()),
                          children: [
                            CupertinoTextFormFieldRow(
                              controller: _serverUrlController,
                              placeholder: l10n.serverUrlHint,
                              keyboardType: TextInputType.url,
                              textInputAction: TextInputAction.next,
                              validator: (value) =>
                                  Validators.validateUrl(value, l10n),
                            ),
                          ],
                        ),
                        // Username field
                        CupertinoListSection.insetGrouped(
                          header: Text(l10n.username.toUpperCase()),
                          children: [
                            CupertinoTextFormFieldRow(
                              controller: _usernameController,
                              placeholder: l10n.usernameHint,
                              textInputAction: TextInputAction.next,
                              validator: (value) => Validators.validateRequired(
                                value,
                                l10n,
                                l10n.username,
                              ),
                            ),
                          ],
                        ),
                        // Password field
                        CupertinoListSection.insetGrouped(
                          header: Text(l10n.password.toUpperCase()),
                          children: [
                            CupertinoTextFormFieldRow(
                              controller: _passwordController,
                              placeholder: l10n.passwordHint,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              validator: (value) => Validators.validateRequired(
                                value,
                                l10n,
                                l10n.password,
                              ),
                              onFieldSubmitted: (_) => _handleLogin(),
                            ),
                            CupertinoListTile(
                              title: Text(l10n.showPassword),
                              trailing: CupertinoSwitch(
                                value: !_obscurePassword,
                                onChanged: (value) {
                                  setState(() {
                                    _obscurePassword = !value;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: CupertinoButton.filled(
                            onPressed: _handleLogin,
                            child: Text(l10n.login),
                          ),
                        ),
                      ] else ...[
                        // MFA code field
                        CupertinoListSection.insetGrouped(
                          header: Text(l10n.mfaCode.toUpperCase()),
                          children: [
                            CupertinoTextFormFieldRow(
                              controller: _mfaCodeController,
                              placeholder: l10n.mfaCodeHint,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.done,
                              validator: (value) => Validators.validateRequired(
                                value,
                                l10n,
                                l10n.mfaCode,
                              ),
                              onFieldSubmitted: (_) => _handleMfaVerification(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: UIConstants.paddingStandard,
                          ),
                          child: CupertinoButton.filled(
                            onPressed: _handleMfaVerification,
                            child: Text(l10n.verify),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: CupertinoButton(
                            onPressed: () {
                              setState(() {
                                _showMfaInput = false;
                                _mfaCodeController.clear();
                              });
                            },
                            child: Text(l10n.back),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
        ),
      );
    }

    // Material style for Android
    return Scaffold(
      appBar: AppBar(
        title: Text(_showMfaInput ? l10n.mfaTitle : l10n.loginTitle),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(UIConstants.paddingStandard),
                children: [
                  const SizedBox(height: 40),
                  // App logo or title
                  Center(
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 120,
                      height: 120,
                    ),
                  ),
                  const SizedBox(height: 40),
                  if (!_showMfaInput) ...[
                    // Server URL field
                    TextFormField(
                      controller: _serverUrlController,
                      decoration: InputDecoration(
                        labelText: l10n.serverUrl,
                        hintText: l10n.serverUrlHint,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.dns),
                      ),
                      keyboardType: TextInputType.url,
                      textInputAction: TextInputAction.next,
                      validator: (value) => Validators.validateUrl(value, l10n),
                    ),
                    const SizedBox(height: 16),
                    // Username field
                    TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: l10n.username,
                        hintText: l10n.usernameHint,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.person),
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (value) => Validators.validateRequired(
                        value,
                        l10n,
                        l10n.username,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Password field
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: l10n.password,
                        hintText: l10n.passwordHint,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      validator: (value) => Validators.validateRequired(
                        value,
                        l10n,
                        l10n.password,
                      ),
                      onFieldSubmitted: (_) => _handleLogin(),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _handleLogin,
                      child: Padding(
                        padding: const EdgeInsets.all(
                          UIConstants.paddingMedium,
                        ),
                        child: Text(l10n.login),
                      ),
                    ),
                  ] else ...[
                    // MFA code field
                    TextFormField(
                      controller: _mfaCodeController,
                      decoration: InputDecoration(
                        labelText: l10n.mfaCode,
                        hintText: l10n.mfaCodeHint,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.security),
                      ),
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      validator: (value) => Validators.validateRequired(
                        value,
                        l10n,
                        l10n.mfaCode,
                      ),
                      onFieldSubmitted: (_) => _handleMfaVerification(),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _handleMfaVerification,
                      child: Padding(
                        padding: const EdgeInsets.all(
                          UIConstants.paddingMedium,
                        ),
                        child: Text(l10n.verify),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _showMfaInput = false;
                          _mfaCodeController.clear();
                        });
                      },
                      child: Text(l10n.back),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
