import 'package:flutter_test/flutter_test.dart';
import 'package:endurain/core/utils/platform_utils.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';

void main() {
  setUp(() {
    PlatformUtils.debugResetOverrides();
  });

  tearDown(() {
    PlatformUtils.debugResetOverrides();
  });

  testWidgets('AdaptiveButton renders label and handles taps', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      AdaptiveApp(
        title: 'Test',
        home: AdaptiveButton(
          label: 'Save',
          onPressed: () {
            tapped = true;
          },
        ),
      ),
    );

    expect(find.text('Save'), findsOneWidget);

    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('renders Material FilledButton for primary variant', (
    tester,
  ) async {
    PlatformUtils.debugIsApplePlatformOverride = false;

    await tester.pumpWidget(
      AdaptiveApp(
        title: 'Test',
        home: AdaptiveButton(label: 'Save', onPressed: () {}),
      ),
    );

    expect(find.byType(FilledButton), findsOneWidget);
    expect(find.byType(TextButton), findsNothing);
  });

  testWidgets('renders Material TextButton for secondary variant', (
    tester,
  ) async {
    PlatformUtils.debugIsApplePlatformOverride = false;

    await tester.pumpWidget(
      AdaptiveApp(
        title: 'Test',
        home: AdaptiveButton(
          label: 'Cancel',
          variant: AdaptiveButtonVariant.secondary,
          onPressed: () {},
        ),
      ),
    );

    expect(find.byType(TextButton), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('renders CupertinoButton for Apple platform', (tester) async {
    PlatformUtils.debugIsApplePlatformOverride = true;

    await tester.pumpWidget(
      AdaptiveApp(
        title: 'Test',
        home: AdaptiveButton(label: 'Continue', onPressed: () {}),
      ),
    );

    expect(find.byType(CupertinoButton), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
    expect(find.byType(TextButton), findsNothing);
  });

  testWidgets('Apple primary destructive button uses system red background', (
    tester,
  ) async {
    PlatformUtils.debugIsApplePlatformOverride = true;

    await tester.pumpWidget(
      const AdaptiveApp(
        title: 'Test',
        home: AdaptiveButton(
          label: 'Delete',
          destructive: true,
          onPressed: null,
        ),
      ),
    );

    final button = tester.widget<CupertinoButton>(find.byType(CupertinoButton));
    expect(button.color, CupertinoColors.systemRed);
  });

  testWidgets('dark Apple destructive primary keeps white foreground', (
    tester,
  ) async {
    PlatformUtils.debugIsApplePlatformOverride = true;
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await tester.pumpWidget(
      AdaptiveApp(
        title: 'Test',
        home: AdaptiveButton(
          label: 'Delete',
          destructive: true,
          onPressed: () {},
        ),
      ),
    );

    final textContext = tester.element(find.text('Delete'));
    expect(DefaultTextStyle.of(textContext).style.color, CupertinoColors.white);
  });

  testWidgets('expand wraps button in full-width SizedBox', (tester) async {
    PlatformUtils.debugIsApplePlatformOverride = false;

    await tester.pumpWidget(
      const AdaptiveApp(
        title: 'Test',
        home: Center(
          child: AdaptiveButton(label: 'Wide', onPressed: null, expand: true),
        ),
      ),
    );

    final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
    expect(sizedBoxes.any((box) => box.width == double.infinity), isTrue);
  });

  testWidgets('disabled Cupertino primary button uses quaternary fill', (
    tester,
  ) async {
    PlatformUtils.debugIsApplePlatformOverride = true;

    await tester.pumpWidget(
      const AdaptiveApp(
        title: 'Test',
        home: AdaptiveButton(label: 'Disabled', onPressed: null),
      ),
    );

    final button = tester.widget<CupertinoButton>(find.byType(CupertinoButton));
    expect(button.disabledColor, CupertinoColors.quaternarySystemFill);
  });
}
