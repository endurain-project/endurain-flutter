import 'dart:async';

import 'package:endurain/app/app_scope.dart';
import 'package:endurain/core/constants/ui_constants.dart';
import 'package:endurain/features/activity/controllers/start_countdown_settings_controller.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:endurain/shared/layout/readable_content.dart';
import 'package:endurain/shared/state/owned_controllers.dart';
import 'package:material_ui/material_ui.dart';

/// Lets the user turn the start countdown on, pick its length, and choose
/// whether it is spoken. Read fresh each time Start is tapped.
class StartCountdownSettingsScreen extends StatefulWidget {
  const StartCountdownSettingsScreen({super.key, this.controller});

  /// Optional override for tests; otherwise resolved from [AppScope].
  final StartCountdownSettingsController? controller;

  @override
  State<StartCountdownSettingsScreen> createState() =>
      _StartCountdownSettingsScreenState();
}

class _StartCountdownSettingsScreenState
    extends State<StartCountdownSettingsScreen>
    with OwnedControllers {
  static const List<int> _presetsSeconds = [3, 5, 10, 15, 30];

  late final StartCountdownSettingsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = registerController(
      widget.controller,
      () => AppScope.servicesOf(
        context,
        listen: false,
      ).createStartCountdownSettingsController(),
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
    final loaded = _controller.isLoaded;

    return AdaptiveScaffold(
      title: l10n.startCountdownSettingsTitle,
      body: ListView(
        padding: readableContentPadding(context),
        children: [
          AdaptiveListSection(
            children: [
              AdaptiveSwitchListTile(
                title: l10n.startCountdownToggleLabel,
                subtitle: l10n.startCountdownToggleDescription,
                value: _controller.enabled,
                onChanged: loaded ? _controller.setEnabled : null,
              ),
            ],
          ),
          if (loaded && _controller.enabled) ...[
            const SizedBox(height: UIConstants.paddingStandard),
            AdaptiveListSection(
              header: l10n.startCountdownDurationHelperText,
              children: [
                for (final seconds in _presetsSeconds)
                  _DurationOptionTile(
                    title: l10n.startCountdownDurationOptionLabel(seconds),
                    isSelected: _controller.seconds == seconds,
                    onTap: () => _controller.setSeconds(seconds),
                  ),
              ],
            ),
            const SizedBox(height: UIConstants.paddingStandard),
            AdaptiveListSection(
              children: [
                AdaptiveSwitchListTile(
                  title: l10n.startCountdownVoiceLabel,
                  subtitle: l10n.startCountdownVoiceDescription,
                  value: _controller.voiceEnabled,
                  onChanged: _controller.setVoiceEnabled,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DurationOptionTile extends StatelessWidget {
  const _DurationOptionTile({
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
