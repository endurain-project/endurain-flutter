import 'package:endurain/core/utils/platform_utils.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

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

  // Guards session-dependent tab content (e.g. Settings' guest/signed-in
  // state): a CupertinoTabView's root route keeps the builder it was created
  // with, so new parent state must still reach the visible tab on rebuild.
  testWidgets('AdaptiveBottomNavigation rebuilds cupertino tabs with new '
      'parent state', (tester) async {
    PlatformUtils.debugIsApplePlatformOverride = true;
    final signedIn = ValueNotifier(false);
    addTearDown(signedIn.dispose);

    await tester.pumpWidget(
      AdaptiveApp(
        title: 'Test',
        home: ValueListenableBuilder<bool>(
          valueListenable: signedIn,
          builder: (context, isSignedIn, _) => AdaptiveBottomNavigation(
            tabs: [
              AdaptiveTab(
                routeName: '/settings',
                label: 'Settings',
                materialIcon: Icons.settings,
                cupertinoIcon: Icons.settings,
                builder: (_) =>
                    Center(child: Text(isSignedIn ? 'Signed in' : 'Guest')),
              ),
              AdaptiveTab(
                routeName: '/map',
                label: 'Map',
                materialIcon: Icons.map,
                cupertinoIcon: Icons.map,
                builder: (_) => const Center(child: Text('Map page')),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Guest'), findsOneWidget);

    signedIn.value = true;
    await tester.pumpAndSettle();

    expect(find.text('Guest'), findsNothing);
    expect(find.text('Signed in'), findsOneWidget);
  });
}
