import 'dart:async';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:endurain/app/app_scope.dart';
import 'package:endurain/core/constants/ui_constants.dart';
import 'package:endurain/core/diagnostics/diagnostics_service.dart';
import 'package:endurain/core/services/platform/url_launcher_service.dart';
import 'package:endurain/core/utils/dialog_utils.dart';
import 'package:endurain/features/activity/screens/activity_history_screen.dart';
import 'package:endurain/features/activity/screens/auto_pause_settings_screen.dart';
import 'package:endurain/features/activity/screens/start_countdown_settings_screen.dart';
import 'package:endurain/features/health/screens/health_sync_screen.dart';
import 'package:endurain/features/sensors/screens/sensor_settings_screen.dart';
import 'package:endurain/features/settings/controllers/locale_controller.dart';
import 'package:endurain/features/settings/controllers/settings_controller.dart';
import 'package:endurain/features/settings/screens/audio_announcement_settings_screen.dart';
import 'package:endurain/features/settings/screens/device_access_screen.dart';
import 'package:endurain/features/settings/screens/diagnostics_screen.dart';
import 'package:endurain/features/settings/screens/language_settings_screen.dart';
import 'package:endurain/features/settings/screens/server_settings_screen.dart';
import 'package:endurain/features/settings/screens/units_settings_screen.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:endurain/shared/state/owned_controllers.dart';
import 'package:material_ui/material_ui.dart';

