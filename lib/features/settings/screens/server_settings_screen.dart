import 'dart:async';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:endurain/app/app_scope.dart';
import 'package:endurain/app/app_services.dart';
import 'package:endurain/core/auth/auth_service.dart';
import 'package:endurain/core/auth/secure_storage_service.dart';
import 'package:endurain/core/constants/ui_constants.dart';
import 'package:endurain/core/utils/dialog_utils.dart';
import 'package:endurain/core/utils/error_localizations.dart';
import 'package:endurain/features/settings/controllers/server_settings_controller.dart';
import 'package:endurain/features/settings/repositories/server_settings_repository.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:endurain/shared/state/owned_controllers.dart';
import 'package:material_ui/material_ui.dart';

class ServerSettingsScreen extends StatefulWidget {
  const ServerSettingsScreen({
    super.key,
    this.onLogout,
    this.storage,
    this.authService,
    this.repository,
  });

  final VoidCallback? onLogout;
  final SecureStorageService? storage;
  final AuthService? authService;
  final ServerSettingsRepository? repository;

  @override
  State<ServerSettingsScreen> createState() => _ServerSettingsScreenState();
}

class _ServerSettingsScreenState extends State<ServerSettingsScreen>
    with OwnedControllers {
  late final ServerSettingsController _controller;

  @override
  void initState() {
    super.initState();
    final services = AppScope.servicesOf(context, listen: false);
    // The screen always owns the controller; its test seam is the repository
    // (built here) rather than the controller itself.
    _controller = registerController(
      null,
      () => ServerSettingsController(
        repository: widget.repository ?? _createRepository(services),
      ),
    );
    unawaited(_controller.load());
  }

  ServerSettingsRepository _createRepository(AppServices services) {
    final storage = widget.storage ?? services.secureStorage;
    return ServerSettingsRepository(
      storage: storage,
      authService: widget.authService ?? services.auth,
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
      // The local clear can fail when secure storage is unavailable. The user
      // asked to sign out, so the app still leaves the session; the message
      // says what went wrong.
      String? warning;
      try {
        if (!await _controller.logout()) {
          warning = l10n.logoutServerFailedWarning;
        }
      } catch (error) {
        warning = localizedErrorMessage(error, l10n);
      }
      if (!mounted) {
        widget.onLogout?.call();
        return;
      }
      if (warning != null) {
        await DialogUtils.showMessage(context, warning);
        if (!mounted) {
          widget.onLogout?.call();
          return;
        }
      }
      // Pop back to settings screen and trigger logout
      Navigator.pop(context);
      widget.onLogout?.call();
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
          return ListView(
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
            ],
          );
        },
      ),
    );
  }
}
