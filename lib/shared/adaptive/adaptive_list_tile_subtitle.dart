import 'package:flutter/widgets.dart';

/// Vertical padding for a Cupertino tile that has a subtitle. The default
/// `CupertinoListTile` padding is horizontal only, so a wrapped subtitle would
/// otherwise touch the top and bottom edges of the tile.
const EdgeInsetsDirectional adaptiveCupertinoSubtitleTilePadding =
    EdgeInsetsDirectional.fromSTEB(20, 10, 14, 10);

class AdaptiveListTileSubtitle extends StatelessWidget {
  const AdaptiveListTileSubtitle({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final inheritedStyle = DefaultTextStyle.of(context);

    return DefaultTextStyle(
      style: inheritedStyle.style,
      textAlign: inheritedStyle.textAlign,
      softWrap: true,
      overflow: TextOverflow.visible,
      textWidthBasis: inheritedStyle.textWidthBasis,
      textHeightBehavior: inheritedStyle.textHeightBehavior,
      child: child,
    );
  }
}
