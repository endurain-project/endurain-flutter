import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:endurain/core/config/app_config.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:endurain/core/services/app_scope.dart';
import 'package:endurain/core/services/secure_storage_service.dart';
import 'package:endurain/core/services/auth_service.dart';
import 'package:endurain/core/utils/validators.dart';
import 'package:endurain/core/utils/dialog_utils.dart';
import 'package:endurain/core/constants/ui_constants.dart';
import 'package:endurain/features/map/repositories/map_settings_repository.dart';
import 'package:endurain/features/settings/repositories/server_settings_repository.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';

class ServerSettingsScreen extends StatefulWidget {
  const ServerSettingsScreen({
    super.key,
    this.onLogout,
    this.storage,
    this.authService,
    this.repository,
    this.config,
  });

  final VoidCallback? onLogout;
  final SecureStorageService? storage;
  final AuthService? authService;
  final ServerSettingsRepository? repository;
  final AppConfig? config;

  @override
  State<ServerSettingsScreen> createState() => _ServerSettingsScreenState();
}

class _ServerSettingsScreenState extends State<ServerSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tileServerUrlController = TextEditingController();
  late final ServerSettingsRepository _repository;
  late final AppConfig _config;
  bool _isLoading = true;
  String _serverUrl = '';
  String _username = '';

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? _createRepository();
    _config =
        widget.config ?? AppScope.servicesOf(context, listen: false).config;
    _loadSettings();
  }

  ServerSettingsRepository _createRepository() {
    final services = AppScope.servicesOf(context, listen: false);
    final storage = widget.storage ?? services.secureStorage;
    return ServerSettingsRepository(
      storage: storage,
      authService: widget.authService ?? services.auth,
      mapSettingsRepository: MapSettingsRepository(
        preferences: services.preferences,
        activeConnectionOrigin: services.authSession.getAuthenticatedOrigin,
      ),
    );
  }

  @override
  void dispose() {
    _tileServerUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final settings = await _repository.loadSettings();

    if (mounted) {
      final l10n = AppLocalizations.of(context)!;

      setState(() {
        _serverUrl = settings.serverUrl ?? l10n.notConfigured;
        _username = settings.username ?? l10n.notLoggedIn;
        _tileServerUrlController.text = settings.tileServerUrl;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final tileUrl = _tileServerUrlController.text.trim();

    if (!await _confirmTileHostIfNeeded(tileUrl, l10n)) {
      return;
    }

    try {
      await _repository.saveTileServerUrl(tileUrl);

      if (mounted) {
        await DialogUtils.showSuccessDialog(
          context,
          l10n.savedSuccessfully,
          onDismiss: () => Navigator.pop(context),
        );
      }
    } catch (e) {
      if (mounted) {
        await DialogUtils.showErrorDialog(context, e);
      }
    }
  }

  /// Returns true when saving may proceed. Shows a warning dialog and returns
  /// false if the tile server host differs from the Endurain server host and
  /// the user does not confirm. In managed mode with an allowlist, rejects
  /// out-of-policy hosts outright without offering a confirmation option.
  Future<bool> _confirmTileHostIfNeeded(
    String tileUrl,
    AppLocalizations l10n,
  ) async {
    final serverHost = Uri.tryParse(_serverUrl)?.host;
    final tileHost = Uri.tryParse(tileUrl)?.host;

    if (tileHost == null || tileHost.isEmpty) {
      return true;
    }

    // Managed policy: reject disallowed hosts without any confirmation.
    if (!_config.isTileServerHostAllowed(tileHost)) {
      if (mounted) {
        await DialogUtils.showErrorDialog(
          context,
          l10n.tileServerHostWarningTitle,
        );
      }
      return false;
    }

    if (serverHost == null || serverHost.isEmpty || serverHost == tileHost) {
      return true;
    }

    if (!mounted) {
      return false;
    }

    return DialogUtils.showConfirmDialog(
      context,
      title: l10n.tileServerHostWarningTitle,
      message: l10n.tileServerHostWarningMessage,
      confirmText: l10n.save,
    );
  }

  Future<void> _handleLogout() async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await DialogUtils.showConfirmDialog(
      context,
      title: l10n.logoutConfirmTitle,
      message: l10n.logoutConfirmMessage,
      confirmText: l10n.logout,
      isDestructive: true,
    );

    if (confirmed && mounted) {
      final serverLogoutSuccess = await _repository.logout();
      if (mounted) {
        if (!serverLogoutSuccess) {
          await DialogUtils.showMessage(
            context,
            l10n.logoutServerFailedWarning,
          );

          if (!mounted) {
            return;
          }
        }
        // Pop back to settings screen and trigger logout
        Navigator.pop(context);
        widget.onLogout?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AdaptiveScaffold(
      title: l10n.serverSettingsTitle,
      body: _isLoading
          ? const Center(child: AdaptiveLoadingIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(UIConstants.paddingStandard),
                children: [
                  AdaptiveListSection(
                    header: l10n.loggedIn,
                    children: [
                      AdaptiveListTile(
                        title: l10n.serverUrl,
                        subtitle: _serverUrl,
                      ),
                      AdaptiveListTile(
                        title: l10n.username,
                        subtitle: _username,
                      ),
                      AdaptiveListTile(
                        leading: AdaptiveIcon(
                          materialIcon: Icons.logout,
                          cupertinoIcon: CupertinoIcons.square_arrow_right,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        title: l10n.logout,
                        destructive: true,
                        onTap: _handleLogout,
                      ),
                    ],
                  ),
                  const SizedBox(height: UIConstants.paddingStandard),
                  AdaptiveTextFormField(
                    label: l10n.tileServerUrl,
                    placeholder: l10n.tileServerUrlHint,
                    controller: _tileServerUrlController,
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.done,
                    validator: (value) =>
                        Validators.validateUrl(value, l10n, config: _config),
                    onFieldSubmitted: (_) => _saveSettings(),
                  ),
                  const SizedBox(height: UIConstants.paddingLarge),
                  AdaptiveButton(
                    label: l10n.save,
                    onPressed: _saveSettings,
                    expand: true,
                  ),
                ],
              ),
            ),
    );
  }
}
