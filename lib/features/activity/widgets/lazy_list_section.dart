import 'package:endurain/core/constants/ui_constants.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:material_ui/material_ui.dart';

/// A sliver version of [AdaptiveListSection] that builds its rows lazily.
///
/// A grouped section paints its rows inside one card, which a sliver cannot do
/// row by row, so rows are grouped into cards of [chunkSize] and only the
/// cards that scroll near the viewport are built. The [header] is shown on the
/// first card only. Rows from `itemBuilder` must not depend on their siblings.
class LazyListSection extends StatelessWidget {
  const LazyListSection({
    super.key,
    this.header,
    required this.itemCount,
    required this.itemBuilder,
    this.chunkSize = 20,
  }) : assert(chunkSize > 0);

  final String? header;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final int chunkSize;

  @override
  Widget build(BuildContext context) {
    final chunkCount = (itemCount + chunkSize - 1) ~/ chunkSize;
    return SliverList.builder(
      itemCount: chunkCount,
      itemBuilder: (context, chunk) {
        final start = chunk * chunkSize;
        final end = start + chunkSize < itemCount
            ? start + chunkSize
            : itemCount;
        return Padding(
          padding: EdgeInsets.only(
            bottom: chunk < chunkCount - 1 ? UIConstants.paddingSmall : 0,
          ),
          child: AdaptiveListSection(
            header: chunk == 0 ? header : null,
            children: [
              for (var index = start; index < end; index++)
                itemBuilder(context, index),
            ],
          ),
        );
      },
    );
  }
}

/// Wraps [slivers] so they share [padding], as one `SliverPadding` around a
/// sliver group would, but as separate top-level slivers.
///
/// Keeping them as separate top-level slivers lets each lazy list build only
/// what is near the viewport.
List<Widget> paddedSlivers(EdgeInsets padding, List<Widget> slivers) {
  final side = EdgeInsets.symmetric(horizontal: padding.horizontal / 2);
  return [
    SliverToBoxAdapter(child: SizedBox(height: padding.top)),
    for (final sliver in slivers) SliverPadding(padding: side, sliver: sliver),
    SliverToBoxAdapter(child: SizedBox(height: padding.bottom)),
  ];
}
