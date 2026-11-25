import 'dart:math' as math;

import 'package:endurain/core/constants/ui_constants.dart';
import 'package:flutter/widgets.dart';

/// Padding for a screen's scrolling content that keeps it at most
/// [UIConstants.readableContentMaxWidth] wide and centred.
///
/// Use it as the `padding` of the scroll view itself rather than constraining
/// the scroll view, so a wide window (an unfolded iPhone Duo, a tablet,
/// landscape) still scrolls when dragged in the side margins.
///
/// The width comes from the nearest [ReadableWidthScope], or else from the
/// window, which is right for a screen that fills it.
EdgeInsets readableContentPadding(
  BuildContext context, {
  double padding = UIConstants.paddingStandard,
}) {
  final width =
      ReadableWidthScope.maybeWidthOf(context) ??
      MediaQuery.sizeOf(context).width;
  return readableContentPaddingFor(width, padding: padding);
}

/// [readableContentPadding] for content laid out in [width].
EdgeInsets readableContentPaddingFor(
  double width, {
  double padding = UIConstants.paddingStandard,
}) {
  final side = math.max(
    padding,
    (width - UIConstants.readableContentMaxWidth) / 2,
  );
  return EdgeInsets.symmetric(horizontal: side, vertical: padding);
}

/// Tells [readableContentPadding] below it how wide its area is, for content
/// that shares the window with something else, such as one pane of a
/// side-by-side layout.
class ReadableWidthScope extends StatelessWidget {
  const ReadableWidthScope({super.key, required this.child});

  final Widget child;

  static double? maybeWidthOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ReadableWidthData>()?.width;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) =>
          _ReadableWidthData(width: constraints.maxWidth, child: child),
    );
  }
}

class _ReadableWidthData extends InheritedWidget {
  const _ReadableWidthData({required this.width, required super.child});

  final double width;

  @override
  bool updateShouldNotify(_ReadableWidthData oldWidget) =>
      width != oldWidget.width;
}
