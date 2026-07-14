import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:endurain/features/health/models/health_authorization_status.dart';
import 'package:endurain/features/health/models/health_sdk_status.dart';
import 'package:endurain/features/health/models/health_workout_type.dart';
import 'package:endurain/features/health/services/health_package_platform_adapter.dart';
import 'package:endurain/features/health/services/health_platform_adapter.dart';
import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/health/models/health_workout.dart';
import 'package:health/health.dart';

// These tests verify the adapter contract using the
// UnsupportedHealthPlatformAdapter and the HealthWorkoutType mapping logic.
// The concrete HealthPackagePlatformAdapter can only be exercised in
// integration tests with a real native platform.

void main() {
  group('HealthPackagePlatformAdapter authorization status', () {
    test('maps hasPermissions=true to granted', () async {
      final adapter = HealthPackagePlatformAdapter(
        health: _FakeHealth(hasPermissionsResult: true),
      );

      expect(
        await adapter.currentAuthorizationStatus(),
        HealthAuthorizationStatus.granted,
      );
    });

    test('maps hasPermissions=false to denied', () async {
      final adapter = HealthPackagePlatformAdapter(
        health: _FakeHealth(hasPermissionsResult: false),
      );

      expect(
        await adapter.currentAuthorizationStatus(),
        HealthAuthorizationStatus.denied,
      );
    });

    test('maps hasPermissions=null to notDetermined', () async {
      final adapter = HealthPackagePlatformAdapter(
        health: _FakeHealth(hasPermissionsResult: null),
      );

      expect(
        await adapter.currentAuthorizationStatus(),
        HealthAuthorizationStatus.notDetermined,
      );
    });

    test('configures the plugin once before reading permissions', () async {
      final health = _FakeHealth(hasPermissionsResult: true);
      final adapter = HealthPackagePlatformAdapter(health: health);

      await adapter.currentAuthorizationStatus();
      await adapter.currentAuthorizationStatus();

      expect(health.configureCallCount, 1);
    });

    test('checks every data type read by the Android workout reader', () async {
      final health = _FakeHealth(hasPermissionsResult: true);
      final adapter = HealthPackagePlatformAdapter(
        health: health,
        targetPlatform: () => TargetPlatform.android,
      );

      await adapter.currentAuthorizationStatus();

      expect(health.lastHasPermissionTypes, [
        HealthDataType.WORKOUT,
        HealthDataType.WORKOUT_ROUTE,
        HealthDataType.HEART_RATE,
      ]);
      expect(health.lastHasPermissionAccess, [
        HealthDataAccess.READ,
        HealthDataAccess.READ,
        HealthDataAccess.READ,
      ]);
    });

    test(
      'requests every data type read by the Android workout reader',
      () async {
        final health = _FakeHealth(
          hasPermissionsResult: true,
          requestAuthorizationResult: true,
        );
        final adapter = HealthPackagePlatformAdapter(
          health: health,
          targetPlatform: () => TargetPlatform.android,
        );

        final result = await adapter.requestAuthorization();

        expect(result, HealthAuthorizationStatus.granted);
        expect(health.lastRequestAuthorizationTypes, [
          HealthDataType.WORKOUT,
          HealthDataType.WORKOUT_ROUTE,
          HealthDataType.HEART_RATE,
        ]);
        expect(health.lastRequestAuthorizationAccess, [
          HealthDataAccess.READ,
          HealthDataAccess.READ,
          HealthDataAccess.READ,
        ]);
      },
    );

    test('keeps the iOS request limited to imported data', () async {
      final health = _FakeHealth(
        hasPermissionsResult: true,
        requestAuthorizationResult: true,
      );
      final adapter = HealthPackagePlatformAdapter(
        health: health,
        targetPlatform: () => TargetPlatform.iOS,
      );

      await adapter.requestAuthorization();

      expect(health.lastRequestAuthorizationTypes, [
        HealthDataType.WORKOUT,
        HealthDataType.WORKOUT_ROUTE,
        HealthDataType.HEART_RATE,
      ]);
    });

    test('does not accept a partial Android grant callback', () async {
      final health = _FakeHealth(
        hasPermissionsResult: false,
        requestAuthorizationResult: true,
      );
      final adapter = HealthPackagePlatformAdapter(
        health: health,
        targetPlatform: () => TargetPlatform.android,
      );

      expect(
        await adapter.requestAuthorization(),
        HealthAuthorizationStatus.denied,
      );
    });
  });

  group('HealthPackagePlatformAdapter — via UnsupportedAdapter contract', () {
    // Verify the adapter interface contract is satisfied
    const adapter = UnsupportedHealthPlatformAdapter();

    test('getSdkStatus completes without throwing', () async {
      final status = await adapter.getSdkStatus();
      expect(status, isA<HealthSdkStatus>());
    });

    test('requestAuthorization completes without throwing', () async {
      final result = await adapter.requestAuthorization();
      expect(result, isA<HealthAuthorizationStatus>());
    });

    test('readWorkouts returns a list', () async {
      final workouts = await adapter.readWorkouts(
        start: DateTime.utc(2025, 6, 1),
        end: DateTime.utc(2025, 6, 2),
      );
      expect(workouts, isA<List<HealthWorkout>>());
    });
  });

  group('HealthWorkoutType mapping — platform value round-trip', () {
    test('RUNNING maps to run -> ActivityType.run', () {
      final type = HealthWorkoutType.fromPlatformValue('RUNNING');
      expect(type.toActivityType(), ActivityType.run);
    });

    test('CYCLING maps to ride -> ActivityType.ride', () {
      final type = HealthWorkoutType.fromPlatformValue('CYCLING');
      expect(type.toActivityType(), ActivityType.ride);
    });

    test('WALKING maps to walk -> ActivityType.walk', () {
      final type = HealthWorkoutType.fromPlatformValue('WALKING');
      expect(type.toActivityType(), ActivityType.walk);
    });

    test('HIKING maps to hike -> ActivityType.hike', () {
      final type = HealthWorkoutType.fromPlatformValue('HIKING');
      expect(type.toActivityType(), ActivityType.hike);
    });

    test('unknown type maps to other -> ActivityType.other', () {
      final type = HealthWorkoutType.fromPlatformValue('TENNIS');
      expect(type, HealthWorkoutType.other);
      expect(type.toActivityType(), ActivityType.other);
    });
  });

  group('HealthPackagePlatformAdapter route metadata', () {
    final start = DateTime.utc(2026, 7, 1, 9);
    final end = DateTime.utc(2026, 7, 1, 10);

    test('uses metadata workout UUID to attach the route', () async {
      final health = _FakeHealth(
        hasPermissionsResult: true,
        dataByType: {
          HealthDataType.WORKOUT: [_workoutPoint(start: start, end: end)],
          HealthDataType.WORKOUT_ROUTE: [
            _routePoint(
              start: start,
              end: end,
              metadata: const {'workout_uuid': 'workout-1'},
              locations: [
                WorkoutRouteLocation(
                  latitude: 41.1,
                  longitude: -8.6,
                  timestamp: start,
                ),
              ],
            ),
          ],
        },
      );
      final adapter = HealthPackagePlatformAdapter(
        health: health,
        targetPlatform: () => TargetPlatform.android,
      );

      final workouts = await adapter.readWorkouts(start: start, end: end);

      expect(workouts, hasLength(1));
      expect(workouts.single.route, hasLength(1));
      expect(workouts.single.route.single.latitude, 41.1);
      expect(adapter.routeConsentDeniedCount, 0);
    });

    test('counts explicit consent metadata on an empty route', () async {
      final health = _FakeHealth(
        hasPermissionsResult: true,
        dataByType: {
          HealthDataType.WORKOUT: [_workoutPoint(start: start, end: end)],
          HealthDataType.WORKOUT_ROUTE: [
            _routePoint(
              start: start,
              end: end,
              metadata: const {
                'workout_uuid': 'workout-1',
                'route_requires_consent': true,
              },
            ),
          ],
        },
      );
      final adapter = HealthPackagePlatformAdapter(
        health: health,
        targetPlatform: () => TargetPlatform.android,
      );

      final workouts = await adapter.readWorkouts(start: start, end: end);

      expect(workouts.single.route, isEmpty);
      expect(adapter.routeConsentDeniedCount, 1);
    });
  });

  group('healthRouteMatchesWorkout', () {
    final workoutStart = DateTime.utc(2025, 6, 1, 9, 0);
    final workoutEnd = DateTime.utc(2025, 6, 1, 10, 0);

    test('matches by UUID when the route carries the workout UUID', () {
      expect(
        healthRouteMatchesWorkout(
          routeWorkoutUuid: 'w1',
          routeStart: DateTime.utc(2030), // time ignored when UUID present
          routeEnd: DateTime.utc(2030),
          workoutUuid: 'w1',
          workoutStart: workoutStart,
          workoutEnd: workoutEnd,
        ),
        isTrue,
      );
    });

    test('rejects a different UUID even if the times overlap', () {
      expect(
        healthRouteMatchesWorkout(
          routeWorkoutUuid: 'other',
          routeStart: workoutStart,
          routeEnd: workoutEnd,
          workoutUuid: 'w1',
          workoutStart: workoutStart,
          workoutEnd: workoutEnd,
        ),
        isFalse,
      );
    });

    test('matches by time overlap when UUID is absent (iOS)', () {
      expect(
        healthRouteMatchesWorkout(
          routeWorkoutUuid: null,
          routeStart: DateTime.utc(2025, 6, 1, 9, 5),
          routeEnd: DateTime.utc(2025, 6, 1, 9, 55),
          workoutUuid: 'w1',
          workoutStart: workoutStart,
          workoutEnd: workoutEnd,
        ),
        isTrue,
      );
    });

    test('does not match a route well outside the workout window', () {
      expect(
        healthRouteMatchesWorkout(
          routeWorkoutUuid: null,
          routeStart: DateTime.utc(2025, 6, 1, 12, 0),
          routeEnd: DateTime.utc(2025, 6, 1, 13, 0),
          workoutUuid: 'w1',
          workoutStart: workoutStart,
          workoutEnd: workoutEnd,
        ),
        isFalse,
      );
    });

    test('tolerates a small clock skew at the window edge', () {
      // Route ends 30s before the workout starts — within the 60s tolerance.
      expect(
        healthRouteMatchesWorkout(
          routeWorkoutUuid: null,
          routeStart: DateTime.utc(2025, 6, 1, 8, 58, 30),
          routeEnd: DateTime.utc(2025, 6, 1, 8, 59, 30),
          workoutUuid: 'w1',
          workoutStart: workoutStart,
          workoutEnd: workoutEnd,
        ),
        isTrue,
      );
    });
  });
}

