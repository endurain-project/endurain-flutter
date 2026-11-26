import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:endurain/core/diagnostics/diagnostics_scope.dart';
import 'package:endurain/core/diagnostics/diagnostics_service.dart';
import 'package:endurain/core/utils/error_localizations.dart';
import 'package:endurain/core/utils/platform_utils.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// One button of a dialog shown by [DialogUtils.showActionDialog].
class DialogChoice<T> {
  const DialogChoice({
    required this.label,
    required this.value,
    this.isDestructive = false,
  });

  final String label;

  /// What the dialog resolves with when this button is pressed.
  final T value;

  /// Styled as a destructive action (red on Apple, the error colour on Material).
  final bool isDestructive;
}

/// Utility class for showing platform-adaptive dialogs
class DialogUtils {
  /// The single place that branches between Cupertino and Material alerts.
  ///
  /// Every other dialog here is built on it so they stay visually consistent.
  /// A button with a `null` value pops without a result.
  static Future<T?> _showAdaptiveAlert<T>(
    BuildContext context, {
    String? title,
    required Widget content,
    required List<DialogChoice<T?>> choices,
    bool? barrierDismissible,
  }) {
    if (PlatformUtils.isApplePlatform) {
      return showCupertinoDialog<T>(
        context: context,
        barrierDismissible: barrierDismissible ?? false,
        builder: (context) => CupertinoAlertDialog(
          title: title == null ? null : Text(title),
          content: content,
          actions: [
            for (final choice in choices)
              CupertinoDialogAction(
                isDestructiveAction: choice.isDestructive,
                onPressed: () => Navigator.pop(context, choice.value),
                child: Text(choice.label),
              ),
          ],
        ),
      );
    }
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible ?? true,
      builder: (context) => AlertDialog(
        title: title == null ? null : Text(title),
        content: content,
        actions: [
          for (final choice in choices)
            TextButton(
              style: choice.isDestructive
                  ? TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    )
                  : null,
              onPressed: () => Navigator.pop(context, choice.value),
              child: Text(choice.label),
            ),
        ],
      ),
    );
  }

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

    await _showAdaptiveAlert<void>(
      context,
      title: title ?? l10n.error,
      content: SelectableText(localizedErrorMessage(message, l10n)),
      choices: [DialogChoice(label: l10n.ok, value: null)],
    );
  }

  /// Show a success dialog with platform-adaptive UI
  static Future<void> showSuccessDialog(
    BuildContext context,
    String message, {
    VoidCallback? onDismiss,
  }) async {
    final l10n = AppLocalizations.of(context)!;

    if (PlatformUtils.isApplePlatform) {
      await _showAdaptiveAlert<void>(
        context,
        content: Text(message),
        choices: [DialogChoice(label: l10n.ok, value: null)],
      );
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
    onDismiss?.call();
  }

  /// Show a short platform-adaptive message.
  static Future<void> showMessage(BuildContext context, String message) async {
    final l10n = AppLocalizations.of(context)!;

    if (PlatformUtils.isApplePlatform) {
      await _showAdaptiveAlert<void>(
        context,
        content: Text(message),
        choices: [DialogChoice(label: l10n.ok, value: null)],
        barrierDismissible: true,
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
    return showActionDialog<bool>(
      context,
      title: title,
      message: message,
      choices: [
        DialogChoice(
          label: cancelText ?? AppLocalizations.of(context)!.cancel,
          value: false,
        ),
        DialogChoice(
          label: confirmText,
          value: true,
          isDestructive: isDestructive,
        ),
      ],
      barrierDismissible: barrierDismissible,
    );
  }

  /// Shows a platform-adaptive dialog with any number of [choices], shown in
  /// the given order, and resolves with the pressed choice's value (`null`
  /// when dismissed without one).
  static Future<T?> showActionDialog<T>(
    BuildContext context, {
    required String title,
    required String message,
    required List<DialogChoice<T>> choices,
    bool? barrierDismissible,
  }) {
    return _showAdaptiveAlert<T>(
      context,
      title: title,
      content: Text(message),
      choices: [
        for (final choice in choices)
          DialogChoice<T?>(
            label: choice.label,
            value: choice.value,
            isDestructive: choice.isDestructive,
          ),
      ],
      barrierDismissible: barrierDismissible,
    );
  }
}
