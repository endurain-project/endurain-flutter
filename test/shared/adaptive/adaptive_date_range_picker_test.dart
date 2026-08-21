import 'package:endurain/core/utils/platform_utils.dart';
import 'package:endurain/shared/adaptive/adaptive_date_range_picker.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => PlatformUtils.debugResetOverrides());
  tearDown(PlatformUtils.debugResetOverrides);

  testWidgets('shows and cancels the Material date range picker', (
    tester,
  ) async {
    PlatformUtils.debugIsApplePlatformOverride = false;
    late Future<DateTimeRange?> selection;
    late BuildContext homeContext;

    await tester.pumpWidget(
      _PickerTestApp(
        onPressed: (context) {
          homeContext = context;
          selection = showAdaptiveDateRangePicker(
            context: context,
            initialStart: DateTime(2026, 7, 1),
            initialEnd: DateTime(2026, 7, 10),
            firstDate: DateTime(2026),
            lastDate: DateTime(2026, 12, 31),
            startLabel: 'Start',
            endLabel: 'End',
            cancelLabel: 'Dismiss',
            confirmLabel: 'Apply',
          );
        },
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Start - End'), findsOneWidget);
    Navigator.of(homeContext, rootNavigator: true).pop();
    await tester.pumpAndSettle();

    expect(await selection, isNull);
  });

  testWidgets('shows and confirms the Cupertino date range picker', (
    tester,
  ) async {
    PlatformUtils.debugIsApplePlatformOverride = true;
    late Future<DateTimeRange?> selection;

    await tester.pumpWidget(
      _PickerTestApp(
        onPressed: (context) {
          selection = showAdaptiveDateRangePicker(
            context: context,
            initialStart: DateTime(2026, 7, 1),
            initialEnd: DateTime(2026, 7, 10),
            firstDate: DateTime(2026),
            lastDate: DateTime(2026, 12, 31),
            startLabel: 'Start',
            endLabel: 'End',
            cancelLabel: 'Dismiss',
            confirmLabel: 'Apply',
          );
        },
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byType(CupertinoDatePicker), findsNWidgets(2));
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(
      await selection,
      DateTimeRange(start: DateTime(2026, 7, 1), end: DateTime(2026, 7, 10)),
    );
  });
}

class _PickerTestApp extends StatelessWidget {
  const _PickerTestApp({required this.onPressed});

  final void Function(BuildContext context) onPressed;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () => onPressed(context),
            child: const Text('Open'),
          ),
        ),
      ),
    );
  }
}
