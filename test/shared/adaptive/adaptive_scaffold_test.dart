// Regression coverage for Android 15 (API 35) edge-to-edge enforcement.
//
// Flutter apps targeting SDK 35+ opt into edge-to-edge automatically (Flutter
// 3.27+), so the framework already calls the platform equivalent of
// `enableEdgeToEdge()`. What remains our responsibility is making sure the
// shared scaffold used by every screen keeps content clear of the transparent
// status bar / gesture navigation bar, and that immersive screens (which opt
// out of the automatic SafeArea) still keep interactive controls reachable.
import 'package:endurain/core/constants/map_constants.dart';
import 'package:endurain/core/utils/platform_utils.dart';
import 'package:endurain/shared/adaptive/adaptive_scaffold.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    PlatformUtils.debugIsApplePlatformOverride = false;
  });

  tearDown(PlatformUtils.debugResetOverrides);

  const topInset = 40.0; // status bar
  const bottomInset = 34.0; // gesture navigation bar / home indicator

  Widget withEdgeToEdgeInsets(Widget child) {
    return MaterialApp(
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: const EdgeInsets.only(top: topInset, bottom: bottomInset),
            viewPadding: const EdgeInsets.only(
              top: topInset,
              bottom: bottomInset,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  testWidgets(
    'safeArea (default) keeps the body clear of the system bar insets',
    (tester) async {
      await tester.pumpWidget(
        withEdgeToEdgeInsets(
          const AdaptiveScaffold(body: SizedBox.expand(key: ValueKey('body'))),
        ),
      );

      final rect = tester.getRect(find.byKey(const ValueKey('body')));
      final screenHeight =
          tester.view.physicalSize.height / tester.view.devicePixelRatio;

      expect(rect.top, topInset);
      expect(rect.bottom, moreOrLessEquals(screenHeight - bottomInset));
    },
  );

  testWidgets(
    'safeArea: false lets immersive screens (e.g. the map) draw edge-to-edge',
    (tester) async {
      await tester.pumpWidget(
        withEdgeToEdgeInsets(
          const AdaptiveScaffold(
            safeArea: false,
            body: SizedBox.expand(key: ValueKey('body')),
          ),
        ),
      );

      final rect = tester.getRect(find.byKey(const ValueKey('body')));
      final screenHeight =
          tester.view.physicalSize.height / tester.view.devicePixelRatio;

      expect(rect.top, 0);
      expect(rect.bottom, moreOrLessEquals(screenHeight));
    },
  );

  testWidgets(
    'keeps the floating action button reachable within the safe area even '
    'when the body is edge-to-edge',
    (tester) async {
      await tester.pumpWidget(
        withEdgeToEdgeInsets(
          AdaptiveScaffold(
            safeArea: false,
            body: const SizedBox.expand(),
            floatingActionButton: ElevatedButton(
              key: const ValueKey('fab'),
              onPressed: () {},
              child: const Text('fab'),
            ),
          ),
        ),
      );

      final rect = tester.getRect(find.byKey(const ValueKey('fab')));
      final screenHeight =
          tester.view.physicalSize.height / tester.view.devicePixelRatio;

      // The button must never sit under the (transparent) gesture nav bar.
      expect(
        rect.bottom,
        moreOrLessEquals(
          screenHeight -
              bottomInset -
              LocationMarkerConstants.buttonOuterPadding,
        ),
      );
    },
  );
}
