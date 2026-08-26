import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/features/activity/models/activity_recording_state.dart';
import 'package:endurain/features/activity/models/activity_track_point.dart';
import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/models/local_activity_record.dart';
import 'package:endurain/features/activity/services/local_activity_summary_builder.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/elevation_profile.dart';

void main() {
  group('LocalActivitySummaryBuilder', () {
    final builder = LocalActivitySummaryBuilder();

    test('builds coordinate-free summary values for populated recordings', () {
      final state = ActivityRecordingState(
        status: ActivityRecordingStatus.completed,
        activityType: ActivityType.run,
        startedAt: DateTime.utc(2026, 6, 2, 10),
        endedAt: DateTime.utc(2026, 6, 2, 10, 2),
        elapsedDurationSeconds: 120,
        points: [
          _point(latitude: 0, longitude: 0, seconds: 0),
          _point(latitude: 0, longitude: 0.001, seconds: 60),
          _point(latitude: 0, longitude: 0.002, seconds: 120),
        ],
      );

      final record = builder.build(
        state: state,
        id: 'activity_1',
        gpxFileName: 'activity_1.gpx',
        createdAt: DateTime.utc(2026, 6, 2, 10, 3),
      );

      expect(record.id, 'activity_1');
      expect(record.activityType, ActivityType.run);
      expect(record.elapsedDurationSeconds, 120);
      expect(record.distanceMeters, closeTo(222.6, 0.1));
      expect(record.averageSpeedMetersPerSecond, closeTo(1.24, 0.01));
      expect(record.pointCount, 3);
      expect(record.uploadStatus, LocalActivityUploadStatus.pending);
      expect(record.toJson().containsKey('points'), isFalse);
    });

    test(
      'falls back to point timestamps when recording timestamps are absent',
      () {
        final state = ActivityRecordingState(
          status: ActivityRecordingStatus.completed,
          activityType: ActivityType.walk,
          points: [
            _point(latitude: 0, longitude: 0, seconds: 10),
            _point(latitude: 0, longitude: 0, seconds: 70),
          ],
        );

        final record = builder.build(
          state: state,
          id: 'activity_2',
          gpxFileName: 'activity_2.gpx',
          createdAt: DateTime.utc(2026, 6, 2, 10),
        );

        expect(record.startedAt, DateTime.utc(2026, 1, 1, 0, 0, 10));
        expect(record.endedAt, DateTime.utc(2026, 1, 1, 0, 1, 10));
        expect(record.distanceMeters, 0);
        expect(record.averageSpeedMetersPerSecond, 0);
      },
    );

    test('uses zero average speed for a lone GPX point', () {
      final state = ActivityRecordingState(
        status: ActivityRecordingStatus.completed,
        activityType: ActivityType.other,
        elapsedDurationSeconds: 0,
        points: [_point(latitude: 0, longitude: 0)],
      );

      final record = builder.build(
        state: state,
        id: 'activity_3',
        gpxFileName: 'activity_3.gpx',
        createdAt: DateTime.utc(2026, 6, 2, 10),
      );

      expect(record.distanceMeters, 0);
      expect(record.averageSpeedMetersPerSecond, 0);
    });

    test('captures max speed and elevation gain from the track', () {
      final elevations = climbElevationProfile();
      final state = ActivityRecordingState(
        status: ActivityRecordingStatus.completed,
        activityType: ActivityType.ride,
        startedAt: DateTime.utc(2026, 6, 2, 10),
        endedAt: DateTime.utc(2026, 6, 2, 10, 2),
        elapsedDurationSeconds: 120,
        points: [
          for (var index = 0; index < elevations.length; index += 1)
            _point(
              latitude: 0,
              longitude: index * 0.0001,
              seconds: index,
              speed: 6,
              elevation: elevations[index],
            ),
        ],
      );

      final record = builder.build(
        state: state,
        id: 'activity_metrics',
        gpxFileName: 'activity_metrics.gpx',
        createdAt: DateTime.utc(2026, 6, 2, 10, 3),
      );

      // Max speed comes from the ~11 m/s position deltas, not the reported
      // 6 m/s GPS speed: the uploaded GPX carries no speed for the server to
      // read, so both sides must derive it the same way.
      expect(record.maxSpeedMetersPerSecond, closeTo(11.13, 0.01));
      expect(
        record.elevationGainMeters,
        closeTo(climbElevationGainMeters, 0.001),
      );
    });

    test('rejects non-completed recording states', () {
      final state = ActivityRecordingState(
        status: ActivityRecordingStatus.recording,
        activityType: ActivityType.run,
      );

      expect(
        () => builder.build(
          state: state,
          id: 'activity_4',
          gpxFileName: 'activity_4.gpx',
          createdAt: DateTime.utc(2026, 6, 2, 10),
        ),
        throwsA(
          isA<AppException>().having(
            (exception) => exception.code,
            'code',
            AppErrorCode.activityLocalRecordInvalid,
          ),
        ),
      );
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
