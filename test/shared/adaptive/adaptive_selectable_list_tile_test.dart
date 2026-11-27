import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:endurain/core/utils/platform_utils.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  tearDown(PlatformUtils.debugResetOverrides);

  Future<void> pump(WidgetTester tester, {required bool selected}) {
    return tester.pumpWidget(
      AdaptiveApp(
        title: 'Test',
        home: Scaffold(
          body: AdaptiveSelectableListTile(
            title: 'Metric',
            selected: selected,
            onTap: () {},
          ),
        ),
      ),
    );
  }

  testWidgets('shows a check only when selected', (tester) async {
    PlatformUtils.debugIsApplePlatformOverride = false;
    await pump(tester, selected: true);
    expect(find.byIcon(Icons.check), findsOneWidget);

    await pump(tester, selected: false);
    expect(find.byIcon(Icons.check), findsNothing);
  });

  testWidgets('exposes the selected state to semantics', (tester) async {
    PlatformUtils.debugIsApplePlatformOverride = false;
    final handle = tester.ensureSemantics();
    await pump(tester, selected: true);

    expect(
      tester.getSemantics(find.byType(AdaptiveSelectableListTile)),
      isSemantics(isSelected: true, hasSelectedState: true),
    );
    handle.dispose();
  });

  testWidgets('has no chevron on unselected Apple rows', (tester) async {
    PlatformUtils.debugIsApplePlatformOverride = true;
    await pump(tester, selected: false);

    expect(find.byType(CupertinoListTileChevron), findsNothing);
  });
}
