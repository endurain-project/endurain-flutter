import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/services/start_countdown.dart';
import 'package:endurain/features/activity/widgets/start_countdown_dialog.dart';
import 'package:endurain/l10n/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/widget_test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final l10n = AppLocalizationsEn();

  Future<List<StartCountdownOutcome>> pumpLauncher(
    WidgetTester tester, {
    int seconds = 5,
  }) async {
    final outcomes = <StartCountdownOutcome>[];
    await tester.pumpWidget(
      TestMaterialApp(
        child: Builder(
          builder: (context) => TextButton(
            onPressed: () async => outcomes.add(
              await showStartCountdownDialog(
                context,
                seconds: seconds,
                activityType: ActivityType.ride,
                now: tester.binding.clock.now,
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    return outcomes;
  }

  String remaining(WidgetTester tester) => tester
      .widget<Text>(find.byKey(const ValueKey('startCountdownRemaining')))
      .data!;

  testWidgets('counts down and closes with start at zero', (tester) async {
    final outcomes = await pumpLauncher(tester, seconds: 3);

    expect(find.text(l10n.activityTypeRide), findsOneWidget);
    expect(find.text(l10n.activityStartCountdownTitle), findsOneWidget);
    expect(remaining(tester), '3');

    await tester.pump(const Duration(seconds: 1));
    expect(remaining(tester), '2');

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(outcomes, [StartCountdownOutcome.start]);
    expect(find.byKey(const ValueKey('startCountdownRemaining')), findsNothing);
  });

  testWidgets('adds ten seconds', (tester) async {
    await pumpLauncher(tester, seconds: 5);

    await tester.tap(find.byKey(const ValueKey('startCountdownAddTime')));
    await tester.pump();

    expect(remaining(tester), '15');
    expect(find.text(l10n.activityStartCountdownAddSeconds(10)), findsOne);

    await tester.tap(find.byKey(const ValueKey('startCountdownCancel')));
    await tester.pumpAndSettle();
  });

  testWidgets('start now closes with start', (tester) async {
    final outcomes = await pumpLauncher(tester);

    await tester.tap(find.byKey(const ValueKey('startCountdownStartNow')));
    await tester.pumpAndSettle();

    expect(outcomes, [StartCountdownOutcome.start]);
  });

  testWidgets('cancel and back both close with cancel', (tester) async {
    final outcomes = await pumpLauncher(tester);

    await tester.tap(find.byKey(const ValueKey('startCountdownCancel')));
    await tester.pumpAndSettle();
    expect(outcomes, [StartCountdownOutcome.cancel]);

    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(outcomes, [
      StartCountdownOutcome.cancel,
      StartCountdownOutcome.cancel,
    ]);
  });

  testWidgets('announces the seconds left to screen readers', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpLauncher(tester, seconds: 7);

    expect(
      find.bySemanticsLabel(l10n.activityStartCountdownRemaining(7)),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('startCountdownCancel')));
    await tester.pumpAndSettle();
    semantics.dispose();
  });
}
