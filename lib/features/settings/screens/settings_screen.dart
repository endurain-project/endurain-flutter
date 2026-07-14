import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:endurain/core/services/app_scope.dart';
import 'package:endurain/core/services/diagnostics_service.dart';
import 'package:endurain/core/services/platform/package_info_service.dart';
import 'package:endurain/core/services/secure_storage_service.dart';
import 'package:endurain/core/services/platform/url_launcher_service.dart';
import 'package:endurain/core/utils/dialog_utils.dart';
import 'package:endurain/features/activity/repositories/activity_retention_settings_repository.dart';
import 'package:endurain/features/activity/screens/activity_history_screen.dart';
import 'package:endurain/features/health/screens/health_sync_screen.dart';
import 'package:endurain/features/settings/controllers/locale_controller.dart';
import 'package:endurain/features/settings/screens/device_access_screen.dart';
import 'package:endurain/features/settings/screens/diagnostics_screen.dart';
import 'package:endurain/features/settings/screens/language_settings_screen.dart';
import 'package:endurain/features/settings/screens/server_settings_screen.dart';
import 'package:endurain/core/constants/ui_constants.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';

/// Public source repository for the project, opened from the settings screen.
const String _sourceCodeUrl = 'https://codeberg.org/endurain-project';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    this.onLogout,
    this.isGuest = false,
    this.onSignIn,
    this.packageInfoService,
    this.diagnostics,
    this.activityRetentionSettings,
    this.localeController,
    this.secureStorage,
    this.urlLauncherService,
  });

  final VoidCallback? onLogout;

  /// Whether the app is running in local-only guest mode (no server session).
  /// Guests see a "sign in / connect a server" entry instead of server
  /// settings.
  final bool isGuest;

  /// Invoked when a guest chooses to connect a server / sign in.
  final VoidCallback? onSignIn;

  final PackageInfoService? packageInfoService;
  final DiagnosticsStore? diagnostics;
  final ActivityRetentionSettingsRepository? activityRetentionSettings;
  final LocaleController? localeController;
  final SecureStorageService? secureStorage;
  final UrlLauncherService? urlLauncherService;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '';
  String? _serverUrl;
  bool _retainUploadedGpx = true;
  late final PackageInfoService _packageInfoService;
  late final ActivityRetentionSettingsRepository _activityRetentionSettings;
  late final SecureStorageService _secureStorage;
  late final bool _healthSyncEnabled;
  late final UrlLauncherService _urlLauncherService;

  @override
  void initState() {
    super.initState();
    final services = AppScope.servicesOf(context, listen: false);
    _packageInfoService = widget.packageInfoService ?? services.packageInfo;
    _activityRetentionSettings =
        widget.activityRetentionSettings ?? services.activityRetentionSettings;
    _secureStorage = widget.secureStorage ?? services.secureStorage;
    _healthSyncEnabled = services.config.healthSyncEnabled;
    _urlLauncherService = widget.urlLauncherService ?? services.urlLauncher;
    _loadVersion();
    _loadServerUrl();
    _loadActivityRetentionSetting();
  }

  Future<void> _openSourceCode() async {
    final l10n = AppLocalizations.of(context)!;
    final launched = await _urlLauncherService.launchExternalApplication(
      Uri.parse(_sourceCodeUrl),
    );
    if (!launched && mounted) {
      await DialogUtils.showErrorDialog(context, l10n.openLinkFailed);
    }
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

  Future<void> _loadServerUrl() async {
    try {
      final serverUrl = await _secureStorage.getServerUrl();
      if (mounted) {
        setState(() {
          _serverUrl = serverUrl;
        });
      }
    } catch (_) {
      // The settings page remains usable if secure storage is temporarily
      // unavailable; the server details screen exposes storage errors directly.
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
    final localeController =
        widget.localeController ??
        AppScope.servicesOf(context, listen: false).localeController;
    final currentLocale = localeController.locale;
    final languageSubtitle = currentLocale == null
        ? l10n.languageSystemDefault
        : languageDisplayName(currentLocale);
    final footerTextStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );

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
                    if (widget.isGuest)
                      AdaptiveListTile(
                        leading: const AdaptiveIcon(
                          materialIcon: Icons.login,
                          cupertinoIcon: CupertinoIcons.square_arrow_right,
                        ),
                        title: l10n.signInConnectServer,
                        subtitle: l10n.signInConnectServerSubtitle,
                        onTap: widget.onSignIn,
                      )
                    else
                      AdaptiveListTile(
                        leading: const AdaptiveIcon(
                          materialIcon: Icons.dns,
                          cupertinoIcon: CupertinoIcons.globe,
                        ),
                        title: l10n.serverSettings,
                        subtitle: _serverUrl == null || _serverUrl!.isEmpty
                            ? null
                            : l10n.connectedToServer(_serverUrl!),
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
                        materialIcon: Icons.language,
                        cupertinoIcon: CupertinoIcons.textformat,
                      ),
                      title: l10n.language,
                      subtitle: languageSubtitle,
                      onTap: () {
                        adaptivePush<void>(
                          context,
                          (context) => const LanguageSettingsScreen(),
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
                        materialIcon: Icons.admin_panel_settings_outlined,
                        cupertinoIcon: CupertinoIcons.shield,
                      ),
                      title: l10n.deviceAccessTitle,
                      subtitle: l10n.deviceAccessSubtitle,
                      onTap: () {
                        adaptivePush<void>(
                          context,
                          (context) => DeviceAccessScreen(
                            healthSyncEnabled: _healthSyncEnabled,
                          ),
                        );
                      },
                    ),
                    if (_healthSyncEnabled && !widget.isGuest)
                      AdaptiveListTile(
                        leading: const AdaptiveIcon(
                          materialIcon: Icons.monitor_heart,
                          cupertinoIcon: CupertinoIcons.heart,
                        ),
                        title: l10n.healthSyncSettingsTitle,
                        subtitle: l10n.healthSyncSettingsSubtitle,
                        onTap: () {
                          adaptivePush<void>(
                            context,
                            (context) => const HealthSyncScreen(),
                          );
                        },
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
                    AdaptiveListTile(
                      leading: const AdaptiveIcon(
                        materialIcon: Icons.code,
                        cupertinoIcon:
                            CupertinoIcons.chevron_left_slash_chevron_right,
                      ),
                      title: l10n.sourceCode,
                      subtitle: l10n.sourceCodeSubtitle,
                      onTap: _openSourceCode,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              UIConstants.paddingStandard,
              0,
              UIConstants.paddingStandard,
              UIConstants.paddingStandard,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _version,
                  textAlign: TextAlign.center,
                  style: footerTextStyle,
                ),
                const SizedBox(height: UIConstants.paddingSmall),
                Text(
                  l10n.endurainTrademarkNotice,
                  textAlign: TextAlign.center,
                  style: footerTextStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
