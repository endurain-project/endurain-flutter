import 'dart:async';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:endurain/core/constants/ui_constants.dart';
import 'package:endurain/core/services/platform/url_launcher_service.dart';
import 'package:endurain/core/utils/dialog_utils.dart';
import 'package:endurain/core/utils/server_url_resolver.dart';
import 'package:endurain/features/settings/controllers/locale_controller.dart';
import 'package:endurain/features/settings/controllers/settings_controller.dart';
import 'package:endurain/features/settings/screens/language_settings_screen.dart';
import 'package:endurain/features/settings/screens/settings_destinations.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:endurain/shared/layout/readable_content.dart';
import 'package:endurain/shared/state/owned_controllers.dart';
import 'package:material_ui/material_ui.dart';

/// Public GitHub organization for the project, opened from the settings screen.
const String _sourceCodeUrl = 'https://github.com/endurain-project';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.destinations,
    required this.localeController,
    required this.urlLauncherService,
    required this.healthSyncEnabled,
    this.isGuest = false,
    this.onSignIn,
    this.controller,
    this.createController,
  }) : assert(
         controller != null || createController != null,
         'Pass a controller or a factory for one.',
       );

  /// The screens the list opens.
  final SettingsDestinations destinations;

  /// Whether the Health Sync entry (and the health permissions in Device
  /// access) are offered in this build.
  final bool healthSyncEnabled;

  /// Whether the app is running in local-only guest mode (no server session).
  /// Guests see a "sign in / connect a server" entry instead of server
  /// settings.
  final bool isGuest;

  /// Invoked when a guest chooses to connect a server / sign in.
  final VoidCallback? onSignIn;

  /// Injected controller (tests); otherwise one is built with
  /// [createController] and owned by the screen.
  final SettingsController? controller;
  final SettingsController Function()? createController;

  /// Read for the language subtitle, which follows the user's choice.
  final LocaleController localeController;
  final UrlLauncherService urlLauncherService;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with OwnedControllers {
  late final SettingsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = registerController(
      widget.controller,
      () => widget.createController!(),
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
    final launched = await widget.urlLauncherService.launchExternalApplication(
      Uri.parse(_sourceCodeUrl),
    );
    if (!launched && mounted) {
      await DialogUtils.showErrorDialog(context, l10n.openLinkFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = widget.localeController.locale;
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
              padding: readableContentPadding(context),
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
                            : ServerUrlResolver.isPlainHttp(serverUrl)
                            ? '${l10n.connectedToServer(serverUrl)}\n'
                                  '${l10n.serverNotSecure}'
                            : l10n.connectedToServer(serverUrl),
                        destination: widget.destinations.serverSettings,
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
                      destination: widget.destinations.language,
                    ),
                    _SettingsNavTile(
                      materialIcon: Icons.straighten,
                      cupertinoIcon: CupertinoIcons.arrow_left_right,
                      title: l10n.unitsTitle,
                      subtitle: l10n.unitsSubtitle,
                      destination: widget.destinations.units,
                    ),
                    // The tile URL is stored per connected server, so guests
                    // (no server) have nothing to configure.
                    if (!widget.isGuest)
                      _SettingsNavTile(
                        materialIcon: Icons.map_outlined,
                        cupertinoIcon: CupertinoIcons.map,
                        title: l10n.mapTilesSettingsTitle,
                        subtitle: l10n.mapTilesSettingsSubtitle,
                        destination: widget.destinations.tileServer,
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
                      destination: widget.destinations.startCountdown,
                    ),
                    _SettingsNavTile(
                      materialIcon: Icons.pause_circle_outline,
                      cupertinoIcon: CupertinoIcons.pause_circle,
                      title: l10n.activityAutoPauseTitle,
                      subtitle: l10n.activityAutoPauseSubtitle,
                      destination: widget.destinations.autoPause,
                    ),
                    _SettingsNavTile(
                      materialIcon: Icons.record_voice_over,
                      cupertinoIcon: CupertinoIcons.speaker_2,
                      title: l10n.audioAnnouncementsTitle,
                      subtitle: l10n.audioAnnouncementsSubtitle,
                      destination: widget.destinations.audioAnnouncements,
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
                      destination: widget.destinations.sensors,
                    ),
                    if (widget.healthSyncEnabled && !widget.isGuest)
                      _SettingsNavTile(
                        materialIcon: Icons.monitor_heart,
                        cupertinoIcon: CupertinoIcons.heart,
                        title: l10n.healthSyncSettingsTitle,
                        subtitle: l10n.healthSyncSettingsSubtitle,
                        destination: widget.destinations.healthSync,
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
                      destination: widget.destinations.activityHistory,
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
                      destination: widget.destinations.deviceAccess,
                    ),
                    _SettingsNavTile(
                      materialIcon: Icons.bug_report,
                      cupertinoIcon: CupertinoIcons.waveform_path_ecg,
                      title: l10n.diagnostics,
                      subtitle: l10n.diagnosticsSubtitle,
                      destination: widget.destinations.diagnostics,
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
