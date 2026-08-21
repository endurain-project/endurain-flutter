import 'package:endurain/core/utils/platform_utils.dart';
import 'package:endurain/shared/adaptive/adaptive_navigation.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(PlatformUtils.debugResetOverrides);

  Future<void> pumpAndPush(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => adaptivePush<void>(
                  context,
                  (context) =>
                      const Scaffold(body: Center(child: Text('pushed'))),
                ),
                child: const Text('push'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('push'));
    await tester.pumpAndSettle();
  }

  testWidgets('uses a Cupertino route on Apple platforms', (tester) async {
    PlatformUtils.debugIsApplePlatformOverride = true;

    await pumpAndPush(tester);

    expect(find.text('pushed'), findsOneWidget);
    final route = ModalRoute.of(tester.element(find.text('pushed')));
    expect(route, isA<CupertinoPageRoute<void>>());
  });

  testWidgets('uses a Material route on non-Apple platforms', (tester) async {
    PlatformUtils.debugIsApplePlatformOverride = false;

    await pumpAndPush(tester);

    expect(find.text('pushed'), findsOneWidget);
    final route = ModalRoute.of(tester.element(find.text('pushed')));
    expect(route, isA<MaterialPageRoute<void>>());
  });
}
