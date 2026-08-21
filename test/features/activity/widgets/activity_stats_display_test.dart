import 'package:endurain/features/activity/models/activity_recording_state.dart';
import 'package:endurain/features/activity/models/activity_track_point.dart';
import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/widgets/activity_stats_display.dart';
import 'package:endurain/core/localization/app_locales.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:endurain/l10n/app_localizations_en.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/device_locale.dart';

void main() {
  // Unit rendering follows the device region, and the test harness
  // reports en-US (imperial) by default. Pin a metric region so these
  // metric assertions are explicit rather than harness-dependent.
  setUp(() => useDeviceLocale(metricDeviceLocale));

  group('ActivityStatsDisplay', () {
    testWidgets('shows empty recording stats safely', (tester) async {
      await tester.pumpWidget(
        _TestApp(
          child: ActivityStatsDisplay(
            state: ActivityRecordingState(
              status: ActivityRecordingStatus.recording,
            ),
          ),
        ),
      );

      expect(
        find.text(AppLocalizationsEn().activityStatDuration),
        findsOneWidget,
      );
      expect(find.text('0:00'), findsOneWidget);
      expect(find.text('0 m'), findsOneWidget);
      // Pace/speed and heart rate both show "-" when there is no data yet.
      expect(find.text('-'), findsNWidgets(2));
      expect(
        find.text(AppLocalizationsEn().activityStatHeartRate),
        findsOneWidget,
      );
    });

    testWidgets('shows elapsed recording time before GPS duration exists', (
      tester,
    ) async {
      await tester.pumpWidget(
        _TestApp(
          child: ActivityStatsDisplay(
            state: ActivityRecordingState(
              status: ActivityRecordingStatus.recording,
              elapsedDurationSeconds: 5,
            ),
          ),
        ),
      );

      expect(find.text('0:05'), findsOneWidget);
      expect(find.text('0 m'), findsOneWidget);
    });

    testWidgets('shows populated recording stats', (tester) async {
      await tester.pumpWidget(
        _TestApp(
          child: ActivityStatsDisplay(
            state: ActivityRecordingState(
              status: ActivityRecordingStatus.recording,
              points: [
                _point(latitude: 0, longitude: 0, seconds: 0),
                _point(latitude: 0, longitude: 0.001, seconds: 60, speed: 2),
              ],
            ),
          ),
        ),
      );

      expect(find.text('1:00'), findsOneWidget);
      expect(find.text('111 m'), findsOneWidget);
      expect(find.text('7.2 km/h'), findsOneWidget);
    });

    testWidgets('renders imperial units when the device region is imperial', (
      tester,
    ) async {
      // The unit system is resolved from the *device* locale, so override the
      // metric region pinned in setUp with an imperial one.
      useDeviceLocale(imperialDeviceLocale);

      await tester.pumpWidget(
        _TestApp(
          child: ActivityStatsDisplay(
            state: ActivityRecordingState(
              status: ActivityRecordingStatus.recording,
              points: [
                _point(latitude: 0, longitude: 0, seconds: 0),
                _point(latitude: 0, longitude: 0.001, seconds: 60, speed: 2),
              ],
            ),
          ),
        ),
      );

      // Same track as the metric test above: 111 m is 364 ft, 2 m/s is 4.5 mph.
      expect(find.text('1:00'), findsOneWidget);
      expect(find.text('364 ft'), findsOneWidget);
      expect(find.text('4.5 mph'), findsOneWidget);
      expect(find.text('111 m'), findsNothing);
      expect(find.text('7.2 km/h'), findsNothing);
    });

    testWidgets('shows pace for a completed run', (tester) async {
      await tester.pumpWidget(
        _TestApp(
          child: ActivityStatsDisplay(
            state: ActivityRecordingState(
              status: ActivityRecordingStatus.completed,
              activityType: ActivityType.run,
              points: [
                _point(latitude: 0, longitude: 0, seconds: 0),
                _point(latitude: 0, longitude: 0.001, seconds: 60, speed: 2),
              ],
            ),
          ),
        ),
      );

      expect(find.text(AppLocalizationsEn().activityStatPace), findsOneWidget);
      expect(find.text('8:20 min/km'), findsOneWidget);
      expect(find.text('7.2 km/h'), findsNothing);
    });

    testWidgets('hides stale stats after discard', (tester) async {
      await tester.pumpWidget(
        _TestApp(child: ActivityStatsDisplay(state: ActivityRecordingState())),
      );

      expect(
        find.text(AppLocalizationsEn().activityStatDuration),
        findsNothing,
      );
    });

    testWidgets('shows the latest heart rate when points carry it', (
      tester,
    ) async {
      await tester.pumpWidget(
        _TestApp(
          child: ActivityStatsDisplay(
            state: ActivityRecordingState(
              status: ActivityRecordingStatus.recording,
              points: [
                _point(latitude: 0, longitude: 0, seconds: 0, heartRate: 120),
                _point(
                  latitude: 0,
                  longitude: 0.001,
                  seconds: 60,
                  speed: 2,
                  heartRate: 138,
                ),
              ],
            ),
          ),
        ),
      );

      expect(
        find.text(AppLocalizationsEn().activityStatHeartRate),
        findsOneWidget,
      );
      expect(find.text('138 bpm'), findsOneWidget);
    });

    testWidgets('shows the live heart rate before any point is recorded', (
      tester,
    ) async {
      await tester.pumpWidget(
        _TestApp(
          child: ActivityStatsDisplay(
            state: ActivityRecordingState(
              status: ActivityRecordingStatus.recording,
              currentHeartRateBpm: 129,
            ),
          ),
        ),
      );

      expect(
        find.text(AppLocalizationsEn().activityStatHeartRate),
        findsOneWidget,
      );
      expect(find.text('129 bpm'), findsOneWidget);
    });

    testWidgets('prefers the live heart rate over the per-point value', (
      tester,
    ) async {
      await tester.pumpWidget(
        _TestApp(
          child: ActivityStatsDisplay(
            state: ActivityRecordingState(
              status: ActivityRecordingStatus.recording,
              currentHeartRateBpm: 150,
              points: [
                _point(latitude: 0, longitude: 0, seconds: 0, heartRate: 120),
                _point(
                  latitude: 0,
                  longitude: 0.001,
                  seconds: 60,
                  speed: 2,
                  heartRate: 138,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('150 bpm'), findsOneWidget);
      expect(find.text('138 bpm'), findsNothing);
    });

    testWidgets('shows a placeholder heart rate without a reading', (
      tester,
    ) async {
      await tester.pumpWidget(
        _TestApp(
          child: ActivityStatsDisplay(
            state: ActivityRecordingState(
              status: ActivityRecordingStatus.recording,
              points: [
                _point(latitude: 0, longitude: 0, seconds: 0),
                _point(latitude: 0, longitude: 0.001, seconds: 60, speed: 2),
              ],
            ),
          ),
        ),
      );

      // Always shown, like pace/speed: the label is present with a "-" value.
      expect(
        find.text(AppLocalizationsEn().activityStatHeartRate),
        findsOneWidget,
      );
      expect(find.text('-'), findsOneWidget);
    });

    testWidgets('shows live power and cadence when present', (tester) async {
      await tester.pumpWidget(
        _TestApp(
          child: ActivityStatsDisplay(
            state: ActivityRecordingState(
              status: ActivityRecordingStatus.recording,
              currentPowerWatts: 250,
              currentCadenceRpm: 88,
            ),
          ),
        ),
      );

      expect(find.text(AppLocalizationsEn().activityStatPower), findsOneWidget);
      expect(find.text('250 W'), findsOneWidget);
      expect(
        find.text(AppLocalizationsEn().activityStatCadence),
        findsOneWidget,
      );
      expect(find.text('88 rpm'), findsOneWidget);
    });

    testWidgets('omits power and cadence tiles without a reading', (
      tester,
    ) async {
      await tester.pumpWidget(
        _TestApp(
          child: ActivityStatsDisplay(
            state: ActivityRecordingState(
              status: ActivityRecordingStatus.recording,
              points: [
                _point(latitude: 0, longitude: 0, seconds: 0),
                _point(latitude: 0, longitude: 0.001, seconds: 60, speed: 2),
              ],
            ),
          ),
        ),
      );

      expect(find.text(AppLocalizationsEn().activityStatPower), findsNothing);
      expect(find.text(AppLocalizationsEn().activityStatCadence), findsNothing);
    });
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }
}

ActivityTrackPoint _point({
  required double latitude,
  required double longitude,
  required int seconds,
  double? speed,
  int? heartRate,
  int? power,
  int? cadence,
}) {
  return ActivityTrackPoint(
    latitude: latitude,
    longitude: longitude,
    timestamp: DateTime.utc(2026).add(Duration(seconds: seconds)),
    speedMetersPerSecond: speed,
    heartRateBpm: heartRate,
    powerWatts: power,
    cadenceRpm: cadence,
  );
}
