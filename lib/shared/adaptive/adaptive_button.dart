import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:endurain/core/constants/ui_constants.dart';
import 'package:endurain/core/utils/platform_utils.dart';

enum AdaptiveButtonVariant { primary, secondary }

class AdaptiveButton extends StatelessWidget {
  const AdaptiveButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AdaptiveButtonVariant.primary,
    this.expand = false,
    this.destructive = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final AdaptiveButtonVariant variant;
  final bool expand;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isApplePlatform) {
      final foregroundColor = _cupertinoForegroundColor(context);
      final child = _ButtonContent(
        label: label,
        icon: icon,
        expand: expand,
        foregroundColor: foregroundColor,
      );
      final primaryColor = CupertinoTheme.of(context).primaryColor;
      final button = variant == AdaptiveButtonVariant.primary
          ? CupertinoButton(
              color: destructive ? CupertinoColors.systemRed : primaryColor,
              disabledColor: CupertinoColors.quaternarySystemFill,
              onPressed: onPressed,
              child: child,
            )
          : CupertinoButton(onPressed: onPressed, child: child);

      return expand ? SizedBox(width: double.infinity, child: button) : button;
    }

    final child = _ButtonContent(label: label, icon: icon, expand: expand);
    final colorScheme = Theme.of(context).colorScheme;

    final button = variant == AdaptiveButtonVariant.primary
        ? FilledButton(
            onPressed: onPressed,
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: colorScheme.error,
                    foregroundColor: colorScheme.onError,
                  )
                : null,
            child: Padding(
              padding: const EdgeInsets.all(UIConstants.paddingMedium),
              child: child,
            ),
          )
        : TextButton(
            onPressed: onPressed,
            style: destructive
                ? TextButton.styleFrom(foregroundColor: colorScheme.error)
                : null,
            child: Padding(
              padding: const EdgeInsets.all(UIConstants.paddingMedium),
              child: child,
            ),
          );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }

  Color? _cupertinoForegroundColor(BuildContext context) {
    if (onPressed == null) {
      return CupertinoColors.inactiveGray;
    }

    if (destructive && variant == AdaptiveButtonVariant.primary) {
      return CupertinoColors.white;
    }

    if (variant == AdaptiveButtonVariant.primary) {
      return CupertinoTheme.of(context).brightness == Brightness.dark
          ? const Color(0xFF04342C)
          : CupertinoColors.white;
    }

    if (destructive) {
      return CupertinoColors.systemRed;
    }

    return CupertinoTheme.of(context).primaryColor;
  }
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.label,
    required this.icon,
    required this.expand,
    this.foregroundColor,
  });

  final String label;
  final Widget? icon;
  final bool expand;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (icon == null) {
      content = Text(label, textAlign: TextAlign.center);
    } else {
      content = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: [
          icon!,
          const SizedBox(width: UIConstants.paddingMedium),
          Flexible(child: Text(label, textAlign: TextAlign.center)),
        ],
      );
    }

    if (foregroundColor == null) {
      return content;
    }

    return IconTheme.merge(
      data: IconThemeData(color: foregroundColor),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: foregroundColor),
        child: content,
      ),
    );
  }
}