/// Public GitHub organization for the project, opened from the settings screen.
const String _sourceCodeUrl = 'https://github.com/endurain-project';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    this.onLogout,
    this.isGuest = false,
    this.onSignIn,
    this.controller,
    this.diagnostics,
    this.localeController,
    this.urlLauncherService,
  });

  final VoidCallback? onLogout;

  /// Whether the app is running in local-only guest mode (no server session).
  /// Guests see a "sign in / connect a server" entry instead of server
  /// settings.
  final bool isGuest;

  /// Invoked when a guest chooses to connect a server / sign in.
  final VoidCallback? onSignIn;

  /// Optional route-owned controller override (tests).
  final SettingsController? controller;

  final DiagnosticsStore? diagnostics;
  final LocaleController? localeController;
  final UrlLauncherService? urlLauncherService;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with OwnedControllers {
  late final SettingsController _controller;
  late final bool _healthSyncEnabled;
  late final UrlLauncherService _urlLauncherService;

  @override
  void initState() {
    super.initState();
    final services = AppScope.servicesOf(context, listen: false);
    _healthSyncEnabled = services.config.healthSyncEnabled;
    _urlLauncherService = widget.urlLauncherService ?? services.urlLauncher;
    _controller = registerController(
      widget.controller,
      services.createSettingsController,
      onChanged: _onControllerChanged,
    );
    unawaited(_controller.load());
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
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
    final serverUrl = _controller.serverUrl;
    final appVersion = _controller.appVersion;
    final versionText = appVersion == null
        ? ''
        : '© ${UIConstants.copyrightStartYear} - ${DateTime.now().year} '
              'Endurain • $appVersion';
    final footerTextStyle = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);

    return AdaptiveScaffold(
      title: l10n.settingsScreen,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(UIConstants.paddingStandard),
              children: [
                AdaptiveListSection(
                  header: l10n.settingsSectionAccount,
                  children: [
                    if (widget.isGuest)
                      _SettingsNavTile(
                        materialIcon: Icons.login,
                        cupertinoIcon: CupertinoIcons.square_arrow_right,
                        title: l10n.signInConnectServer,
                        subtitle: l10n.signInConnectServerSubtitle,
                        onTap: widget.onSignIn,
                      )
                    else
                      _SettingsNavTile(
                        materialIcon: Icons.dns,
                        cupertinoIcon: CupertinoIcons.globe,
                        title: l10n.serverSettings,
                        subtitle: serverUrl == null || serverUrl.isEmpty
                            ? null
                            : l10n.connectedToServer(serverUrl),
                        destination: (context) =>
                            ServerSettingsScreen(onLogout: widget.onLogout),
                      ),
                  ],
                ),
                const SizedBox(height: UIConstants.paddingStandard),
                AdaptiveListSection(
                  header: l10n.settingsSectionGeneral,
                  children: [
                    _SettingsNavTile(
                      materialIcon: Icons.language,
                      cupertinoIcon: CupertinoIcons.textformat,
                      title: l10n.language,
                      subtitle: languageSubtitle,
                      destination: (context) => const LanguageSettingsScreen(),
                    ),
                    _SettingsNavTile(
                      materialIcon: Icons.straighten,
                      cupertinoIcon: CupertinoIcons.arrow_left_right,
                      title: l10n.unitsTitle,
                      subtitle: l10n.unitsSubtitle,
                      destination: (context) => const UnitsSettingsScreen(),
                    ),
                  ],
                ),
                const SizedBox(height: UIConstants.paddingStandard),
                AdaptiveListSection(
                  header: l10n.settingsSectionRecording,
                  children: [
                    _SettingsNavTile(
                      materialIcon: Icons.timer_outlined,
                      cupertinoIcon: CupertinoIcons.timer,
                      title: l10n.startCountdownSettingsTitle,
                      subtitle: l10n.startCountdownSettingsSubtitle,
                      destination: (context) =>
                          const StartCountdownSettingsScreen(),
                    ),
                    _SettingsNavTile(
                      materialIcon: Icons.pause_circle_outline,
                      cupertinoIcon: CupertinoIcons.pause_circle,
                      title: l10n.activityAutoPauseTitle,
                      subtitle: l10n.activityAutoPauseSubtitle,
                      destination: (context) => const AutoPauseSettingsScreen(),
                    ),
                    _SettingsNavTile(
                      materialIcon: Icons.record_voice_over,
                      cupertinoIcon: CupertinoIcons.speaker_2,
                      title: l10n.audioAnnouncementsTitle,
                      subtitle: l10n.audioAnnouncementsSubtitle,
                      destination: (context) =>
                          const AudioAnnouncementSettingsScreen(),
                    ),
                  ],
                ),
                const SizedBox(height: UIConstants.paddingStandard),
                AdaptiveListSection(
                  header: l10n.settingsSectionDevices,
                  children: [
                    _SettingsNavTile(
                      materialIcon: Icons.sensors,
                      cupertinoIcon: CupertinoIcons.dot_radiowaves_left_right,
                      title: l10n.sensorsTitle,
                      subtitle: l10n.sensorsSettingsSubtitle,
                      destination: (context) => const SensorSettingsScreen(),
                    ),
                    if (_healthSyncEnabled && !widget.isGuest)
                      _SettingsNavTile(
                        materialIcon: Icons.monitor_heart,
                        cupertinoIcon: CupertinoIcons.heart,
                        title: l10n.healthSyncSettingsTitle,
                        subtitle: l10n.healthSyncSettingsSubtitle,
                        destination: (context) => const HealthSyncScreen(),
                      ),
                  ],
                ),
                const SizedBox(height: UIConstants.paddingStandard),
                AdaptiveListSection(
                  header: l10n.settingsSectionData,
                  children: [
                    _SettingsNavTile(
                      materialIcon: Icons.history,
                      cupertinoIcon: CupertinoIcons.time,
                      title: l10n.activityHistoryTitle,
                      subtitle: l10n.activityHistorySettingsSubtitle,
                      destination: (context) => const ActivityHistoryScreen(),
                    ),
                  ],
                ),
                const SizedBox(height: UIConstants.paddingStandard),
                AdaptiveListSection(
                  header: l10n.settingsSectionPrivacySupport,
                  children: [
                    _SettingsNavTile(
                      materialIcon: Icons.admin_panel_settings_outlined,
                      cupertinoIcon: CupertinoIcons.shield,
                      title: l10n.deviceAccessTitle,
                      subtitle: l10n.deviceAccessSubtitle,
                      destination: (context) => DeviceAccessScreen(
                        healthSyncEnabled: _healthSyncEnabled,
                      ),
                    ),
                    _SettingsNavTile(
                      materialIcon: Icons.bug_report,
                      cupertinoIcon: CupertinoIcons.waveform_path_ecg,
                      title: l10n.diagnostics,
                      subtitle: l10n.diagnosticsSubtitle,
                      destination: (context) => DiagnosticsScreen(
                        diagnostics:
                            widget.diagnostics ??
                            AppScope.servicesOf(
                              context,
                              listen: false,
                            ).diagnostics,
                      ),
                    ),
                    _SettingsNavTile(
                      materialIcon: Icons.code,
                      cupertinoIcon:
                          CupertinoIcons.chevron_left_slash_chevron_right,
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
                  versionText,
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

/// One row of the settings list: an icon, a title and an optional subtitle.
///
/// Give [destination] to push a settings sub-screen, or [onTap] for any other
/// action (signing in, opening a link).
class _SettingsNavTile extends StatelessWidget {
  const _SettingsNavTile({
    required this.materialIcon,
    required this.cupertinoIcon,
    required this.title,
    this.subtitle,
    this.destination,
    this.onTap,
  }) : assert(
         destination == null || onTap == null,
         'Pass either destination or onTap, not both.',
       );

  final IconData materialIcon;
  final IconData cupertinoIcon;
  final String title;
  final String? subtitle;
  final WidgetBuilder? destination;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final destination = this.destination;
    return AdaptiveListTile(
      leading: AdaptiveIcon(
        materialIcon: materialIcon,
        cupertinoIcon: cupertinoIcon,
      ),
      title: title,
      subtitle: subtitle,
      onTap: destination == null
          ? onTap
          : () => adaptivePush<void>(context, destination),
    );
  }
}
