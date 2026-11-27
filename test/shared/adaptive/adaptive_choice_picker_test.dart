import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:endurain/core/utils/platform_utils.dart';
import 'package:endurain/shared/adaptive/adaptive_choice_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  setUp(PlatformUtils.debugResetOverrides);
  tearDown(PlatformUtils.debugResetOverrides);

  late Future<String?> result;

  Future<void> open(WidgetTester tester, {String? selected = 'b'}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () {
              result = showAdaptiveChoicePicker<String>(
                context: context,
                title: 'Pick one',
                cancelLabel: 'Dismiss',
                selected: selected,
                choices: const [
                  AdaptiveChoice(value: 'a', label: 'Alpha'),
                  AdaptiveChoice(value: 'b', label: 'Beta'),
                ],
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  group('Material', () {
    setUp(() => PlatformUtils.debugIsApplePlatformOverride = false);

    testWidgets('shows a dialog and returns the tapped value', (tester) async {
      await open(tester);

      expect(find.byType(SimpleDialog), findsOneWidget);
      expect(find.text('Pick one'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);

      await tester.tap(find.text('Alpha'));
      await tester.pumpAndSettle();

      expect(await result, 'a');
    });

    testWidgets('marks nothing when no entry is selected', (tester) async {
      await open(tester, selected: null);

      expect(find.byIcon(Icons.check), findsNothing);
    });

    testWidgets('returns null when dismissed', (tester) async {
      await open(tester);

      await tester.tapAt(const Offset(2, 2));
      await tester.pumpAndSettle();

      expect(await result, isNull);
    });
  });

  group('Cupertino', () {
    setUp(() => PlatformUtils.debugIsApplePlatformOverride = true);

    testWidgets('shows an action sheet and returns the tapped value', (
      tester,
    ) async {
      await open(tester);

      expect(find.byType(CupertinoActionSheet), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.check_mark), findsOneWidget);

      await tester.tap(find.text('Beta'));
      await tester.pumpAndSettle();

      expect(await result, 'b');
    });

    testWidgets('cancel resolves to null', (tester) async {
      await open(tester);

      await tester.tap(find.text('Dismiss'));
      await tester.pumpAndSettle();

      expect(await result, isNull);
    });
  });
}
