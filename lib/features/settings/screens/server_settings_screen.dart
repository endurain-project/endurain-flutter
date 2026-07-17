import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:endurain/core/config/app_config.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:endurain/core/services/app_scope.dart';
import 'package:endurain/core/services/app_services.dart';
import 'package:endurain/core/services/secure_storage_service.dart';
import 'package:endurain/core/services/auth_service.dart';
import 'package:endurain/core/utils/validators.dart';
import 'package:endurain/core/utils/dialog_utils.dart';
import 'package:endurain/core/constants/ui_constants.dart';
import 'package:endurain/features/map/repositories/map_settings_repository.dart';
import 'package:endurain/features/settings/controllers/server_settings_controller.dart';
import 'package:endurain/features/settings/repositories/server_settings_repository.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:endurain/shared/state/owned_controllers.dart';

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

class _ServerSettingsScreenState extends State<ServerSettingsScreen>
    with OwnedControllers {
  final _formKey = GlobalKey<FormState>();
  final _tileServerUrlController = TextEditingController();
  late final ServerSettingsController _controller;
  late final AppConfig _config;

  @override
  void initState() {
    super.initState();
    final services = AppScope.servicesOf(context, listen: false);
    _config = widget.config ?? services.config;
    // The screen always owns the controller; its test seam is the repository
    // (built here) rather than the controller itself.
    _controller = registerController(
      null,
      () => ServerSettingsController(
        repository: widget.repository ?? _createRepository(services),
        config: _config,
      ),
    );
    _initialize();
  }

  ServerSettingsRepository _createRepository(AppServices services) {
    final storage = widget.storage ?? services.secureStorage;
    return ServerSettingsRepository(
      storage: storage,
      authService: widget.authService ?? services.auth,
      mapSettingsRepository: MapSettingsRepository(
        preferences: services.preferences,
        config: services.config,
        activeConnectionOrigin: services.authSession.getAuthenticatedOrigin,
      ),
    );
  }

  @override
  void dispose() {
    _tileServerUrlController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    await _controller.load();
    if (mounted) {
      _tileServerUrlController.text = _controller.tileServerUrl;
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
      await _controller.saveTileServerUrl(tileUrl);

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

  /// Applies the controller's tile-host policy and shows the matching UI.
  /// Returns true when saving may proceed.
  Future<bool> _confirmTileHostIfNeeded(
    String tileUrl,
    AppLocalizations l10n,
  ) async {
    switch (_controller.evaluateTileHost(tileUrl)) {
      case TileServerHostDecision.allowed:
        return true;
      case TileServerHostDecision.blocked:
        // Managed policy: reject disallowed hosts without any confirmation.
        if (mounted) {
          await DialogUtils.showErrorDialog(
            context,
            l10n.tileServerHostWarningTitle,
          );
        }
        return false;
      case TileServerHostDecision.needsConfirmation:
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
      final serverLogoutSuccess = await _controller.logout();
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
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.isLoading) {
            return const Center(child: AdaptiveLoadingIndicator());
          }
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(UIConstants.paddingStandard),
              children: [
                AdaptiveListSection(
                  header: l10n.loggedIn,
                  children: [
                    AdaptiveListTile(
                      title: l10n.serverUrl,
                      subtitle: _controller.serverUrl ?? l10n.notConfigured,
                    ),
                    AdaptiveListTile(
                      title: l10n.username,
                      subtitle: _controller.username ?? l10n.notLoggedIn,
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
          );
        },
      ),
    );
  }
}
