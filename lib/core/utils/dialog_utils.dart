import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:endurain/core/diagnostics/diagnostics_scope.dart';
import 'package:endurain/core/diagnostics/diagnostics_service.dart';
import 'package:endurain/core/utils/error_localizations.dart';
import 'package:endurain/core/utils/platform_utils.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// Utility class for showing platform-adaptive dialogs
class DialogUtils {
  /// Show an error dialog with platform-adaptive UI
  ///
  /// Records a breadcrumb for every error the user is shown, so a report
  /// always explains a failure the user saw. A ready-made message (a [String])
  /// is recorded by type only, since its text may come from a server.
  static Future<void> showErrorDialog(
    BuildContext context,
    Object message, {
    String? title,
  }) async {
    DiagnosticsScope.of(context).recordBreadcrumbSync(
      DiagnosticsEvents.uiErrorShown,
      details: message is String
          ? const {'type': 'String'}
          : diagnosticErrorDetails(message),
    );
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
    final confirmed = await showChoiceDialog(
      context,
      title: title,
      message: message,
      confirmText: confirmText,
      isDestructive: isDestructive,
    );
    return confirmed ?? false;
  }

  /// Shows a platform-adaptive two-choice dialog.
  ///
  /// Returns `true` for [confirmText], `false` for [cancelText] (the localized
  /// "Cancel" when omitted), and `null` when the dialog is dismissed without a
  /// choice (back button, or a barrier tap when [barrierDismissible]).
  /// [barrierDismissible] defaults to each platform's own default.
  static Future<bool?> showChoiceDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmText,
    String? cancelText,
    bool isDestructive = false,
    bool? barrierDismissible,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final cancelLabel = cancelText ?? l10n.cancel;

    if (PlatformUtils.isApplePlatform) {
      return showCupertinoDialog<bool>(
        context: context,
        barrierDismissible: barrierDismissible ?? false,
        builder: (context) => CupertinoAlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context, false),
              child: Text(cancelLabel),
            ),
            CupertinoDialogAction(
              isDestructiveAction: isDestructive,
              onPressed: () => Navigator.pop(context, true),
              child: Text(confirmText),
            ),
          ],
        ),
      );
    }
    return showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible ?? true,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelLabel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }
}
