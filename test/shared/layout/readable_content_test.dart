import 'package:endurain/core/constants/ui_constants.dart';
import 'package:endurain/shared/layout/readable_content.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const padding = UIConstants.paddingStandard;
  const maxWidth = UIConstants.readableContentMaxWidth;

  group('readableContentPaddingFor', () {
    test('uses the plain padding when the content fits', () {
      expect(readableContentPaddingFor(390), const EdgeInsets.all(padding));
    });

    test('centres content no wider than the readable width', () {
      final insets = readableContentPaddingFor(951);

      expect(insets.left, insets.right);
      expect(951 - insets.horizontal, maxWidth);
      expect(insets.top, padding);
      expect(insets.bottom, padding);
    });

    test('never goes below the plain padding', () {
      final insets = readableContentPaddingFor(maxWidth + 10);

      expect(insets.left, padding);
      expect(insets.right, padding);
    });
  });

  group('readableContentPadding', () {
    Future<EdgeInsets> paddingIn(
      WidgetTester tester, {
      required Widget Function(Widget probe) wrap,
    }) async {
      late EdgeInsets result;
      final probe = Builder(
        builder: (context) {
          result = readableContentPadding(context);
          return const SizedBox.shrink();
        },
      );
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(951, 669)),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: wrap(probe),
          ),
        ),
      );
      return result;
    }

    testWidgets('uses the window width without a scope', (tester) async {
      final insets = await paddingIn(tester, wrap: (probe) => probe);

      expect(insets, readableContentPaddingFor(951));
    });

    testWidgets('uses the scope width inside a narrower pane', (tester) async {
      final insets = await paddingIn(
        tester,
        wrap: (probe) => Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: 360, child: ReadableWidthScope(child: probe)),
        ),
      );

      expect(insets, const EdgeInsets.all(padding));
    });
  });
}
