import 'package:flutter/widgets.dart';

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
