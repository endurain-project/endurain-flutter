import 'package:endurain/core/constants/ui_constants.dart';
import 'package:endurain/core/utils/platform_utils.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';

class AdaptiveEmptyStateText extends StatelessWidget {
  const AdaptiveEmptyStateText({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final style = PlatformUtils.isApplePlatform
        ? CupertinoTheme.of(context).textTheme.textStyle
              .copyWith(color: CupertinoColors.label.resolveFrom(context))
        : Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: Theme.of(context).colorScheme.onSurface);

    return Padding(
      padding: const EdgeInsets.all(UIConstants.paddingStandard),
      child: Text(message, textAlign: TextAlign.center, style: style),
    );
  }
}
