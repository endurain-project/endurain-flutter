import 'package:endurain/features/activity/models/activity_recording_state.dart';
import 'package:endurain/features/activity/models/activity_track_point.dart';
import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/widgets/activity_completion_summary.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:endurain/l10n/app_localizations_en.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ActivityCompletionSummary', () {
    final l10n = AppLocalizationsEn();

    testWidgets('shows a richer summary for a completed ride', (tester) async {
      await tester.pumpWidget(
        _TestApp(
          child: ActivityCompletionSummary(
            state: ActivityRecordingState(
              status: ActivityRecordingStatus.completed,
              activityType: ActivityType.ride,
              startedAt: DateTime.utc(2026, 6, 2, 14, 30),
              points: [
                _point(
                  latitude: 0,
                  longitude: 0,
                  seconds: 0,
                  speed: 2,
                  elevation: 100,
                ),
                _point(
                  latitude: 0,
                  longitude: 0.001,
                  seconds: 60,
                  speed: 5,
                  elevation: 130,
                ),
                _point(
                  latitude: 0,
                  longitude: 0.002,
                  seconds: 120,
                  speed: 3,
                  elevation: 120,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text(l10n.activityHistorySummary), findsOneWidget);
      expect(find.text(l10n.activityTypeRide), findsOneWidget);
      expect(find.text('2:00'), findsOneWidget);
      expect(find.text('222 m'), findsOneWidget);
      expect(find.text(l10n.activityHistoryAverageSpeed), findsOneWidget);
      expect(find.text('6.7 km/h'), findsOneWidget);
      expect(find.text(l10n.activityStatMaxSpeed), findsOneWidget);
      expect(find.text('18.0 km/h'), findsOneWidget);
      expect(find.text(l10n.activityStatElevationGain), findsOneWidget);
      expect(find.text('30 m'), findsOneWidget);
      expect(find.text(l10n.activityHistoryPointCount), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('shows pace instead of average speed for a run', (
      tester,
    ) async {
      await tester.pumpWidget(
        _TestApp(
          child: ActivityCompletionSummary(
            state: ActivityRecordingState(
              status: ActivityRecordingStatus.completed,
              activityType: ActivityType.run,
              points: [
                _point(latitude: 0, longitude: 0, seconds: 0, speed: 2),
                _point(latitude: 0, longitude: 0.001, seconds: 60, speed: 2),
              ],
            ),
          ),
        ),
      );

      expect(find.text(l10n.activityStatPace), findsOneWidget);
      expect(find.textContaining('min/km'), findsOneWidget);
      expect(find.text(l10n.activityHistoryAverageSpeed), findsNothing);
    });

    testWidgets('omits elevation gain without elevation data', (tester) async {
      await tester.pumpWidget(
        _TestApp(
          child: ActivityCompletionSummary(
            state: ActivityRecordingState(
              status: ActivityRecordingStatus.completed,
              activityType: ActivityType.walk,
              points: [
                _point(latitude: 0, longitude: 0, seconds: 0, speed: 1),
                _point(latitude: 0, longitude: 0.001, seconds: 60, speed: 1),
              ],
            ),
          ),
        ),
      );

      expect(find.text(l10n.activityStatElevationGain), findsNothing);
      expect(find.text(l10n.activityStatMaxSpeed), findsOneWidget);
    });

    testWidgets('renders safely for an empty completed recording', (
      tester,
    ) async {
      await tester.pumpWidget(
        _TestApp(
          child: ActivityCompletionSummary(
            state: ActivityRecordingState(
              status: ActivityRecordingStatus.completed,
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text(l10n.activityTypeOther), findsOneWidget);
      expect(find.text('0:00'), findsOneWidget);
      expect(find.text('0 m'), findsOneWidget);
    });
  });
}

ActivityTrackPoint _point({
  required double latitude,
  required double longitude,
  int seconds = 0,
  double? speed,
  double? elevation,
}) {
  return ActivityTrackPoint(
    latitude: latitude,
    longitude: longitude,
    timestamp: DateTime.utc(2026).add(Duration(seconds: seconds)),
    speedMetersPerSecond: speed,
    elevationMeters: elevation,
  );
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
