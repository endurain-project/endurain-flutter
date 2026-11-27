import 'package:endurain/core/diagnostics/diagnostics_service.dart';
import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/health/models/health_authorization_status.dart';
import 'package:endurain/features/health/models/health_sdk_status.dart';
import 'package:endurain/features/health/models/health_workout.dart';
import 'package:endurain/features/health/models/health_workout_changes.dart';
import 'package:endurain/features/health/models/health_workout_type.dart';
import 'package:endurain/features/health/services/health_package_platform_adapter.dart';
import 'package:endurain/features/health/services/health_platform_adapter.dart';
import 'package:endurain/features/health/services/health_workout_changes_reader.dart';
import 'package:endurain/features/health/services/heart_rate_series_reader.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';

import '../../../helpers/recording_diagnostics.dart';

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
        HealthDataType.DISTANCE_DELTA,
      ]);
      expect(health.lastHasPermissionAccess, [
        HealthDataAccess.READ,
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
          HealthDataType.DISTANCE_DELTA,
        ]);
        expect(health.lastRequestAuthorizationAccess, [
          HealthDataAccess.READ,
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

  group('HealthPackagePlatformAdapter authorization failures', () {
    HealthPackagePlatformAdapter adapterFailingWith(Object error) {
      return HealthPackagePlatformAdapter(
        health: _FakeHealth(hasPermissionsResult: true, authError: error),
        targetPlatform: () => TargetPlatform.android,
      );
    }

    Matcher throwsCode(AppErrorCode code) =>
        throwsA(isA<AppException>().having((e) => e.code, 'code', code));

    test('Health Connect missing is unavailable, not denied', () async {
      await expectLater(
        adapterFailingWith(UnsupportedError('no Health Connect'))
            .requestAuthorization(),
        throwsCode(AppErrorCode.healthUnavailable),
      );
    });

    test('a not-supported platform error is unavailable', () async {
      await expectLater(
        adapterFailingWith(
          HealthException(
            null,
            'nope',
            errorCode: HealthErrorCode.notSupported,
          ),
        ).requestAuthorization(),
        throwsCode(AppErrorCode.healthUnavailable),
      );
    });

    test('a permission error stays denied', () async {
      await expectLater(
        adapterFailingWith(
          HealthException(
            null,
            'no',
            errorCode: HealthErrorCode.permissionDenied,
          ),
        ).requestAuthorization(),
        throwsCode(AppErrorCode.healthPermissionDenied),
      );
    });

    test('a transient platform error is a read failure, not denied', () async {
      await expectLater(
        adapterFailingWith(
          HealthException(null, 'busy', errorCode: HealthErrorCode.unavailable),
        ).requestAuthorization(),
        throwsA(
          isA<AppException>()
              .having((e) => e.code, 'code', AppErrorCode.healthReadFailed)
              .having((e) => e.isTransient, 'isTransient', isTrue),
        ),
      );
    });

    test('status check reports a missing platform instead of denied', () async {
      await expectLater(
        adapterFailingWith(UnsupportedError('no Health Connect'))
            .currentAuthorizationStatus(),
        throwsCode(AppErrorCode.healthUnavailable),
      );
    });

    test('status check still maps other failures to denied', () async {
      expect(
        await adapterFailingWith(StateError('boom'))
            .currentAuthorizationStatus(),
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

  group('HealthPackagePlatformAdapter companion watch workouts', () {
    final start = DateTime.utc(2026, 7, 1, 9);
    final end = DateTime.utc(2026, 7, 1, 10);

    test('skips workouts saved by the Endurain watch app', () async {
      final diagnostics = RecordingDiagnostics();
      final health = _FakeHealth(
        hasPermissionsResult: true,
        dataByType: {
          HealthDataType.WORKOUT: [
            _workoutPoint(
              start: start,
              end: end,
              uuid: 'from-watch',
              sourceId: 'com.endurain.endurain.watchkitapp',
            ),
            _workoutPoint(start: start, end: end, uuid: 'from-elsewhere'),
          ],
        },
      );
      final adapter = HealthPackagePlatformAdapter(
        health: health,
        diagnostics: diagnostics,
        targetPlatform: () => TargetPlatform.iOS,
      );

      final workouts = await adapter.readWorkouts(start: start, end: end);

      expect(workouts.map((w) => w.sourceId), ['from-elsewhere']);
      expect(
        diagnostics.single(DiagnosticsEvents.healthReadWorkouts),
        containsPair('companion_watch_skipped', 1),
      );
    });

    test('returns nothing when every workout came from the watch', () async {
      final health = _FakeHealth(
        hasPermissionsResult: true,
        dataByType: {
          HealthDataType.WORKOUT: [
            _workoutPoint(
              start: start,
              end: end,
              sourceId: 'com.endurain.endurain.watchkitapp',
            ),
          ],
        },
      );
      final adapter = HealthPackagePlatformAdapter(
        health: health,
        targetPlatform: () => TargetPlatform.iOS,
      );

      expect(await adapter.readWorkouts(start: start, end: end), isEmpty);
    });
  });

  group('HealthPackagePlatformAdapter — Health Connect history window', () {
    final now = DateTime.utc(2026, 7, 17, 12);
    final cutoff = now.subtract(const Duration(days: 30));
    final safeRecentStart = cutoff.add(const Duration(minutes: 5));

    _FakeHealth fakeWith({
      required DateTime workoutStart,
      bool historyAvailable = false,
      bool historyAuthorized = false,
      bool requestHistoryResult = false,
    }) {
      return _FakeHealth(
        hasPermissionsResult: true,
        historyAvailable: historyAvailable,
        historyAuthorized: historyAuthorized,
        requestHistoryResult: requestHistoryResult,
        dataByType: {
          HealthDataType.WORKOUT: [
            _workoutPoint(
              start: workoutStart,
              end: workoutStart.add(const Duration(hours: 1)),
            ),
          ],
        },
      );
    }

    test('recent window reads as-is without touching history', () async {
      final requestedStart = now.subtract(const Duration(days: 10));
      final health = fakeWith(workoutStart: requestedStart);
      final adapter = HealthPackagePlatformAdapter(
        health: health,
        targetPlatform: () => TargetPlatform.android,
        now: () => now,
      );

      final workouts = await adapter.readWorkouts(
        start: requestedStart,
        end: now,
      );

      expect(workouts, hasLength(1));
      expect(health.lastWorkoutReadStart, requestedStart);
      expect(health.historyAvailableCallCount, 0);
      expect(health.requestHistoryCallCount, 0);
    });

    test(
      'historical window reads full range when already authorized',
      () async {
        final requestedStart = now.subtract(const Duration(days: 90));
        final health = fakeWith(
          workoutStart: requestedStart,
          historyAvailable: true,
          historyAuthorized: true,
        );
        final adapter = HealthPackagePlatformAdapter(
          health: health,
          targetPlatform: () => TargetPlatform.android,
          now: () => now,
        );

        final workouts = await adapter.readWorkouts(
          start: requestedStart,
          end: now,
        );

        expect(workouts, hasLength(1));
        expect(health.lastWorkoutReadStart, requestedStart);
        expect(health.requestHistoryCallCount, 0);
      },
    );

    test('historical window requests history and reads full range when '
        'granted', () async {
      final requestedStart = now.subtract(const Duration(days: 90));
      final health = fakeWith(
        workoutStart: requestedStart,
        historyAvailable: true,
        requestHistoryResult: true,
      );
      final adapter = HealthPackagePlatformAdapter(
        health: health,
        targetPlatform: () => TargetPlatform.android,
        now: () => now,
      );

      final workouts = await adapter.readWorkouts(
        start: requestedStart,
        end: now,
      );

      expect(workouts, hasLength(1));
      expect(health.requestHistoryCallCount, 1);
      expect(health.lastWorkoutReadStart, requestedStart);
    });

    test(
      'clamps to the recent window when history is declined (no throw)',
      () async {
        final requestedStart = now.subtract(const Duration(days: 90));
        final health = fakeWith(
          workoutStart: now.subtract(const Duration(days: 10)),
          historyAvailable: true,
          requestHistoryResult: false,
        );
        final adapter = HealthPackagePlatformAdapter(
          health: health,
          targetPlatform: () => TargetPlatform.android,
          now: () => now,
        );

        final workouts = await adapter.readWorkouts(
          start: requestedStart,
          end: now,
        );

        expect(workouts, hasLength(1));
        expect(health.requestHistoryCallCount, 1);
        expect(health.lastWorkoutReadStart, safeRecentStart);
      },
    );

    test('reads full range when the history feature is unavailable', () async {
      final requestedStart = now.subtract(const Duration(days: 90));
      final health = fakeWith(workoutStart: requestedStart);
      final adapter = HealthPackagePlatformAdapter(
        health: health,
        targetPlatform: () => TargetPlatform.android,
        now: () => now,
      );

      final workouts = await adapter.readWorkouts(
        start: requestedStart,
        end: now,
      );

      expect(workouts, hasLength(1));
      expect(health.lastWorkoutReadStart, requestedStart);
      expect(health.requestHistoryCallCount, 0);
    });

    test(
      'older-than-window page skips the read when history is declined',
      () async {
        final requestedStart = now.subtract(const Duration(days: 90));
        final pageEnd = now.subtract(const Duration(days: 40));
        final health = fakeWith(
          workoutStart: requestedStart,
          historyAvailable: true,
          requestHistoryResult: false,
        );
        final adapter = HealthPackagePlatformAdapter(
          health: health,
          targetPlatform: () => TargetPlatform.android,
          now: () => now,
        );

        final workouts = await adapter.readWorkouts(
          start: requestedStart,
          end: pageEnd,
        );

        expect(workouts, isEmpty);
        expect(health.lastWorkoutReadStart, isNull);
      },
    );

    test('reports declined history so callers stop paging back', () async {
      final health = _FakeHealth(
        hasPermissionsResult: true,
        historyAvailable: true,
        requestHistoryResult: false,
        dataByType: {
          HealthDataType.WORKOUT: [
            _workoutPoint(
              start: now.subtract(const Duration(days: 10)),
              end: now.subtract(const Duration(days: 10, hours: -1)),
            ),
          ],
          HealthDataType.WORKOUT_ROUTE: [
            _routePoint(
              start: now.subtract(const Duration(days: 10)),
              end: now.subtract(const Duration(days: 10, hours: -1)),
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
        now: () => now,
      );

      await adapter.readWorkouts(
        start: now.subtract(const Duration(days: 30)),
        end: now,
      );
      expect(adapter.historyAccessDeclined, isFalse);
      expect(adapter.routeConsentDeniedCount, 1);

      // An older page: history is declined and the read returns early.
      final older = await adapter.readWorkouts(
        start: now.subtract(const Duration(days: 60)),
        end: now.subtract(const Duration(days: 30)),
      );
      expect(older, isEmpty);
      expect(adapter.historyAccessDeclined, isTrue);
      expect(adapter.routeConsentDeniedCount, 0);
    });

    test('non-Android platforms ignore the 30-day window', () async {
      final requestedStart = now.subtract(const Duration(days: 365));
      final health = fakeWith(
        workoutStart: requestedStart,
        historyAvailable: true,
      );
      final adapter = HealthPackagePlatformAdapter(
        health: health,
        targetPlatform: () => TargetPlatform.iOS,
        now: () => now,
      );

      final workouts = await adapter.readWorkouts(
        start: requestedStart,
        end: now,
      );

      expect(workouts, hasLength(1));
      expect(health.lastWorkoutReadStart, requestedStart);
      expect(health.historyAvailableCallCount, 0);
      expect(health.requestHistoryCallCount, 0);
    });
  });

  group('HealthPackagePlatformAdapter iOS route assignment', () {
    final firstStart = DateTime.utc(2026, 7, 1, 9);
    final firstEnd = DateTime.utc(2026, 7, 1, 10);
    final secondStart = DateTime.utc(2026, 7, 1, 10, 0, 30);
    final secondEnd = DateTime.utc(2026, 7, 1, 11);

    WorkoutRouteLocation at(DateTime time, double latitude) =>
        WorkoutRouteLocation(
          latitude: latitude,
          longitude: -8.6,
          timestamp: time,
        );

    _FakeHealth backToBack() => _FakeHealth(
      hasPermissionsResult: true,
      dataByType: {
        HealthDataType.WORKOUT: [
          _workoutPoint(start: firstStart, end: firstEnd, uuid: 'first'),
          _workoutPoint(start: secondStart, end: secondEnd, uuid: 'second'),
        ],
        HealthDataType.WORKOUT_ROUTE: [
          // Routes arrive newest first and carry no workout UUID on iOS.
          _routePoint(
            uuid: 'route-second',
            start: secondStart,
            end: secondEnd,
            metadata: const {},
            locations: [at(secondStart, 2)],
          ),
          _routePoint(
            uuid: 'route-first-b',
            start: firstStart.add(const Duration(minutes: 30)),
            end: firstEnd,
            metadata: const {},
            locations: [at(firstStart.add(const Duration(minutes: 30)), 1.5)],
          ),
          _routePoint(
            uuid: 'route-first-a',
            start: firstStart,
            end: firstStart.add(const Duration(minutes: 30)),
            metadata: const {},
            locations: [at(firstStart, 1)],
          ),
        ],
      },
    );

    test(
      'back-to-back workouts keep only their own tracks, in order',
      () async {
        final adapter = HealthPackagePlatformAdapter(
          health: backToBack(),
          targetPlatform: () => TargetPlatform.iOS,
        );

        final workouts = await adapter.readWorkouts(
          start: firstStart,
          end: secondEnd,
        );
        final bySource = {for (final w in workouts) w.sourceId: w};

        expect(bySource['first']!.route.map((p) => p.latitude), [1, 1.5]);
        expect(bySource['second']!.route.map((p) => p.latitude), [2]);
      },
    );

    test('a skipped workout keeps its route from its neighbour', () async {
      final adapter = HealthPackagePlatformAdapter(
        health: backToBack(),
        targetPlatform: () => TargetPlatform.iOS,
      );

      final workouts = await adapter.readWorkouts(
        start: firstStart,
        end: secondEnd,
        exclude: (sourceId) async => sourceId == 'second',
      );

      expect(workouts.map((w) => w.sourceId), ['first']);
      expect(workouts.single.route.map((p) => p.latitude), [1, 1.5]);
    });
  });

  group('HealthPackagePlatformAdapter heart rate', () {
    final start = DateTime.utc(2026, 11, 5, 9);
    final end = DateTime.utc(2026, 11, 5, 10);

    /// A route with one point per second for [seconds] seconds from [start].
    List<WorkoutRouteLocation> routeEverySecond(int seconds) => [
      for (var i = 0; i < seconds; i++)
        WorkoutRouteLocation(
          latitude: 41.1,
          longitude: -8.6,
          timestamp: start.add(Duration(seconds: i)),
        ),
    ];

    _FakeHealth healthWith({
      required List<WorkoutRouteLocation> route,
      List<HealthDataPoint> heartRate = const [],
    }) {
      return _FakeHealth(
        hasPermissionsResult: true,
        dataByType: {
          HealthDataType.WORKOUT: [_workoutPoint(start: start, end: end)],
          HealthDataType.WORKOUT_ROUTE: [
            _routePoint(
              start: start,
              end: end,
              metadata: const {'workout_uuid': 'workout-1'},
              locations: route,
            ),
          ],
          HealthDataType.HEART_RATE: heartRate,
        },
      );
    }

    test('reads each workout window through the series reader', () async {
      final reader = _FakeHeartRateSeriesReader([
        for (var i = 0; i < 6; i++)
          _reading(start.add(Duration(seconds: i * 5)), 150.0 + i),
      ]);
      final health = healthWith(
        route: routeEverySecond(30),
        // A condensed series as the plugin reports it: must not be used.
        heartRate: [_hrPoint(start: start, end: end, bpm: 99)],
      );
      final diagnostics = RecordingDiagnostics();
      final adapter = HealthPackagePlatformAdapter(
        health: health,
        diagnostics: diagnostics,
        targetPlatform: () => TargetPlatform.iOS,
        heartRateSeriesReader: reader,
      );

      final workouts = await adapter.readWorkouts(start: start, end: end);

      expect(reader.windows, [
        (
          start: start.subtract(const Duration(minutes: 1)),
          end: end.add(const Duration(minutes: 1)),
        ),
      ]);
      expect(health.heartRateReadCount, 0);
      final hr = workouts.single.route.map((p) => p.heartRate).toList();
      expect(hr, everyElement(isNotNull));
      expect(hr.first, 150);
      expect(hr[12], 152); // nearer to the 10 s reading than the 15 s one
      expect(hr.last, 155);
      expect(
        diagnostics.single(DiagnosticsEvents.healthReadWorkouts),
        allOf(
          containsPair('heart_rate_source', 'series'),
          containsPair('heart_rate_readings', 6),
          containsPair('route_points_with_heart_rate', 30),
        ),
      );
    });

    test('a reading interval covers every route point inside it', () async {
      final reader = _FakeHeartRateSeriesReader([
        _reading(start, 140, end: start.add(const Duration(seconds: 40))),
      ]);
      final adapter = HealthPackagePlatformAdapter(
        health: healthWith(route: routeEverySecond(41)),
        targetPlatform: () => TargetPlatform.iOS,
        heartRateSeriesReader: reader,
      );

      final workouts = await adapter.readWorkouts(start: start, end: end);

      expect(workouts.single.route.map((p) => p.heartRate), everyElement(140));
    });

    test(
      'an earlier long reading covers points past a later short one',
      () async {
        // Overlapping sources: a long interval, and an instant inside it.
        final reader = _FakeHeartRateSeriesReader([
          _reading(start, 120, end: start.add(const Duration(seconds: 50))),
          _reading(start.add(const Duration(seconds: 10)), 150),
          _reading(
            start.add(const Duration(seconds: 20)),
            130,
            end: start.add(const Duration(seconds: 40)),
          ),
        ]);
        final adapter = HealthPackagePlatformAdapter(
          health: healthWith(route: routeEverySecond(61)),
          targetPlatform: () => TargetPlatform.iOS,
          heartRateSeriesReader: reader,
        );

        final workouts = await adapter.readWorkouts(start: start, end: end);
        final hr = workouts.single.route.map((p) => p.heartRate).toList();

        // 20 s past the instant, but still inside the long reading.
        expect(hr[30], 120);
        // Covered by both long readings: the earliest-starting one wins.
        expect(hr[25], 120);
        // The instant covers this point too; the earliest-starting still wins.
        expect(hr[10], 120);
        // Uncovered: the long reading ended 10 s before, while the reading that
        // started last ended 20 s before.
        expect(hr[60], 120);
      },
    );

    test('bridges gaps up to 20 s but not longer ones', () async {
      final reader = _FakeHeartRateSeriesReader([
        _reading(start, 150),
        _reading(start.add(const Duration(seconds: 14)), 160),
        _reading(start.add(const Duration(seconds: 40)), 170),
      ]);
      final adapter = HealthPackagePlatformAdapter(
        health: healthWith(route: routeEverySecond(41)),
        targetPlatform: () => TargetPlatform.iOS,
        heartRateSeriesReader: reader,
      );

      final workouts = await adapter.readWorkouts(start: start, end: end);
      final hr = workouts.single.route.map((p) => p.heartRate).toList();

      // 14 s gap: every point is within 7 s of a reading.
      expect(hr.sublist(0, 15), everyElement(isNotNull));
      expect(hr[7], 150); // tie: the earlier reading wins
      // 26 s gap: points more than 10 s from both readings get none.
      expect(hr[24], 160);
      expect(hr[25], isNull);
      expect(hr[29], isNull);
      expect(hr[30], 170);
    });

    test('falls back to the plugin read when the series read fails', () async {
      final diagnostics = RecordingDiagnostics();
      final health = healthWith(
        route: routeEverySecond(3),
        heartRate: [_hrPoint(start: start, end: start, bpm: 120)],
      );
      final adapter = HealthPackagePlatformAdapter(
        health: health,
        diagnostics: diagnostics,
        targetPlatform: () => TargetPlatform.iOS,
        heartRateSeriesReader: _FakeHeartRateSeriesReader(
          const [],
          error: PlatformException(code: 'DEVICE_LOCKED'),
        ),
      );

      final workouts = await adapter.readWorkouts(start: start, end: end);

      expect(health.heartRateReadCount, 1);
      expect(workouts.single.route.map((p) => p.heartRate), everyElement(120));
      expect(
        diagnostics.events,
        contains(DiagnosticsEvents.healthHeartRateSeriesFailed),
      );
      expect(
        diagnostics.single(DiagnosticsEvents.healthReadWorkouts),
        containsPair('heart_rate_source', 'samples_fallback'),
      );
    });

    test('reads plugin heart rate per workout window on Android', () async {
      final secondStart = start.add(const Duration(hours: 5));
      final secondEnd = secondStart.add(const Duration(hours: 1));
      final health = _FakeHealth(
        hasPermissionsResult: true,
        dataByType: {
          HealthDataType.WORKOUT: [
            _workoutPoint(start: start, end: end, uuid: 'first'),
            _workoutPoint(start: secondStart, end: secondEnd, uuid: 'second'),
            _workoutPoint(
              start: secondEnd.add(const Duration(hours: 1)),
              end: secondEnd.add(const Duration(hours: 2)),
              uuid: 'imported',
            ),
          ],
        },
      );
      final adapter = HealthPackagePlatformAdapter(
        health: health,
        targetPlatform: () => TargetPlatform.android,
      );

      final workouts = await adapter.readWorkouts(
        start: start,
        end: secondEnd.add(const Duration(hours: 3)),
        exclude: (sourceId) async => sourceId == 'imported',
      );

      expect(workouts.map((w) => w.sourceId), ['first', 'second']);
      // One read per remaining workout, never the whole page, and none for
      // the skipped one.
      expect(health.heartRateReadWindows, [
        (
          start: start.subtract(const Duration(minutes: 1)),
          end: end.add(const Duration(minutes: 1)),
        ),
        (
          start: secondStart.subtract(const Duration(minutes: 1)),
          end: secondEnd.add(const Duration(minutes: 1)),
        ),
      ]);
    });

    test('does not read heart rate when every workout is skipped', () async {
      final health = healthWith(route: routeEverySecond(3));
      final adapter = HealthPackagePlatformAdapter(
        health: health,
        targetPlatform: () => TargetPlatform.android,
      );

      final workouts = await adapter.readWorkouts(
        start: start,
        end: end,
        exclude: (_) async => true,
      );

      expect(workouts, isEmpty);
      expect(health.heartRateReadCount, 0);
    });

    test('a failed heart rate read fails the read instead of dropping it', () {
      final health = _FakeHealth(
        hasPermissionsResult: true,
        dataByType: {
          HealthDataType.WORKOUT: [_workoutPoint(start: start, end: end)],
        },
        errorByType: {
          HealthDataType.HEART_RATE: HealthPlatformException(
            HealthDataType.HEART_RATE,
            PlatformException(code: 'RATE_LIMIT_EXCEEDED'),
          ),
        },
      );
      final adapter = HealthPackagePlatformAdapter(
        health: health,
        targetPlatform: () => TargetPlatform.android,
      );

      expect(
        adapter.readWorkouts(start: start, end: end),
        throwsA(
          isA<AppException>()
              .having((e) => e.code, 'code', AppErrorCode.healthReadFailed)
              .having((e) => e.isTransient, 'isTransient', isTrue),
        ),
      );
    });

    test('fails the read when the series and plugin reads both fail', () {
      final health = _FakeHealth(
        hasPermissionsResult: true,
        dataByType: {
          HealthDataType.WORKOUT: [_workoutPoint(start: start, end: end)],
        },
        errorByType: {HealthDataType.HEART_RATE: StateError('boom')},
      );
      final adapter = HealthPackagePlatformAdapter(
        health: health,
        targetPlatform: () => TargetPlatform.iOS,
        heartRateSeriesReader: _FakeHeartRateSeriesReader(
          const [],
          error: PlatformException(code: 'DEVICE_LOCKED'),
        ),
      );

      expect(
        adapter.readWorkouts(start: start, end: end),
        throwsA(
          isA<AppException>().having(
            (e) => e.code,
            'code',
            AppErrorCode.healthReadFailed,
          ),
        ),
      );
    });

    test('without a series reader, plugin samples cover their interval', () {
      final health = healthWith(
        route: routeEverySecond(20),
        heartRate: [
          _hrPoint(
            start: start,
            end: start.add(const Duration(seconds: 19)),
            bpm: 133,
          ),
        ],
      );
      final adapter = HealthPackagePlatformAdapter(
        health: health,
        targetPlatform: () => TargetPlatform.android,
      );

      expect(
        adapter
            .readWorkouts(start: start, end: end)
            .then((w) => w.single.route.map((p) => p.heartRate)),
        completion(everyElement(133)),
      );
    });
  });

  group('read failures', () {
    final start = DateTime.utc(2025, 6, 1);
    final end = DateTime.utc(2025, 6, 2);

    Future<AppException> readFailure(Object error) async {
      final adapter = HealthPackagePlatformAdapter(
        health: _FakeHealth(hasPermissionsResult: true, readError: error),
        targetPlatform: () => TargetPlatform.android,
      );
      try {
        await adapter.readWorkouts(start: start, end: end);
      } on AppException catch (e) {
        return e;
      }
      fail('readWorkouts did not throw');
    }

    test('flags a retryable platform error as transient', () async {
      final error = await readFailure(
        HealthPlatformException(
          HealthDataType.WORKOUT,
          PlatformException(code: 'UNAVAILABLE'),
        ),
      );

      expect(error.code, AppErrorCode.healthReadFailed);
      expect(error.isTransient, isTrue);
    });

    test('does not flag a lasting platform error as transient', () async {
      final error = await readFailure(
        HealthPlatformException(
          HealthDataType.WORKOUT,
          PlatformException(code: 'DATA_TOO_LARGE'),
        ),
      );

      expect(error.code, AppErrorCode.healthReadFailed);
      expect(error.isTransient, isFalse);
    });

    test('reports a missing permission as a permission denial', () async {
      final error = await readFailure(
        HealthPlatformException(
          HealthDataType.WORKOUT,
          PlatformException(code: 'PERMISSION_DENIED'),
        ),
      );

      expect(error.code, AppErrorCode.healthPermissionDenied);
      expect(error.isTransient, isFalse);
    });

    test('does not flag an unclassified error as transient', () async {
      final error = await readFailure(StateError('boom'));

      expect(error.code, AppErrorCode.healthReadFailed);
      expect(error.isTransient, isFalse);
    });
  });

  group('HealthPackagePlatformAdapter background access', () {
    HealthPackagePlatformAdapter androidAdapter(_FakeHealth health) =>
        HealthPackagePlatformAdapter(
          health: health,
          targetPlatform: () => TargetPlatform.android,
        );

    test('needs no extra permission on iOS', () async {
      final adapter = HealthPackagePlatformAdapter(
        health: _FakeHealth(hasPermissionsResult: null),
        targetPlatform: () => TargetPlatform.iOS,
      );

      expect(await adapter.hasBackgroundReadAccess(), isTrue);
      expect(await adapter.requestBackgroundReadAccess(), isTrue);
    });

    test('needs the Health Connect permission on Android', () async {
      final health = _FakeHealth(
        hasPermissionsResult: true,
        backgroundAvailable: true,
      );

      expect(await androidAdapter(health).hasBackgroundReadAccess(), isFalse);
      expect(health.requestBackgroundCallCount, 0);
    });

    test('asks for the permission only when it is missing', () async {
      final missing = _FakeHealth(
        hasPermissionsResult: true,
        backgroundAvailable: true,
        requestBackgroundResult: true,
      );
      final held = _FakeHealth(
        hasPermissionsResult: true,
        backgroundAvailable: true,
        backgroundAuthorized: true,
      );

      expect(
        await androidAdapter(missing).requestBackgroundReadAccess(),
        isTrue,
      );
      expect(missing.requestBackgroundCallCount, 1);
      expect(await androidAdapter(held).requestBackgroundReadAccess(), isTrue);
      expect(held.requestBackgroundCallCount, 0);
    });

    test('is unavailable without the Health Connect feature', () async {
      final health = _FakeHealth(
        hasPermissionsResult: true,
        backgroundAuthorized: true,
      );

      expect(await androidAdapter(health).hasBackgroundReadAccess(), isFalse);
      expect(
        await androidAdapter(health).requestBackgroundReadAccess(),
        isFalse,
      );
      expect(health.requestBackgroundCallCount, 0);
    });

    test('maps a missing Health Connect to healthUnavailable', () async {
      final health = _FakeHealth(
        hasPermissionsResult: true,
        backgroundAvailable: true,
        requestBackgroundError: UnsupportedError('Health Connect missing'),
      );

      await expectLater(
        androidAdapter(health).requestBackgroundReadAccess(),
        throwsA(
          isA<AppException>().having(
            (error) => error.code,
            'code',
            AppErrorCode.healthUnavailable,
          ),
        ),
      );
    });
  });

  group('HealthPackagePlatformAdapter workout changes', () {
    test('reads changes through the injected reader', () async {
      final health = _FakeHealth(hasPermissionsResult: true);
      final adapter = HealthPackagePlatformAdapter(
        health: health,
        workoutChangesReader: _FakeChangesReader(),
      );

      expect(await adapter.workoutChangesToken(), 'anchors');
      final changes = await adapter.workoutChangesSince('anchors');

      expect(changes.nextToken, 'anchors-next');
      expect(health.configureCallCount, 1);
    });

    test('maps a failed read to healthReadFailed', () async {
      final adapter = HealthPackagePlatformAdapter(
        health: _FakeHealth(hasPermissionsResult: true),
        workoutChangesReader: _FakeChangesReader(error: StateError('locked')),
      );

      await expectLater(
        adapter.workoutChangesToken(),
        throwsA(
          isA<AppException>().having(
            (error) => error.code,
            'code',
            AppErrorCode.healthReadFailed,
          ),
        ),
      );
      await expectLater(
        adapter.workoutChangesSince('anchors'),
        throwsA(isA<AppException>()),
      );
    });
  });
}

class _FakeChangesReader implements HealthWorkoutChangesReader {
  _FakeChangesReader({this.error});

  final Error? error;

  @override
  Future<String> currentToken() async {
    if (error case final error?) throw error;
    return 'anchors';
  }

  @override
  Future<HealthWorkoutChanges> changesSince(String token) async {
    if (error case final error?) throw error;
    return HealthWorkoutChanges(nextToken: '$token-next');
  }
}

class _FakeHealth extends Health {
  _FakeHealth({
    required this.hasPermissionsResult,
    this.requestAuthorizationResult = false,
    this.dataByType = const {},
    this.historyAvailable = false,
    this.historyAuthorized = false,
    this.requestHistoryResult = false,
    this.readError,
    this.errorByType = const {},
    this.authError,
    this.backgroundAvailable = false,
    this.backgroundAuthorized = false,
    this.requestBackgroundResult = false,
    this.requestBackgroundError,
  });

  final bool backgroundAvailable;
  final bool backgroundAuthorized;
  final bool requestBackgroundResult;

  /// Thrown by requestHealthDataInBackgroundAuthorization when set.
  final Object? requestBackgroundError;
  int requestBackgroundCallCount = 0;

  final bool? hasPermissionsResult;

  /// Thrown by requestAuthorization and hasPermissions when set.
  final Object? authError;

  /// Thrown by every data read when set.
  final Object? readError;

  /// Thrown by reads of the given type.
  final Map<HealthDataType, Object> errorByType;
  final List<({DateTime start, DateTime end})> heartRateReadWindows = [];
  final bool requestAuthorizationResult;
  final Map<HealthDataType, List<HealthDataPoint>> dataByType;
  final bool historyAvailable;
  final bool historyAuthorized;
  final bool requestHistoryResult;
  int configureCallCount = 0;
  int heartRateReadCount = 0;
  int historyAvailableCallCount = 0;
  int historyAuthorizedCallCount = 0;
  int requestHistoryCallCount = 0;
  DateTime? lastWorkoutReadStart;
  List<HealthDataType>? lastHasPermissionTypes;
  List<HealthDataAccess>? lastHasPermissionAccess;
  List<HealthDataType>? lastRequestAuthorizationTypes;
  List<HealthDataAccess>? lastRequestAuthorizationAccess;

  @override
  Future<void> configure() async {
    configureCallCount++;
  }

  @override
  Future<bool> isHealthDataInBackgroundAvailable() async => backgroundAvailable;

  @override
  Future<bool> isHealthDataInBackgroundAuthorized() async =>
      backgroundAuthorized;

  @override
  Future<bool> requestHealthDataInBackgroundAuthorization() async {
    requestBackgroundCallCount++;
    if (requestBackgroundError case final error?) {
      Error.throwWithStackTrace(error, StackTrace.current);
    }
    return requestBackgroundResult;
  }

  @override
  Future<bool> isHealthDataHistoryAvailable() async {
    historyAvailableCallCount++;
    return historyAvailable;
  }

  @override
  Future<bool> isHealthDataHistoryAuthorized() async {
    historyAuthorizedCallCount++;
    return historyAuthorized;
  }

  @override
  Future<bool> requestHealthDataHistoryAuthorization() async {
    requestHistoryCallCount++;
    return requestHistoryResult;
  }

  @override
  Future<bool?> hasPermissions(
    List<HealthDataType> types, {
    List<HealthDataAccess>? permissions,
  }) async {
    if (authError case final error?) {
      Error.throwWithStackTrace(error, StackTrace.current);
    }
    lastHasPermissionTypes = types;
    lastHasPermissionAccess = permissions;
    return hasPermissionsResult;
  }

  @override
  Future<bool> requestAuthorization(
    List<HealthDataType> types, {
    List<HealthDataAccess>? permissions,
  }) async {
    if (authError case final error?) {
      Error.throwWithStackTrace(error, StackTrace.current);
    }
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
    int? limit,
  }) async {
    final error = readError;
    if (error != null) {
      Error.throwWithStackTrace(error, StackTrace.current);
    }
    if (types.contains(HealthDataType.WORKOUT)) {
      lastWorkoutReadStart = startTime;
    }
    if (types.contains(HealthDataType.HEART_RATE)) {
      heartRateReadCount++;
      heartRateReadWindows.add((start: startTime, end: endTime));
    }
    for (final type in types) {
      final typeError = errorByType[type];
      if (typeError != null) {
        Error.throwWithStackTrace(typeError, StackTrace.current);
      }
    }
    return [for (final type in types) ...?dataByType[type]];
  }
}

HealthDataPoint _workoutPoint({
  required DateTime start,
  required DateTime end,
  String uuid = 'workout-1',
  String sourceId = 'source',
}) {
  return HealthDataPoint(
    uuid: uuid,
    value: WorkoutHealthValue(
      workoutActivityType: HealthWorkoutActivityType.RUNNING,
    ),
    type: HealthDataType.WORKOUT,
    unit: HealthDataUnit.NO_UNIT,
    dateFrom: start,
    dateTo: end,
    sourcePlatform: HealthPlatformType.googleHealthConnect,
    sourceDeviceId: 'device',
    sourceId: sourceId,
    sourceName: 'source',
  );
}

HealthDataPoint _routePoint({
  required DateTime start,
  required DateTime end,
  required Map<String, dynamic> metadata,
  List<WorkoutRouteLocation> locations = const [],
  String uuid = 'route-1',
}) {
  return HealthDataPoint(
    uuid: uuid,
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

HealthDataPoint _hrPoint({
  required DateTime start,
  required DateTime end,
  required num bpm,
}) {
  return HealthDataPoint(
    uuid: 'hr-${start.millisecondsSinceEpoch}',
    value: NumericHealthValue(numericValue: bpm),
    type: HealthDataType.HEART_RATE,
    unit: HealthDataUnit.BEATS_PER_MINUTE,
    dateFrom: start,
    dateTo: end,
    sourcePlatform: HealthPlatformType.appleHealth,
    sourceDeviceId: 'device',
    sourceId: 'source',
    sourceName: 'source',
  );
}

HeartRateReading _reading(DateTime start, double bpm, {DateTime? end}) =>
    HeartRateReading(start: start, end: end ?? start, bpm: bpm);

class _FakeHeartRateSeriesReader implements HeartRateSeriesReader {
  _FakeHeartRateSeriesReader(this.readings, {this.error});

  final List<HeartRateReading> readings;
  final Object? error;
  final List<({DateTime start, DateTime end})> windows = [];

  @override
  Future<List<HeartRateReading>> read({
    required DateTime start,
    required DateTime end,
  }) async {
    windows.add((start: start, end: end));
    final failure = error;
    if (failure != null) {
      Error.throwWithStackTrace(failure, StackTrace.current);
    }
    return readings;
  }
}
