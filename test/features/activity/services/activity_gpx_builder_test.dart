import 'package:endurain/features/activity/models/activity_recording_state.dart';
import 'package:endurain/features/activity/models/activity_track_segment.dart';
import 'package:endurain/features/activity/models/activity_track_point.dart';
import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/services/activity_gpx_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ActivityGpxBuilder', () {
    const builder = ActivityGpxBuilder();

    test('builds GPX for valid points', () {
      final gpx = builder.build(
        ActivityRecordingState(
          status: ActivityRecordingStatus.completed,
          activityType: ActivityType.run,
          points: [
            _point(latitude: 41.1, longitude: -8.6, elevationMeters: 20),
            _point(latitude: 41.2, longitude: -8.7, elevationMeters: 25),
          ],
        ),
      );

      expect(gpx, startsWith('<?xml version="1.0" encoding="UTF-8"?>'));
      expect(gpx, contains('<gpx version="1.1" creator="Endurain mobile app"'));
      expect(gpx, contains('  <metadata>'));
      expect(gpx, contains('    <name>run</name>'));
      expect(
        gpx,
        contains(
          '    <link href="https://codeberg.org/endurain-project">\n'
          '      <text>Endurain Project</text>\n'
          '    </link>',
        ),
      );
      expect(gpx, contains('    <time>2026-05-30T10:00:00.000Z</time>'));
      expect(
        gpx,
        contains(
          '    <bounds minlat="41.1" minlon="-8.7" '
          'maxlat="41.2" maxlon="-8.6" />',
        ),
      );
      expect(gpx, contains('<name>run</name>'));
      expect(gpx, contains('<type>run</type>'));
      expect(gpx, contains('<trkpt lat="41.1" lon="-8.6">'));
      expect(gpx, contains('<ele>20.0</ele>'));
      expect(gpx, contains('<time>2026-05-30T10:00:00.000Z</time>'));
      expect(gpx, contains('</gpx>'));
    });

    test('formats decimal values for GPX output', () {
      final gpx = builder.build(
        ActivityRecordingState(
          status: ActivityRecordingStatus.completed,
          activityType: ActivityType.ride,
          points: [
            _point(
              latitude: 38.938779999999994,
              longitude: -8.8569227,
              elevationMeters: 66,
            ),
          ],
        ),
      );

      expect(gpx, contains('<type>ride</type>'));
      expect(gpx, contains('<trkpt lat="38.93878" lon="-8.8569227">'));
      expect(gpx, contains('<ele>66.0</ele>'));
    });

    test('omits elevation when missing', () {
      final gpx = builder.build(
        ActivityRecordingState(
          status: ActivityRecordingStatus.completed,
          points: [_point(elevationMeters: null)],
        ),
      );

      expect(gpx, isNot(contains('<ele>')));
      expect(gpx, contains('<time>2026-05-30T10:00:00.000Z</time>'));
    });

    test('builds well-formed empty track segments', () {
      final gpx = builder.build(
        ActivityRecordingState(status: ActivityRecordingStatus.completed),
      );

      expect(gpx, contains('<trkseg>'));
      expect(gpx, contains('</trkseg>'));
      expect(gpx, isNot(contains('<trkpt')));
      expect(gpx, isNot(contains('<bounds')));
    });

    test('preserves pause and resume boundaries as separate GPX segments', () {
      final gpx = builder.build(
        ActivityRecordingState(
          status: ActivityRecordingStatus.completed,
          segments: [
            ActivityTrackSegment(
              points: [_point(latitude: 41.1, longitude: -8.6)],
            ),
            ActivityTrackSegment(
              points: [_point(latitude: 41.2, longitude: -8.7)],
            ),
          ],
        ),
      );

      expect(RegExp('<trkseg>').allMatches(gpx), hasLength(2));
      expect(gpx, contains('<trkpt lat="41.1" lon="-8.6">'));
      expect(gpx, contains('<trkpt lat="41.2" lon="-8.7">'));
    });

    test('escapes XML metadata values', () {
      final gpx = builder.build(
        ActivityRecordingState(status: ActivityRecordingStatus.completed),
        trackName: 'A&B "run" <test>',
      );

      expect(
        gpx,
        contains('<name>A&amp;B &quot;run&quot; &lt;test&gt;</name>'),
      );
    });

    test('emits heart rate as a Garmin TrackPointExtension', () {
      final gpx = builder.build(
        ActivityRecordingState(
          status: ActivityRecordingStatus.completed,
          activityType: ActivityType.run,
          points: [_point(latitude: 41.1, longitude: -8.6, heartRateBpm: 142)],
        ),
      );

      expect(
        gpx,
        contains(
          'xmlns:gpxtpx="http://www.garmin.com/xmlschemas/'
          'TrackPointExtension/v1"',
        ),
      );
      expect(gpx, contains('<gpxtpx:hr>142</gpxtpx:hr>'));
    });
  });
}

ActivityTrackPoint _point({
  double latitude = 41,
  double longitude = -8,
  double? elevationMeters = 20,
  int? heartRateBpm,
}) {
  return ActivityTrackPoint(
    latitude: latitude,
    longitude: longitude,
    elevationMeters: elevationMeters,
    timestamp: DateTime.utc(2026, 5, 30, 10),
    heartRateBpm: heartRateBpm,
  );
}
