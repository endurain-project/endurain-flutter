import 'package:endurain/core/theme/app_theme.dart';
import 'package:endurain/core/utils/platform_utils.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => PlatformUtils.debugIsApplePlatformOverride = true);
  tearDown(PlatformUtils.debugResetOverrides);

  testWidgets('Cupertino segment labels use dynamic readable label color', (
    tester,
  ) async {
    await tester.pumpWidget(
      CupertinoApp(
        theme: AppTheme.cupertinoDarkTheme,
        home: const CupertinoPageScaffold(
          child: AdaptiveSegmentedControl<int>(
            labels: {0: 'Available', 1: 'Imported'},
            selected: 0,
            onChanged: _ignoreInt,
          ),
        ),
      ),
    );

    final text = tester.widget<Text>(find.text('Available'));
    expect(
      text.style?.color,
      CupertinoColors.label.resolveFrom(
        tester.element(find.byType(AdaptiveSegmentedControl<int>)),
      ),
    );
  });

  testWidgets('Cupertino selectable row uses a trailing checkmark', (
    tester,
  ) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          child: AdaptiveCheckboxListTile(
            value: true,
            title: const Text('Workout'),
            onChanged: (_) {},
          ),
        ),
      ),
    );

    expect(find.byType(CupertinoCheckbox), findsNothing);
    expect(find.byIcon(CupertinoIcons.check_mark), findsOneWidget);
    expect(find.byType(MergeSemantics), findsOneWidget);
  });

  testWidgets('unavailable Cupertino row has no selection control', (
    tester,
  ) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: CupertinoPageScaffold(
          child: AdaptiveCheckboxListTile(
            value: false,
            title: Text('Workout'),
            showControl: false,
          ),
        ),
      ),
    );

    expect(find.byType(CupertinoCheckbox), findsNothing);
  });

  testWidgets('Cupertino switch row can be disabled', (tester) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: CupertinoPageScaffold(
          child: AdaptiveSwitchListTile(
            title: 'Auto-sync',
            value: true,
            onChanged: null,
          ),
        ),
      ),
    );

    final toggle = tester.widget<CupertinoSwitch>(find.byType(CupertinoSwitch));
    expect(toggle.onChanged, isNull);
    expect(find.byType(MergeSemantics), findsOneWidget);
  });
}

void _ignoreInt(int value) {}
