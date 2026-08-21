import 'package:endurain/core/utils/dialog_utils.dart';
import 'package:endurain/core/utils/platform_utils.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
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
  if (PlatformUtils.isApplePlatform) {
    return await showCupertinoDialog<ActivityStopAction>(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text(l10n.activityStopConfirmTitle),
            content: Text(l10n.activityStopConfirmMessage),
            actions: [
              CupertinoDialogAction(
                onPressed: () =>
                    Navigator.pop(context, ActivityStopAction.cancel),
                child: Text(l10n.cancel),
              ),
              CupertinoDialogAction(
                onPressed: () =>
                    Navigator.pop(context, ActivityStopAction.stop),
                child: Text(l10n.activityStopAndSave),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () =>
                    Navigator.pop(context, ActivityStopAction.discard),
                child: Text(l10n.activityDiscard),
              ),
            ],
          ),
        ) ??
        ActivityStopAction.cancel;
  }

  return await showDialog<ActivityStopAction>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.activityStopConfirmTitle),
          content: Text(l10n.activityStopConfirmMessage),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, ActivityStopAction.cancel),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, ActivityStopAction.discard),
              child: Text(l10n.activityDiscard),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, ActivityStopAction.stop),
              child: Text(l10n.activityStopAndSave),
            ),
          ],
        ),
      ) ??
      ActivityStopAction.cancel;
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
