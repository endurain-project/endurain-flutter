import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:endurain/features/settings/server_settings_screen.dart';
import 'package:endurain/core/utils/platform_utils.dart';
import 'package:endurain/core/constants/ui_constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.onLogout});

  final VoidCallback? onLogout;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentYear = DateTime.now().year;
    if (mounted) {
      setState(() {
        _version =
            '© ${UIConstants.copyrightStartYear} - $currentYear Endurain • ${packageInfo.version}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Cupertino style for iOS/macOS
    if (PlatformUtils.isApplePlatform) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(l10n.settingsScreen),
        ),
        child: SafeArea(
          child: Column(
            children: [
              CupertinoListSection.insetGrouped(
                children: [
                  CupertinoListTile(
                    leading: const Icon(CupertinoIcons.globe),
                    title: Text(l10n.serverSettings),
                    trailing: const CupertinoListTileChevron(),
                    onTap: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute<void>(
                          builder: (context) =>
                              ServerSettingsScreen(onLogout: widget.onLogout),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(
                  bottom: UIConstants.paddingStandard,
                ),
                child: Text(
                  _version,
                  style: CupertinoTheme.of(context).textTheme.tabLabelTextStyle
                      .copyWith(color: CupertinoColors.systemGrey),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Material style for Android
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsScreen)),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  leading: const Icon(Icons.dns),
                  title: Text(l10n.serverSettings),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (context) =>
                            ServerSettingsScreen(onLogout: widget.onLogout),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: UIConstants.paddingStandard),
            child: Text(
              _version,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
