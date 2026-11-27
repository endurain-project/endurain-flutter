import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/features/health/models/health_data_access_details.dart';
import 'package:endurain/features/health/models/health_workout_type.dart';
import 'package:endurain/features/health/services/health_heart_rate_index.dart';
import 'package:endurain/features/health/services/health_read_failure.dart';
import 'package:endurain/features/health/services/health_read_window.dart';
import 'package:endurain/features/health/services/health_workout_mapper.dart';
import 'package:endurain/features/health/services/heart_rate_series_reader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';

HealthDataPoint _point({
  required HealthDataType type,
  required HealthValue value,
  required DateTime start,
  required DateTime end,
  String uuid = 'uuid',
  String sourceId = 'source',
  Map<String, dynamic>? metadata,
}) {
  return HealthDataPoint(
    uuid: uuid,
    value: value,
    type: type,
    unit: HealthDataUnit.NO_UNIT,
    dateFrom: start,
    dateTo: end,
    sourcePlatform: HealthPlatformType.googleHealthConnect,
    sourceDeviceId: 'device',
    sourceId: sourceId,
    sourceName: 'source',
    metadata: metadata,
  );
}

HealthDataPoint _workout(
  String uuid,
  DateTime start,
  DateTime end, {
  String sourceId = 'source',
  int? distance,
  HealthDataUnit? unit,
}) {
  return _point(
    type: HealthDataType.WORKOUT,
    value: WorkoutHealthValue(
      workoutActivityType: HealthWorkoutActivityType.RUNNING,
      totalDistance: distance,
      totalDistanceUnit: unit,
    ),
    start: start,
    end: end,
    uuid: uuid,
    sourceId: sourceId,
  );
}

WorkoutRouteLocation _loc(DateTime time, {double lat = 1, double lon = 2}) {
  return WorkoutRouteLocation(
    latitude: lat,
    longitude: lon,
    timestamp: time,
    altitude: 10,
  );
}

HealthDataPoint _route(
  DateTime start,
  DateTime end,
  List<WorkoutRouteLocation> locations, {
  Map<String, dynamic>? metadata,
}) {
  return _point(
    type: HealthDataType.WORKOUT_ROUTE,
    value: WorkoutRouteHealthValue(locations: locations),
    start: start,
    end: end,
    uuid: 'route',
    metadata: metadata,
  );
}

