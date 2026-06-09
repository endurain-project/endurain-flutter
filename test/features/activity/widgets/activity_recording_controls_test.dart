import 'package:endurain/features/activity/models/activity_recording_error.dart';
import 'package:endurain/core/constants/map_constants.dart';
import 'package:endurain/core/utils/platform_utils.dart';
import 'package:endurain/features/activity/models/activity_recording_state.dart';
import 'package:endurain/features/activity/models/activity_upload_state.dart';
import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/widgets/activity_recording_controls.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:endurain/l10n/app_localizations_en.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ActivityRecordingControls', () {
    setUp(() {
      PlatformUtils.debugIsApplePlatformOverride = false;
    });

    tearDown(PlatformUtils.debugResetOverrides);

    testWidgets('shows start action when idle', (tester) async {
      ActivityType? startedType;

      await tester.pumpWidget(
        _TestApp(
          child: ActivityRecordingControls(
            state: ActivityRecordingState(),
            selectedActivityType: ActivityType.run,
            onActivityTypeChanged: (_) {},
            onStart: (type) => startedType = type,
            onPause: null,
            onResume: null,
            onStop: null,
          ),
        ),
      );

      expect(
        find.byTooltip(AppLocalizationsEn().activityStart),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip(AppLocalizationsEn().activityStart));

      expect(startedType, ActivityType.run);
    });

    testWidgets('places start action beside picker with matching height', (
      tester,
    ) async {
      await tester.pumpWidget(
        _TestApp(
          child: SizedBox(
            width: 390,
            height: 600,
            child: ActivityRecordingControls(
              state: ActivityRecordingState(),
              selectedActivityType: ActivityType.run,
              onActivityTypeChanged: (_) {},
              onStart: (_) {},
              onPause: null,
              onResume: null,
              onStop: null,
            ),
          ),
        ),
      );

      final pickerRect = tester.getRect(
        find.byKey(const ValueKey('activityTypePickerMaterialField')),
      );
      final startRect = tester.getRect(
        find.byKey(const ValueKey('activityStartButton')),
      );

      expect(startRect.left, greaterThan(pickerRect.right));
      expect(startRect.width, startRect.height);
      expect(startRect.height, pickerRect.height);
    });

    testWidgets('shows activity type picker before start', (tester) async {
      ActivityType? selectedType;

      await tester.pumpWidget(
        _TestApp(
          child: ActivityRecordingControls(
            state: ActivityRecordingState(),
            selectedActivityType: ActivityType.run,
            onActivityTypeChanged: (type) => selectedType = type,
            onStart: (_) {},
            onPause: null,
            onResume: null,
            onStop: null,
          ),
        ),
      );

      expect(find.text(AppLocalizationsEn().activityTypeLabel), findsOneWidget);
      expect(find.text(AppLocalizationsEn().activityTypeRun), findsOneWidget);

      await tester.tap(find.text(AppLocalizationsEn().activityTypeRun));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppLocalizationsEn().activityTypeRide).last);
      await tester.pumpAndSettle();

      expect(selectedType, ActivityType.ride);
    });

    testWidgets('builds in a Cupertino app without a Material ancestor', (
      tester,
    ) async {
      PlatformUtils.debugIsApplePlatformOverride = true;

      await tester.pumpWidget(
        CupertinoApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SizedBox(
            width: 390,
            height: 600,
            child: ActivityRecordingControls(
              state: ActivityRecordingState(),
              selectedActivityType: ActivityType.run,
              onActivityTypeChanged: (_) {},
              onStart: (_) {},
              onPause: null,
              onResume: null,
              onStop: null,
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(
        find.byTooltip(AppLocalizationsEn().activityStart),
        findsOneWidget,
      );
      expect(
        tester.widget<Icon>(find.byIcon(CupertinoIcons.play_arrow)).color,
        CupertinoColors.white,
      );
    });

    testWidgets('reserves trailing space for map floating controls', (
      tester,
    ) async {
      const floatingButtonKey = ValueKey('mapFloatingButton');
      const floatingButtonBottom = LocationMarkerConstants.buttonOuterPadding;

      await tester.pumpWidget(
        _TestApp(
          child: SizedBox(
            width: 390,
            height: 600,
            child: Stack(
              children: [
                ActivityRecordingControls(
                  state: ActivityRecordingState(),
                  selectedActivityType: ActivityType.run,
                  trailingReservedWidth: 88,
                  onActivityTypeChanged: (_) {},
                  onStart: (_) {},
                  onPause: null,
                  onResume: null,
                  onStop: null,
                ),
                const Positioned(
                  right: 0,
                  bottom: floatingButtonBottom,
                  child: SizedBox(
                    key: floatingButtonKey,
                    width: 56,
                    height: 56,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final controlsRect = tester.getRect(
        find.byKey(const ValueKey('activityRecordingControlsSurface')),
      );
      final floatingButtonRect = tester.getRect(find.byKey(floatingButtonKey));

      expect(controlsRect.right, lessThanOrEqualTo(floatingButtonRect.left));
      expect(controlsRect.bottom, floatingButtonRect.bottom);
    });

    testWidgets('shows pause and stop while recording', (tester) async {
      await tester.pumpWidget(
        _TestApp(
          child: ActivityRecordingControls(
            state: ActivityRecordingState(
              status: ActivityRecordingStatus.recording,
            ),
            selectedActivityType: ActivityType.run,
            onActivityTypeChanged: null,
            onStart: null,
            onPause: () {},
            onResume: null,
            onStop: () {},
          ),
        ),
      );

      expect(find.text(AppLocalizationsEn().activityPause), findsOneWidget);
      expect(find.text(AppLocalizationsEn().activityStop), findsOneWidget);
    });

    testWidgets('shows resume and stop while paused', (tester) async {
      await tester.pumpWidget(
        _TestApp(
          child: ActivityRecordingControls(
            state: ActivityRecordingState(
              status: ActivityRecordingStatus.paused,
            ),
            selectedActivityType: ActivityType.run,
            onActivityTypeChanged: null,
            onStart: null,
            onPause: null,
            onResume: () {},
            onStop: () {},
          ),
        ),
      );

      expect(find.text(AppLocalizationsEn().activityResume), findsOneWidget);
      expect(find.text(AppLocalizationsEn().activityStop), findsOneWidget);
    });

    testWidgets('disables unsafe actions while stopping', (tester) async {
      var stopped = false;

      await tester.pumpWidget(
        _TestApp(
          child: ActivityRecordingControls(
            state: ActivityRecordingState(
              status: ActivityRecordingStatus.stopping,
            ),
            selectedActivityType: ActivityType.run,
            onActivityTypeChanged: null,
            onStart: null,
            onPause: null,
            onResume: null,
            onStop: () => stopped = true,
          ),
        ),
      );

      expect(find.text(AppLocalizationsEn().activityStopping), findsOneWidget);

      await tester.tap(find.text(AppLocalizationsEn().activityStopping));

      expect(stopped, isFalse);
    });

    testWidgets('shows localized empty recording errors', (tester) async {
      await tester.pumpWidget(
        _TestApp(
          child: ActivityRecordingControls(
            state: ActivityRecordingState(
              status: ActivityRecordingStatus.failed,
              lastErrorKey: ActivityRecordingError.emptyRecording,
            ),
            selectedActivityType: ActivityType.run,
            onActivityTypeChanged: null,
            onStart: (_) {},
            onPause: null,
            onResume: null,
            onStop: null,
          ),
        ),
      );

      expect(
        find.text(AppLocalizationsEn().activityRecordingEmpty),
        findsOneWidget,
      );
    });

    testWidgets('shows settings action for denied forever', (tester) async {
      var openedSettings = false;

      await tester.pumpWidget(
        _TestApp(
          child: ActivityRecordingControls(
            state: ActivityRecordingState(
              status: ActivityRecordingStatus.failed,
              lastErrorKey:
                  ActivityRecordingError.locationPermissionDeniedForever,
            ),
            selectedActivityType: ActivityType.run,
            onActivityTypeChanged: null,
            onStart: (_) {},
            onPause: null,
            onResume: null,
            onStop: null,
            onOpenLocationSettings: () => openedSettings = true,
          ),
        ),
      );

      expect(
        find.text(AppLocalizationsEn().activityLocationPermissionDeniedForever),
        findsOneWidget,
      );

      await tester.tap(find.text(AppLocalizationsEn().activityOpenSettings));

      expect(openedSettings, isTrue);
    });

    testWidgets('shows settings action for background permission required', (
      tester,
    ) async {
      var openedSettings = false;

      await tester.pumpWidget(
        _TestApp(
          child: ActivityRecordingControls(
            state: ActivityRecordingState(
              status: ActivityRecordingStatus.failed,
              lastErrorKey: ActivityRecordingError.backgroundPermissionRequired,
            ),
            selectedActivityType: ActivityType.run,
            onActivityTypeChanged: null,
            onStart: (_) {},
            onPause: null,
            onResume: null,
            onStop: null,
            onOpenLocationSettings: () => openedSettings = true,
          ),
        ),
      );

      expect(
        find.text(AppLocalizationsEn().activityBackgroundPermissionRequired),
        findsOneWidget,
      );

      await tester.tap(find.text(AppLocalizationsEn().activityOpenSettings));

      expect(openedSettings, isTrue);
    });

    testWidgets('shows upload actions for completed recordings', (
      tester,
    ) async {
      var retried = false;
      var deleted = false;

      await tester.pumpWidget(
        _TestApp(
          child: ActivityRecordingControls(
            state: ActivityRecordingState(
              status: ActivityRecordingStatus.completed,
            ),
            selectedActivityType: ActivityType.run,
            onActivityTypeChanged: null,
            onStart: null,
            onPause: null,
            onResume: null,
            onStop: null,
            uploadStatus: ActivityUploadStatus.failed,
            onRetryUpload: () => retried = true,
            onDelete: () => deleted = true,
          ),
        ),
      );

      expect(
        find.text(AppLocalizationsEn().activityUploadFailed),
        findsOneWidget,
      );

      await tester.tap(find.text(AppLocalizationsEn().activityRetryUpload));
      await tester.tap(find.text(AppLocalizationsEn().activityDeleteLocal));

      expect(retried, isTrue);
      expect(deleted, isTrue);
    });
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }
}
