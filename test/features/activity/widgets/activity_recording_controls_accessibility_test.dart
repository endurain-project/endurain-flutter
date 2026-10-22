import 'package:endurain/core/localization/app_locales.dart';
import 'package:endurain/core/utils/platform_utils.dart';
import 'package:endurain/features/activity/models/activity_recording_state.dart';
import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/widgets/activity_recording_controls.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// The controls are used one-handed, mid-workout, so every state must keep
/// large tap targets and readable labels.
void main() {
  setUp(() {
    PlatformUtils.debugIsApplePlatformOverride = false;
  });

  tearDown(PlatformUtils.debugResetOverrides);

  final states = <String, ActivityRecordingState>{
    'idle': ActivityRecordingState(),
    'recording': ActivityRecordingState(
      status: ActivityRecordingStatus.recording,
      startedAt: DateTime.utc(2026, 9, 11),
    ),
    'paused': ActivityRecordingState(
      status: ActivityRecordingStatus.paused,
      startedAt: DateTime.utc(2026, 9, 11),
    ),
  };

  for (final entry in states.entries) {
    testWidgets('${entry.key} state meets tap target and label guidelines', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ActivityRecordingControls(
              state: entry.value,
              selectedActivityType: ActivityType.run,
              onActivityTypeChanged: (_) {},
              onStart: (_) {},
              onPause: () {},
              onResume: () {},
              onStop: () {},
            ),
          ),
        ),
      );

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  }
}