void main() {
  final t0 = DateTime.utc(2026, 5, 1, 10);
  final t1 = t0.add(const Duration(minutes: 30));

  group('partitionHealthWorkoutPoints', () {
    test('skips companion watch and excluded workouts', () async {
      final result = await partitionHealthWorkoutPoints([
        _workout('keep', t0, t1),
        _workout(
          'watch',
          t0,
          t1,
          sourceId: 'com.endurain.endurain.watchkitapp',
        ),
        _workout('done', t0, t1),
      ], exclude: (id) async => id == 'done');

      expect(result.importable.map((p) => p.uuid), ['keep']);
      expect(result.companionSkipped, 1);
      expect(result.excludedSkipped, 1);
    });

    test('keeps everything without an exclude callback', () async {
      final result = await partitionHealthWorkoutPoints([
        _workout('a', t0, t1),
      ]);

      expect(result.importable, hasLength(1));
    });
  });

  group('parseHealthRoutes', () {
    test('keeps routes with locations and prefers the metadata uuid', () {
      final parsed = parseHealthRoutes([
        _route(t0, t1, [_loc(t0)], metadata: {'workout_uuid': 'w1'}),
        _route(t0, t1, const []),
        _point(
          type: HealthDataType.HEART_RATE,
          value: NumericHealthValue(numericValue: 80),
          start: t0,
          end: t1,
        ),
      ]);

      expect(parsed.routes, hasLength(1));
      expect(parsed.routes.single.workoutUuid, 'w1');
      expect(parsed.consentDenied, 0);
    });

    test('counts routes withheld pending consent', () {
      final parsed = parseHealthRoutes([
        _route(t0, t1, [_loc(t0)], metadata: {'route_requires_consent': true}),
      ]);

      expect(parsed.routes, isEmpty);
      expect(parsed.consentDenied, 1);
    });
  });

  group('assignHealthRoutes', () {
    test('gives a route to the workout named by its uuid', () {
      final byWorkout = assignHealthRoutes(
        routes: [
          HealthRouteData(
            start: t0,
            end: t1,
            workoutUuid: 'w2',
            locations: [_loc(t0)],
          ),
        ],
        workoutPoints: [_workout('w1', t0, t1), _workout('w2', t0, t1)],
      );

      expect(byWorkout.keys, ['w2']);
    });

    test('drops a route no workout owns', () {
      final byWorkout = assignHealthRoutes(
        routes: [
          HealthRouteData(
            start: t0,
            end: t1,
            workoutUuid: 'missing',
            locations: [_loc(t0)],
          ),
        ],
        workoutPoints: [_workout('w1', t0, t1)],
      );

      expect(byWorkout, isEmpty);
    });
  });

  group('heart rate helpers', () {
    test('windows are padded by one minute and in UTC', () {
      final windows = healthHeartRateWindows([_workout('w', t0, t1)]);

      expect(windows.single.start, t0.subtract(const Duration(minutes: 1)));
      expect(windows.single.end, t1.add(const Duration(minutes: 1)));
      expect(windows.single.start.isUtc, isTrue);
    });

    test('plugin points become rounded interval samples', () {
      final samples = heartRateSamplesFromPoints([
        _point(
          type: HealthDataType.HEART_RATE,
          value: NumericHealthValue(numericValue: 120.6),
          start: t0,
          end: t1,
        ),
        _route(t0, t1, const []),
      ]);

      expect(samples, hasLength(1));
      expect(samples.single.bpm, 121);
      expect(samples.single.startMs, t0.millisecondsSinceEpoch);
      expect(samples.single.endMs, t1.millisecondsSinceEpoch);
    });

    test('native readings become rounded interval samples', () {
      final samples = heartRateSamplesFromReadings([
        HeartRateReading(start: t0, end: t1, bpm: 99.4),
      ]);

      expect(samples.single.bpm, 99);
      expect(samples.single.endMs, t1.millisecondsSinceEpoch);
    });
  });

  group('mapHealthWorkout', () {
    final index = HealthHeartRateIndex([
      HealthHeartRateSample.interval(start: t0, end: t1, bpm: 140),
    ]);

    test('returns null for a non-workout point', () {
      final point = _point(
        type: HealthDataType.HEART_RATE,
        value: NumericHealthValue(numericValue: 80),
        start: t0,
        end: t1,
      );

      expect(
        mapHealthWorkout(point: point, locations: const [], heartRate: index),
        isNull,
      );
    });

    test('converts miles to meters and defaults other units to meters', () {
      final miles = mapHealthWorkout(
        point: _workout('m', t0, t1, distance: 1, unit: HealthDataUnit.MILE),
        locations: const [],
        heartRate: index,
      )!;
      final meters = mapHealthWorkout(
        point: _workout('m', t0, t1, distance: 500, unit: HealthDataUnit.METER),
        locations: const [],
        heartRate: index,
      )!;
      final unknown = mapHealthWorkout(
        point: _workout(
          'm',
          t0,
          t1,
          distance: 700,
          unit: HealthDataUnit.NO_UNIT,
        ),
        locations: const [],
        heartRate: index,
      )!;
      final none = mapHealthWorkout(
        point: _workout('m', t0, t1),
        locations: const [],
        heartRate: index,
      )!;

      expect(miles.distanceMeters, closeTo(1609.344, 0.01));
      expect(meters.distanceMeters, 500);
      expect(unknown.distanceMeters, 700);
      expect(none.distanceMeters, isNull);
      expect(none.type, HealthWorkoutType.fromPlatformValue('RUNNING'));
    });

    test('sorts route points by time and attaches heart rate', () {
      final later = t0.add(const Duration(minutes: 10));
      final earlier = t0.add(const Duration(minutes: 5));
      final workout = mapHealthWorkout(
        point: _workout('w', t0, t1),
        locations: [_loc(later), _loc(earlier)],
        heartRate: index,
      )!;

      expect(workout.sourceId, 'w');
      expect(workout.route.map((p) => p.time), [earlier, later]);
      expect(workout.route.every((p) => p.heartRate == 140), isTrue);
      expect(workout.route.first.elevation, 10);
    });
  });

  test('healthReadDiagnosticsDetails reports counts only', () {
    final workout = mapHealthWorkout(
      point: _workout('w', t0, t1),
      locations: [_loc(t0)],
      heartRate: HealthHeartRateIndex(const []),
    )!;

    final details = healthReadDiagnosticsDetails(
      workouts: [workout],
      routes: [
        HealthRouteData(
          start: t0,
          end: t1,
          workoutUuid: 'w',
          locations: [_loc(t0)],
        ),
        HealthRouteData(
          start: t0,
          end: t1,
          workoutUuid: null,
          locations: [_loc(t0), _loc(t1)],
        ),
      ],
      routeConsentDenied: 2,
      historyClamped: true,
      companionSkipped: 3,
      excludedSkipped: 4,
      heartRateReadings: 5,
      heartRateSource: 'series',
    );

    expect(details, {
      'workouts': 1,
      'route_samples': 2,
      'route_locations': 3,
      'routes_with_uuid': 1,
      'workouts_with_route': 1,
      'route_read_failed': true,
      'history_clamped': true,
      'companion_watch_skipped': 3,
      'already_handled_skipped': 4,
      'heart_rate_readings': 5,
      'heart_rate_source': 'series',
      'route_points_with_heart_rate': 0,
    });
  });

  group('resolveHealthReadWindow', () {
    final now = DateTime.utc(2026, 6, 30, 12);

    Future<HealthReadWindow> resolve(
      DateTime start, {
      bool android = true,
      bool history = false,
      List<int>? asked,
    }) {
      return resolveHealthReadWindow(
        requestedStart: start,
        now: now,
        isAndroid: android,
        hasHistoryAccess: () async {
          asked?.add(1);
          return history;
        },
      );
    }

    test('does not clamp or ask off Android', () async {
      final asked = <int>[];
      final start = now.subtract(const Duration(days: 400));

      final window = await resolve(start, android: false, asked: asked);

      expect(window.start, start);
      expect(window.historyClamped, isFalse);
      expect(asked, isEmpty);
    });

    test(
      'keeps a start inside the safe recent window without asking',
      () async {
        final asked = <int>[];
        final start = now.subtract(const Duration(days: 10));

        final window = await resolve(start, asked: asked);

        expect(window.start, start);
        expect(window.historyClamped, isFalse);
        expect(asked, isEmpty);
      },
    );

    test('keeps an older start when history access is held', () async {
      final start = now.subtract(const Duration(days: 90));

      final window = await resolve(start, history: true);

      expect(window.start, start);
      expect(window.historyClamped, isFalse);
    });

    test('clamps an older start when history access is declined', () async {
      final window = await resolve(now.subtract(const Duration(days: 90)));

      expect(
        window.start,
        now
            .subtract(healthConnectHistoryWindow)
            .add(healthHistoryCutoffSafetyMargin),
      );
      expect(window.historyClamped, isTrue);
    });

    test('clamps silently when only clock skew straddles the cutoff', () async {
      final asked = <int>[];
      final start = now
          .subtract(healthConnectHistoryWindow)
          .subtract(const Duration(minutes: 1));

      final window = await resolve(start, asked: asked);

      expect(window.historyClamped, isFalse);
      expect(window.start.isAfter(start), isTrue);
      expect(asked, isEmpty);
    });
  });

  group('health read failures', () {
    test('a permission error maps to permission denied', () {
      final error = healthReadFailed(
        HealthException(
          HealthDataType.WORKOUT,
          'denied',
          errorCode: HealthErrorCode.permissionDenied,
        ),
      );

      expect(error.code, AppErrorCode.healthPermissionDenied);
    });

    test('other errors map to a read failure', () {
      final error = healthReadFailed(StateError('boom'));

      expect(error.code, AppErrorCode.healthReadFailed);
      expect(error.isTransient, isFalse);
    });

    test('detects an unavailable platform', () {
      expect(isHealthPlatformUnavailable(UnsupportedError('x')), isTrue);
      expect(isHealthPlatformUnavailable(StateError('x')), isFalse);
    });

    test('maps the tri-state permission answer', () {
      expect(healthAccessStatus(true), HealthDataAccessStatus.allowed);
      expect(healthAccessStatus(false), HealthDataAccessStatus.needsAttention);
      expect(healthAccessStatus(null), HealthDataAccessStatus.needsAttention);
    });
  });
}
