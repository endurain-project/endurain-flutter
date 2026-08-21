import 'package:endurain/core/utils/platform_utils.dart';
import 'package:endurain/features/activity/widgets/activity_stop_confirmation_dialog.dart';
import 'package:endurain/core/localization/app_locales.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:endurain/l10n/app_localizations_en.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    PlatformUtils.debugIsApplePlatformOverride = false;
  });

  tearDown(PlatformUtils.debugResetOverrides);

  group('showActivityStopConfirmationDialog', () {
    testWidgets('returns cancel without stopping', (tester) async {
      ActivityStopAction? selectedAction;

      await tester.pumpWidget(
        _TestApp(onAction: (action) => selectedAction = action),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppLocalizationsEn().cancel));
      await tester.pumpAndSettle();

      expect(selectedAction, ActivityStopAction.cancel);
    });

    testWidgets('returns stop when stop is selected', (tester) async {
      ActivityStopAction? selectedAction;

      await tester.pumpWidget(
        _TestApp(onAction: (action) => selectedAction = action),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppLocalizationsEn().activityStopAndSave));
      await tester.pumpAndSettle();

      expect(selectedAction, ActivityStopAction.stop);
    });

    testWidgets('requires a second choice before discard', (tester) async {
      ActivityStopAction? selectedAction;

      await tester.pumpWidget(
        _TestApp(onAction: (action) => selectedAction = action),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppLocalizationsEn().activityDiscard).first);
      await tester.pumpAndSettle();

      expect(
        find.text(AppLocalizationsEn().activityDiscardConfirmTitle),
        findsOneWidget,
      );

      await tester.tap(find.text(AppLocalizationsEn().activityDiscard).last);
      await tester.pumpAndSettle();

      expect(selectedAction, ActivityStopAction.discard);
    });

    testWidgets('cancelling the discard confirmation returns cancel', (
      tester,
    ) async {
      ActivityStopAction? selectedAction;

      await tester.pumpWidget(
        _TestApp(onAction: (action) => selectedAction = action),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppLocalizationsEn().activityDiscard).first);
      await tester.pumpAndSettle();

      // Reject the discard in the confirmation dialog.
      await tester.tap(find.text(AppLocalizationsEn().cancel));
      await tester.pumpAndSettle();

      expect(selectedAction, ActivityStopAction.cancel);
    });

    testWidgets('uses Cupertino dialogs and discards on Apple platforms', (
      tester,
    ) async {
      PlatformUtils.debugIsApplePlatformOverride = true;
      ActivityStopAction? selectedAction;

      await tester.pumpWidget(
        _TestApp(onAction: (action) => selectedAction = action),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppLocalizationsEn().activityDiscard).first);
      await tester.pumpAndSettle();

      expect(
        find.text(AppLocalizationsEn().activityDiscardConfirmTitle),
        findsOneWidget,
      );

      await tester.tap(find.text(AppLocalizationsEn().activityDiscard).last);
      await tester.pumpAndSettle();

      expect(selectedAction, ActivityStopAction.discard);
    });

    testWidgets('returns stop from the Cupertino stop dialog', (tester) async {
      PlatformUtils.debugIsApplePlatformOverride = true;
      ActivityStopAction? selectedAction;

      await tester.pumpWidget(
        _TestApp(onAction: (action) => selectedAction = action),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppLocalizationsEn().activityStopAndSave));
      await tester.pumpAndSettle();

      expect(selectedAction, ActivityStopAction.stop);
    });

    testWidgets('cancels the Cupertino stop dialog', (tester) async {
      PlatformUtils.debugIsApplePlatformOverride = true;
      ActivityStopAction? selectedAction;

      await tester.pumpWidget(
        _TestApp(onAction: (action) => selectedAction = action),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppLocalizationsEn().cancel));
      await tester.pumpAndSettle();

      expect(selectedAction, ActivityStopAction.cancel);
    });

    testWidgets('cancels the Cupertino discard confirmation', (tester) async {
      PlatformUtils.debugIsApplePlatformOverride = true;
      ActivityStopAction? selectedAction;

      await tester.pumpWidget(
        _TestApp(onAction: (action) => selectedAction = action),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppLocalizationsEn().activityDiscard).first);
      await tester.pumpAndSettle();

      // Reject the discard in the Cupertino confirmation dialog.
      await tester.tap(find.text(AppLocalizationsEn().cancel));
      await tester.pumpAndSettle();

      expect(selectedAction, ActivityStopAction.cancel);
    });
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.onAction});

  final ValueChanged<ActivityStopAction> onAction;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          return TextButton(
            onPressed: () async {
              onAction(await showActivityStopConfirmationDialog(context));
            },
            child: const Text('open'),
          );
        },
      ),
    );
  }
}
