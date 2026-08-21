import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:endurain/core/constants/ui_constants.dart';
import 'package:endurain/core/utils/platform_utils.dart';

class AdaptiveListSection extends StatelessWidget {
  const AdaptiveListSection({super.key, this.header, required this.children});

  final String? header;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isApplePlatform) {
      final section = CupertinoListSection.insetGrouped(
        margin: EdgeInsets.zero,
        // The section paints this color across its full bounds, behind the
        // inset rounded card. Left opaque (the default is an opaque grouped
        // background that is pure black in dark mode) it shows through the
        // square area outside the card's corner radius as black "tips". Make
        // it transparent so the scaffold background shows through instead.
        backgroundColor: CupertinoColors.transparent,
        children: children,
      );

      if (header == null) {
        return section;
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: UIConstants.paddingSmall),
            child: Text(
              header!,
              style: CupertinoTheme.of(context).textTheme.textStyle
                  .copyWith(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          section,
        ],
      );
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                UIConstants.paddingStandard,
                UIConstants.paddingMedium,
                UIConstants.paddingStandard,
                UIConstants.paddingSmall,
              ),
              child: Text(
                header!,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ...children,
        ],
      ),
    );
  }
}
