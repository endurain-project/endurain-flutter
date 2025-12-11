import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:endurain/core/services/secure_storage_service.dart';
import 'package:endurain/core/services/auth_service.dart';
import 'package:endurain/core/utils/platform_utils.dart';
import 'package:endurain/core/utils/validators.dart';
import 'package:endurain/core/utils/dialog_utils.dart';
import 'package:endurain/core/constants/ui_constants.dart';

class ServerSettingsScreen extends StatefulWidget {
  const ServerSettingsScreen({super.key, this.onLogout});

  final VoidCallback? onLogout;

  @override
  State<ServerSettingsScreen> createState() => _ServerSettingsScreenState();
}

class _ServerSettingsScreenState extends State<ServerSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tileServerUrlController = TextEditingController();
  final _storage = SecureStorageService();
  final _authService = AuthService();
  bool _isLoading = true;
  String _serverUrl = '';
  String _username = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _tileServerUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final serverUrl = await _storage.getServerUrl();
    final username = await _storage.getUsername();
    final tileServerUrl = await _storage.getTileServerUrl();

    if (mounted) {
      setState(() {
        _serverUrl = serverUrl ?? 'Not configured';
        _username = username ?? 'Not logged in';
        _tileServerUrlController.text =
            tileServerUrl ?? 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;

    try {
      await _storage.setTileServerUrl(_tileServerUrlController.text.trim());

      if (mounted) {
        await DialogUtils.showSuccessDialog(
          context,
          l10n.savedSuccessfully,
          onDismiss: () => Navigator.pop(context),
        );
      }
    } catch (e) {
      if (mounted) {
        await DialogUtils.showErrorDialog(context, e.toString());
      }
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
      await _authService.logout();
      if (mounted) {
        // Pop back to settings screen and trigger logout
        Navigator.pop(context);
        widget.onLogout?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Cupertino style for iOS/macOS
    if (PlatformUtils.isApplePlatform) {
      if (_isLoading) {
        return const CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(),
          child: Center(child: CupertinoActivityIndicator()),
        );
      }

      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(l10n.serverSettingsTitle),
        ),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(UIConstants.paddingStandard),
              children: [
                CupertinoListSection.insetGrouped(
                  header: Text(l10n.loggedIn),
                  children: [
                    CupertinoListTile(
                      title: Text(l10n.serverUrl),
                      subtitle: Text(_serverUrl),
                    ),
                    CupertinoListTile(
                      title: Text(l10n.username),
                      subtitle: Text(_username),
                    ),
                    CupertinoListTile(
                      leading: const Icon(
                        CupertinoIcons.square_arrow_right,
                        color: CupertinoColors.systemRed,
                      ),
                      title: Text(
                        l10n.logout,
                        style: const TextStyle(
                          color: CupertinoColors.systemRed,
                        ),
                      ),
                      onTap: _handleLogout,
                    ),
                  ],
                ),
                CupertinoListSection.insetGrouped(
                  header: Text(l10n.tileServerUrl),
                  children: [
                    CupertinoTextFormFieldRow(
                      controller: _tileServerUrlController,
                      placeholder: l10n.tileServerUrlHint,
                      keyboardType: TextInputType.url,
                      textInputAction: TextInputAction.done,
                      validator: (value) => Validators.validateUrl(value, l10n),
                      onFieldSubmitted: (_) => _saveSettings(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: UIConstants.paddingStandard,
                  ),
                  child: CupertinoButton.filled(
                    onPressed: _saveSettings,
                    child: Text(l10n.save),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Material style for Android
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.serverSettingsTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.serverSettingsTitle)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(UIConstants.paddingStandard),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(UIConstants.paddingStandard),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.loggedIn,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          l10n.serverUrl,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Expanded(child: Text(_serverUrl)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          l10n.username,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(_username),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: Text(
                        l10n.logout,
                        style: const TextStyle(color: Colors.red),
                      ),
                      onTap: _handleLogout,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tileServerUrlController,
              decoration: InputDecoration(
                labelText: l10n.tileServerUrl,
                hintText: l10n.tileServerUrlHint,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              validator: (value) => Validators.validateUrl(value, l10n),
              onFieldSubmitted: (_) => _saveSettings(),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saveSettings,
              child: Padding(
                padding: const EdgeInsets.all(UIConstants.paddingMedium),
                child: Text(l10n.save),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
