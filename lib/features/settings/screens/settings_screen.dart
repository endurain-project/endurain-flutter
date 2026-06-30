import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:endurain/core/services/app_scope.dart';
import 'package:endurain/core/services/diagnostics_service.dart';
import 'package:endurain/core/services/package_info_service.dart';
import 'package:endurain/features/activity/repositories/activity_retention_settings_repository.dart';
import 'package:endurain/features/activity/screens/activity_history_screen.dart';
import 'package:endurain/features/settings/screens/diagnostics_screen.dart';
import 'package:endurain/features/settings/screens/server_settings_screen.dart';
import 'package:endurain/core/constants/ui_constants.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    this.onLogout,
    this.packageInfoService,
    this.diagnostics,
    this.activityRetentionSettings,
  });

  final VoidCallback? onLogout;
  final PackageInfoService? packageInfoService;
  final DiagnosticsStore? diagnostics;
  final ActivityRetentionSettingsRepository? activityRetentionSettings;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '';
  bool _retainUploadedGpx = true;
  late final PackageInfoService _packageInfoService;
  late final ActivityRetentionSettingsRepository _activityRetentionSettings;

  @override
  void initState() {
    super.initState();
    _packageInfoService =
        widget.packageInfoService ??
        AppScope.servicesOf(context, listen: false).packageInfo;
    _activityRetentionSettings =
        widget.activityRetentionSettings ??
        AppScope.servicesOf(context, listen: false).activityRetentionSettings;
    _loadVersion();
    _loadActivityRetentionSetting();
  }

  Future<void> _loadVersion() async {
    final packageInfo = await _packageInfoService.fromPlatform();
    final currentYear = DateTime.now().year;
    if (mounted) {
      setState(() {
        _version =
            '© ${UIConstants.copyrightStartYear} - $currentYear Endurain • ${packageInfo.version}';
      });
    }
  }

  Future<void> _loadActivityRetentionSetting() async {
    final retainUploadedGpx = await _activityRetentionSettings
        .isRetainUploadedGpxEnabled();
    if (mounted) {
      setState(() {
        _retainUploadedGpx = retainUploadedGpx;
      });
    }
  }

  Future<void> _setRetainUploadedGpx(bool value) async {
    setState(() {
      _retainUploadedGpx = value;
    });
    await _activityRetentionSettings.setRetainUploadedGpxEnabled(value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AdaptiveScaffold(
      title: l10n.settingsScreen,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(UIConstants.paddingStandard),
              children: [
                AdaptiveListSection(
                  children: [
                    AdaptiveListTile(
                      leading: const AdaptiveIcon(
                        materialIcon: Icons.dns,
                        cupertinoIcon: CupertinoIcons.globe,
                      ),
                      title: l10n.serverSettings,
                      onTap: () {
                        adaptivePush<void>(
                          context,
                          (context) =>
                              ServerSettingsScreen(onLogout: widget.onLogout),
                        );
                      },
                    ),
                    AdaptiveListTile(
                      leading: const AdaptiveIcon(
                        materialIcon: Icons.history,
                        cupertinoIcon: CupertinoIcons.time,
                      ),
                      title: l10n.activityHistoryTitle,
                      subtitle: l10n.activityHistorySettingsSubtitle,
                      onTap: () {
                        adaptivePush<void>(
                          context,
                          (context) => const ActivityHistoryScreen(),
                        );
                      },
                    ),
                    AdaptiveSwitchListTile(
                      leading: const AdaptiveIcon(
                        materialIcon: Icons.description,
                        cupertinoIcon: CupertinoIcons.doc_text,
                      ),
                      title: l10n.activityRetainUploadedGpx,
                      subtitle: l10n.activityRetainUploadedGpxSubtitle,
                      value: _retainUploadedGpx,
                      onChanged: _setRetainUploadedGpx,
                    ),
                    AdaptiveListTile(
                      leading: const AdaptiveIcon(
                        materialIcon: Icons.bug_report,
                        cupertinoIcon: CupertinoIcons.waveform_path_ecg,
                      ),
                      title: l10n.diagnostics,
                      subtitle: l10n.diagnosticsSubtitle,
                      onTap: () {
                        adaptivePush<void>(
                          context,
                          (context) => DiagnosticsScreen(
                            diagnostics:
                                widget.diagnostics ??
                                AppScope.servicesOf(
                                  context,
                                  listen: false,
                                ).diagnostics,
                          ),
                        );
                      },
                    ),
                  ],
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
