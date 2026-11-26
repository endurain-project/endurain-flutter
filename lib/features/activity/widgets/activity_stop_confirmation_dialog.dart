import 'package:endurain/core/utils/dialog_utils.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

enum ActivityStopAction { cancel, stop, discard }

Future<ActivityStopAction> showActivityStopConfirmationDialog(
  BuildContext context,
) async {
  final l10n = AppLocalizations.of(context)!;
  final action = await _showStopDialog(context, l10n);
  if (action != ActivityStopAction.discard) {
    return action;
  }
  if (!context.mounted) {
    return ActivityStopAction.cancel;
  }

  final discardConfirmed = await _showDiscardDialog(context, l10n);
  return discardConfirmed
      ? ActivityStopAction.discard
      : ActivityStopAction.cancel;
}

Future<ActivityStopAction> _showStopDialog(
  BuildContext context,
  AppLocalizations l10n,
) async {
  final action = await DialogUtils.showActionDialog<ActivityStopAction>(
    context,
    title: l10n.activityStopConfirmTitle,
    message: l10n.activityStopConfirmMessage,
    choices: [
      DialogChoice(label: l10n.cancel, value: ActivityStopAction.cancel),
      DialogChoice(
        label: l10n.activityStopAndSave,
        value: ActivityStopAction.stop,
      ),
      DialogChoice(
        label: l10n.activityDiscard,
        value: ActivityStopAction.discard,
        isDestructive: true,
      ),
    ],
  );
  return action ?? ActivityStopAction.cancel;
}

Future<bool> _showDiscardDialog(BuildContext context, AppLocalizations l10n) {
  return DialogUtils.showConfirmDialog(
    context,
    title: l10n.activityDiscardConfirmTitle,
    message: l10n.activityDiscardConfirmMessage,
    confirmText: l10n.activityDiscard,
    isDestructive: true,
  );
}
