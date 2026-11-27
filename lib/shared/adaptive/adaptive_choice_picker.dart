import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:endurain/core/constants/ui_constants.dart';
import 'package:endurain/core/utils/platform_utils.dart';
import 'package:material_ui/material_ui.dart';

/// One selectable entry of [showAdaptiveChoicePicker].
class AdaptiveChoice<T> {
  const AdaptiveChoice({required this.value, required this.label});

  final T value;
  final String label;
}

/// Asks the user to pick one of [choices].
///
/// Renders a Cupertino action sheet on Apple platforms and a Material
/// [SimpleDialog] elsewhere. The entry equal to [selected] is marked with a
/// check mark. Resolves to the picked value, or `null` when dismissed or when
/// the cancel button of the action sheet is used.
Future<T?> showAdaptiveChoicePicker<T>({
  required BuildContext context,
  required String title,
  required List<AdaptiveChoice<T>> choices,
  required String cancelLabel,
  T? selected,
}) {
  if (PlatformUtils.isApplePlatform) {
    return showCupertinoModalPopup<T>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(title),
        actions: [
          for (final choice in choices)
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context, choice.value),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (choice.value == selected) ...[
                    const Icon(CupertinoIcons.check_mark, size: 18),
                    const SizedBox(width: UIConstants.paddingCompact),
                  ],
                  Flexible(child: Text(choice.label)),
                ],
              ),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: Text(cancelLabel),
        ),
      ),
    );
  }
  return showDialog<T>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(title),
      children: [
        for (final choice in choices)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, choice.value),
            child: Row(
              children: [
                Expanded(child: Text(choice.label)),
                if (choice.value == selected) const Icon(Icons.check, size: 18),
              ],
            ),
          ),
      ],
    ),
  );
}
