import 'dart:async';

import 'package:endurain/core/constants/ui_constants.dart';
import 'package:endurain/core/services/app_scope.dart';
import 'package:endurain/features/activity/controllers/auto_pause_settings_controller.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:endurain/shared/state/owned_controllers.dart';
import 'package:material_ui/material_ui.dart';

/// Lets the user enable/disable auto-pause and choose the stillness delay.
///
/// The change only affects the *next* recording: the active configuration is
/// read once and snapshotted onto the session when a recording starts (see
/// `ActiveActivitySession.autoPauseEnabled`/`autoPauseDelaySeconds`), so a
/// change made here never alters a recording already in progress.
class AutoPauseSettingsScreen extends StatefulWidget {
  const AutoPauseSettingsScreen({super.key, this.controller});

  /// Optional override for tests; otherwise resolved from [AppScope].
  final AutoPauseSettingsController? controller;

  @override
  State<AutoPauseSettingsScreen> createState() =>
      _AutoPauseSettingsScreenState();
}

class _AutoPauseSettingsScreenState extends State<AutoPauseSettingsScreen>
    with OwnedControllers {
  static const List<int> _delayPresetsSeconds = [5, 10, 15, 30, 60];

  late final AutoPauseSettingsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = registerController(
      widget.controller,
      () => AppScope.servicesOf(
        context,
        listen: false,
      ).createAutoPauseSettingsController(),
      onChanged: _onControllerChanged,
    );
    unawaited(_controller.load());
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AdaptiveScaffold(
      title: l10n.activityAutoPauseTitle,
      body: ListView(
        padding: const EdgeInsets.all(UIConstants.paddingStandard),
        children: [
          AdaptiveListSection(
            children: [
              AdaptiveSwitchListTile(
                title: l10n.activityAutoPauseToggleLabel,
                subtitle: l10n.activityAutoPauseToggleDescription,
                value: _controller.enabled,
                onChanged: _controller.isLoaded ? _controller.setEnabled : null,
              ),
            ],
          ),
          if (_controller.isLoaded && _controller.enabled) ...[
            const SizedBox(height: UIConstants.paddingStandard),
            AdaptiveListSection(
              header: l10n.activityAutoPauseDelayHelperText,
              children: [
                for (final seconds in _delayPresetsSeconds)
                  _DelayOptionTile(
                    title: l10n.activityAutoPauseDelayOptionLabel(seconds),
                    isSelected: _controller.delaySeconds == seconds,
                    onTap: () => _controller.setDelaySeconds(seconds),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DelayOptionTile extends StatelessWidget {
  const _DelayOptionTile({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AdaptiveListTile(
      title: title,
      onTap: onTap,
      trailing: isSelected
          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
          : null,
    );
  }
}
