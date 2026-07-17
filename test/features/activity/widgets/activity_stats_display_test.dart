import 'package:endurain/features/activity/models/activity_recording_state.dart';
import 'package:endurain/features/activity/models/activity_track_point.dart';
import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/widgets/activity_stats_display.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:endurain/l10n/app_localizations_en.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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

ActivityTrackPoint _point({
  required double latitude,
  required double longitude,
  required int seconds,
  double? speed,
  int? heartRate,
}) {
  return ActivityTrackPoint(
    latitude: latitude,
    longitude: longitude,
    timestamp: DateTime.utc(2026).add(Duration(seconds: seconds)),
    speedMetersPerSecond: speed,
    heartRateBpm: heartRate,
  );
}
