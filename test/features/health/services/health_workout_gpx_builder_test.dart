import 'package:flutter_test/flutter_test.dart';
import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/features/health/models/health_route_point.dart';
import 'package:endurain/features/health/models/health_workout.dart';
import 'package:endurain/features/health/models/health_workout_type.dart';
import 'package:endurain/features/health/services/health_workout_gpx_builder.dart';

void main() {
  const builder = HealthWorkoutGpxBuilder();

  final start = DateTime.utc(2025, 6, 1, 9, 0, 0);
  final end = DateTime.utc(2025, 6, 1, 10, 0, 0);

  HealthWorkout makeWorkout({
    List<HealthRoutePoint> route = const [],
    HealthWorkoutType type = HealthWorkoutType.run,
  }) => HealthWorkout(
    sourceId: 'test-uuid',
    type: type,
    startedAt: start,
    endedAt: end,
    route: route,
  );

  HealthRoutePoint makePoint({
    double lat = 38.71,
    double lon = -9.13,
    double? ele,
    int? hr,
    int offsetSeconds = 0,
  }) => HealthRoutePoint(
    latitude: lat,
    longitude: lon,
    time: start.add(Duration(seconds: offsetSeconds)),
    elevation: ele,
    heartRate: hr,
  );

  group('HealthWorkoutGpxBuilder', () {
    test('throws healthGpxBuildFailed when workout has no route', () {
      final workout = makeWorkout(route: const []);
      expect(
        () => builder.build(workout),
        throwsA(
          isA<AppException>().having(
            (e) => e.code,
            'code',
            AppErrorCode.healthGpxBuildFailed,
          ),
        ),
      );
    });

    test('produces valid GPX XML for a workout with route', () {
      final workout = makeWorkout(
        route: [
          makePoint(lat: 38.71, lon: -9.13, ele: 42.0, offsetSeconds: 0),
          makePoint(lat: 38.72, lon: -9.14, ele: 43.5, offsetSeconds: 60),
        ],
      );
      final gpx = builder.build(workout);

      expect(gpx, contains('<?xml version="1.0" encoding="UTF-8"?>'));
      expect(gpx, contains('<gpx'));
      expect(gpx, contains('<trk>'));
      expect(gpx, contains('<trkseg>'));
      expect(gpx, contains('<trkpt lat="38.71" lon="-9.13">'));
      expect(gpx, contains('<trkpt lat="38.72" lon="-9.14">'));
      expect(gpx, contains('<ele>42.0</ele>'));
      expect(gpx, contains('<ele>43.5</ele>'));
      expect(gpx, contains('<time>2025-06-01T09:00:00.000Z</time>'));
      expect(gpx, contains('<type>run</type>'));
    });

    test('includes a <bounds> element enclosing the route', () {
      final workout = makeWorkout(
        route: [
          makePoint(lat: 38.71, lon: -9.13, offsetSeconds: 0),
          makePoint(lat: 38.72, lon: -9.14, offsetSeconds: 60),
        ],
      );
      final gpx = builder.build(workout);

      // min/max derived from the two route points. Keeps the health GPX shape
      // consistent with the GPS-recording builder, which also emits <bounds>.
      expect(
        gpx,
        contains(
          '<bounds minlat="38.71" minlon="-9.14" '
          'maxlat="38.72" maxlon="-9.13" />',
        ),
      );
    });

    test('includes gpxtpx:hr extension when heart rate is present', () {
      final workout = makeWorkout(
        route: [
          makePoint(hr: 155, offsetSeconds: 0),
          makePoint(lat: 38.72, lon: -9.14, hr: 160, offsetSeconds: 30),
        ],
      );
      final gpx = builder.build(workout);

      expect(gpx, contains('xmlns:gpxtpx='));
      expect(gpx, contains('<gpxtpx:hr>155</gpxtpx:hr>'));
      expect(gpx, contains('<gpxtpx:hr>160</gpxtpx:hr>'));
      expect(gpx, contains('<gpxtpx:TrackPointExtension>'));
    });

    test('omits gpxtpx namespace when no heart rate data', () {
      final workout = makeWorkout(route: [makePoint(offsetSeconds: 0)]);
      final gpx = builder.build(workout);

      expect(gpx, isNot(contains('gpxtpx')));
    });

    test('uses activityType apiValue as track type', () {
      final workout = makeWorkout(
        type: HealthWorkoutType.ride,
        route: [makePoint()],
      );
      final gpx = builder.build(workout);

      expect(gpx, contains('<type>ride</type>'));
      expect(gpx, contains('<name>ride</name>'));
    });

    test('omits ele element when elevation is null', () {
      final workout = makeWorkout(route: [makePoint(ele: null)]);
      final gpx = builder.build(workout);

      expect(gpx, isNot(contains('<ele>')));
    });

    test('output is valid XML (no unescaped characters)', () {
      final workout = makeWorkout(route: [makePoint()]);
      final gpx = builder.build(workout);

      // Spot-check no bare & or < in content (outside tags)
      expect(gpx, isNot(matches(r'>[^<]*&[^;a-zA-Z#][^<]*<')));
    });
  });
}