class _FakeHealth extends Health {
  _FakeHealth({
    required this.hasPermissionsResult,
    this.requestAuthorizationResult = false,
    this.dataByType = const {},
  });

  final bool? hasPermissionsResult;
  final bool requestAuthorizationResult;
  final Map<HealthDataType, List<HealthDataPoint>> dataByType;
  int configureCallCount = 0;
  List<HealthDataType>? lastHasPermissionTypes;
  List<HealthDataAccess>? lastHasPermissionAccess;
  List<HealthDataType>? lastRequestAuthorizationTypes;
  List<HealthDataAccess>? lastRequestAuthorizationAccess;

  @override
  Future<void> configure() async {
    configureCallCount++;
  }

  @override
  Future<bool?> hasPermissions(
    List<HealthDataType> types, {
    List<HealthDataAccess>? permissions,
  }) async {
    lastHasPermissionTypes = types;
    lastHasPermissionAccess = permissions;
    return hasPermissionsResult;
  }

  @override
  Future<bool> requestAuthorization(
    List<HealthDataType> types, {
    List<HealthDataAccess>? permissions,
  }) async {
    lastRequestAuthorizationTypes = types;
    lastRequestAuthorizationAccess = permissions;
    return requestAuthorizationResult;
  }

  @override
  Future<List<HealthDataPoint>> getHealthDataFromTypes({
    required List<HealthDataType> types,
    Map<HealthDataType, HealthDataUnit>? preferredUnits,
    required DateTime startTime,
    required DateTime endTime,
    List<RecordingMethod> recordingMethodsToFilter = const [],
  }) async {
    return [for (final type in types) ...?dataByType[type]];
  }
}

HealthDataPoint _workoutPoint({
  required DateTime start,
  required DateTime end,
}) {
  return HealthDataPoint(
    uuid: 'workout-1',
    value: WorkoutHealthValue(
      workoutActivityType: HealthWorkoutActivityType.RUNNING,
    ),
    type: HealthDataType.WORKOUT,
    unit: HealthDataUnit.NO_UNIT,
    dateFrom: start,
    dateTo: end,
    sourcePlatform: HealthPlatformType.googleHealthConnect,
    sourceDeviceId: 'device',
    sourceId: 'source',
    sourceName: 'source',
  );
}

HealthDataPoint _routePoint({
  required DateTime start,
  required DateTime end,
  required Map<String, dynamic> metadata,
  List<WorkoutRouteLocation> locations = const [],
}) {
  return HealthDataPoint(
    uuid: 'route-1',
    value: WorkoutRouteHealthValue(locations: locations),
    type: HealthDataType.WORKOUT_ROUTE,
    unit: HealthDataUnit.NO_UNIT,
    dateFrom: start,
    dateTo: end,
    sourcePlatform: HealthPlatformType.googleHealthConnect,
    sourceDeviceId: 'device',
    sourceId: 'source',
    sourceName: 'source',
    metadata: metadata,
  );
}
