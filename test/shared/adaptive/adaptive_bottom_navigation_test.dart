import 'package:endurain/core/utils/platform_utils.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    PlatformUtils.debugIsApplePlatformOverride = false;
  });

  tearDown(PlatformUtils.debugResetOverrides);

  testWidgets('AdaptiveBottomNavigation switches material tabs', (
    tester,
  ) async {
    await tester.pumpWidget(
      AdaptiveApp(
        title: 'Test',
        home: AdaptiveBottomNavigation(
          tabs: [
            AdaptiveTab(
              routeName: '/map',
              label: 'Map',
              materialIcon: Icons.map,
              cupertinoIcon: Icons.map,
              builder: (_) => const Center(child: Text('Map page')),
            ),
            AdaptiveTab(
              routeName: '/settings',
              label: 'Settings',
              materialIcon: Icons.settings,
              cupertinoIcon: Icons.settings,
              builder: (_) => const Center(child: Text('Settings page')),
            ),
          ],
        ),
      ),
    );

    expect(find.text('Map page'), findsOneWidget);
    expect(find.text('Settings page'), findsNothing);

    await tester.tap(find.text('Settings'));
    await tester.pump();

    expect(find.text('Map page'), findsNothing);
    expect(find.text('Settings page'), findsOneWidget);
  });
}
