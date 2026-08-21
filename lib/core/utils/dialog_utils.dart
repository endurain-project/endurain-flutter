import 'package:material_ui/material_ui.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:endurain/core/utils/platform_utils.dart';
import 'package:endurain/core/utils/error_localizations.dart';

/// Utility class for showing platform-adaptive dialogs
class DialogUtils {
  /// Show an error dialog with platform-adaptive UI
  static Future<void> showErrorDialog(
    BuildContext context,
    Object message, {
    String? title,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final errorTitle = title ?? l10n.error;
    final errorMessage = localizedErrorMessage(message, l10n);

    if (PlatformUtils.isApplePlatform) {
      await showCupertinoDialog<void>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(errorTitle),
          content: SelectableText(errorMessage),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.ok),
            ),
          ],
        ),
      );
    } else {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(errorTitle),
          content: SelectableText(errorMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.ok),
            ),
          ],
        ),
      );
    }
  }

  /// Show a success dialog with platform-adaptive UI
  static Future<void> showSuccessDialog(
    BuildContext context,
    String message, {
    VoidCallback? onDismiss,
  }) async {
    final l10n = AppLocalizations.of(context)!;

    if (PlatformUtils.isApplePlatform) {
      await showCupertinoDialog<void>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              onPressed: () {
                Navigator.pop(context);
                onDismiss?.call();
              },
              child: Text(l10n.ok),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      onDismiss?.call();
    }
  }

  /// Show a short platform-adaptive message.
  static Future<void> showMessage(BuildContext context, String message) async {
    final l10n = AppLocalizations.of(context)!;

    if (PlatformUtils.isApplePlatform) {
      await showCupertinoDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (context) => CupertinoAlertDialog(
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.ok),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
      );
    }
  }

  /// Show a confirmation dialog with platform-adaptive UI
  static Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmText,
    bool isDestructive = false,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    bool? confirmed = false;

    if (PlatformUtils.isApplePlatform) {
      confirmed = await showCupertinoDialog<bool>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            CupertinoDialogAction(
              isDestructiveAction: isDestructive,
              onPressed: () => Navigator.pop(context, true),
              child: Text(confirmText),
            ),
          ],
        ),
      );
    } else {
      confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(confirmText),
            ),
          ],
        ),
      );
    }

    return confirmed ?? false;
  }
}
