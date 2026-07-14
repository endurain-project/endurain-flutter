import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/services/diagnostics_service.dart';
import 'package:endurain/features/health/models/health_authorization_status.dart';
import 'package:endurain/features/health/models/health_data_access_details.dart';
import 'package:endurain/features/health/models/health_route_point.dart';
import 'package:endurain/features/health/models/health_sdk_status.dart';
import 'package:endurain/features/health/models/health_workout.dart';
import 'package:endurain/features/health/models/health_workout_type.dart';
import 'package:endurain/features/health/services/health_platform_adapter.dart';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

const _coreReadTypes = [
  HealthDataType.WORKOUT,
  HealthDataType.WORKOUT_ROUTE,
  HealthDataType.HEART_RATE,
];

const _androidEnrichmentReadTypes = [
  HealthDataType.DISTANCE_DELTA,
  HealthDataType.TOTAL_CALORIES_BURNED,
  HealthDataType.STEPS,
];

const _healthConnectHistoryWindow = Duration(days: 30);

/// [HealthPlatformAdapter] backed by the `health` Flutter package.
///
/// Connects to HealthKit on iOS and Health Connect on Android. Inject a
/// [Health] instance for unit testing (no native calls in tests).
class HealthPackagePlatformAdapter implements HealthPlatformAdapter {
  HealthPackagePlatformAdapter({
    Health? health,
    DiagnosticsRecorder? diagnostics,
    TargetPlatform Function()? targetPlatform,
  }) : _health = health ?? Health(),
       _diagnostics = diagnostics ?? const NoopDiagnosticsRecorder(),
       _targetPlatform = targetPlatform ?? _defaultTargetPlatform;

  final Health _health;
  final DiagnosticsRecorder _diagnostics;
  final TargetPlatform Function() _targetPlatform;
  int _routeConsentDeniedCount = 0;
  Future<void>? _configureOnce;

  static TargetPlatform _defaultTargetPlatform() => defaultTargetPlatform;

  List<HealthDataType> get _readTypes => [
    ..._coreReadTypes,
    if (_targetPlatform() == TargetPlatform.android)
      ..._androidEnrichmentReadTypes,
  ];

  List<HealthDataAccess> get _readAccess =>
      List.filled(_readTypes.length, HealthDataAccess.READ);

  @override
  int get routeConsentDeniedCount => _routeConsentDeniedCount;

  /// The `health` plugin requires [Health.configure] to be called exactly once
  /// before any other call. Without it, iOS HealthKit calls fail before a
  /// permission prompt can be shown. The future is cached so configuration
  /// runs only once for the lifetime of this adapter.
  Future<void> _ensureConfigured() {
    return _configureOnce ??= _health.configure();
  }

  // ── Status & authorization ──────────────────────────────────────────────

  @override
  Future<HealthSdkStatus> getSdkStatus() async {
    try {
      await _ensureConfigured();
      if (_targetPlatform() == TargetPlatform.iOS) {
        return HealthSdkStatus.available;
      }
      if (_targetPlatform() != TargetPlatform.android) {
        return HealthSdkStatus.unsupported;
      }

      final status = await _health.getHealthConnectSdkStatus();
      // Record the raw platform SDK status (sanitized enum name only) so the
      // Diagnostics screen shows the ground-truth Health Connect availability.
      _diagnostics.recordBreadcrumbSync(
        'health_connect_sdk_status',
        details: {'status': status?.name ?? 'null'},
      );
      return switch (status) {
        HealthConnectSdkStatus.sdkAvailable => HealthSdkStatus.available,
        HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired =>
          HealthSdkStatus.needsProviderInstall,
        _ => HealthSdkStatus.unsupported,
      };
    } catch (_) {
      return HealthSdkStatus.unsupported;
    }
  }

  @override
  Future<HealthAuthorizationStatus> requestAuthorization() async {
    try {
      await _ensureConfigured();
      var granted = await _health.requestAuthorization(
        _readTypes,
        permissions: _readAccess,
      );
      if (granted && _targetPlatform() == TargetPlatform.android) {
        granted =
            await _health.hasPermissions(
              _readTypes,
              permissions: _readAccess,
            ) ==
            true;
      }
      _diagnostics.recordBreadcrumbSync(
        'health_request_authorization',
        details: {'granted': granted},
      );
      return granted
          ? HealthAuthorizationStatus.granted
          : HealthAuthorizationStatus.denied;
    } catch (e) {
      _diagnostics.recordBreadcrumbSync(
        'health_request_authorization_error',
        details: {'type': e.runtimeType.toString()},
      );
      throw const AppException(AppErrorCode.healthPermissionDenied);
    }
  }

  @override
  Future<HealthAuthorizationStatus> currentAuthorizationStatus() async {
    try {
      await _ensureConfigured();
      final hasPermissions = await _health.hasPermissions(
        _readTypes,
        permissions: _readAccess,
      );
      return switch (hasPermissions) {
        true => HealthAuthorizationStatus.granted,
        false => HealthAuthorizationStatus.denied,
        null => HealthAuthorizationStatus.notDetermined,
      };
    } catch (_) {
      return HealthAuthorizationStatus.denied;
    }
  }

  @override
  Future<HealthDataAccessDetails> getAccessDetails() async {
    // HealthKit deliberately hides read grants, including when authorization
    // has succeeded. Never infer or display individual iOS read permissions.
    if (_targetPlatform() == TargetPlatform.iOS) {
      return const HealthDataAccessDetails.systemManaged();
    }
    if (_targetPlatform() != TargetPlatform.android) {
      return const HealthDataAccessDetails.systemManaged();
    }

    try {
      await _ensureConfigured();
      final results = await Future.wait(
        _readTypes.map(
          (type) => _health.hasPermissions(
            [type],
            permissions: const [HealthDataAccess.READ],
          ),
        ),
      );
      return HealthDataAccessDetails(
        canInspectIndividualPermissions: true,
        workouts: _accessStatus(results[0]),
        workoutRoutes: _accessStatus(results[1]),
        heartRate: _accessStatus(results[2]),
        distance: _accessStatus(results[3]),
        calories: _accessStatus(results[4]),
        steps: _accessStatus(results[5]),
      );
    } catch (_) {
      return const HealthDataAccessDetails(
        canInspectIndividualPermissions: true,
      );
    }
  }

  HealthDataAccessStatus _accessStatus(bool? granted) {
    return granted == true
        ? HealthDataAccessStatus.allowed
        : HealthDataAccessStatus.needsAttention;
  }

  @override
  Future<void> installHealthConnect() async {
    if (_targetPlatform() != TargetPlatform.android) return;
    _diagnostics.recordBreadcrumbSync('health_install_provider_requested');
    await _health.installHealthConnect();
  }

  @override
  Future<void> revokePermissions() async {
    try {
      await _ensureConfigured();
      await _health.revokePermissions();
    } catch (error) {
      throw AppException(AppErrorCode.healthPermissionDenied, cause: error);
    }
  }

  // ── Workout reading ─────────────────────────────────────────────────────

  @override
  Future<List<HealthWorkout>> readWorkouts({
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      await _ensureConfigured();
      await _ensureHistoryAuthorization(start);
      _routeConsentDeniedCount = 0;
      // Step 1 — Fetch workout metadata.
      final workoutPoints = await _health.getHealthDataFromTypes(
        types: [HealthDataType.WORKOUT],
        startTime: start,
        endTime: end,
      );

      if (workoutPoints.isEmpty) return const [];

      // Step 2 — Fetch GPS routes for the same window.
      final routes = await _fetchRoutes(
        start: start,
        end: end,
        workoutCount: workoutPoints.length,
      );

      // Step 3 — Fetch heart rate samples for the same window.
      final hrPoints = await _fetchHeartRateSamples(start: start, end: end);

      // Step 4 — Map each workout data point to a HealthWorkout.
      final workouts = workoutPoints
          .map(
            (pt) => _mapWorkout(point: pt, routes: routes, hrSamples: hrPoints),
          )
          .whereType<HealthWorkout>()
          .toList();

      // Sanitized observability (counts only, never coordinates/PII): lets the
      // Diagnostics screen show where route correlation may be failing.
      _diagnostics.recordBreadcrumbSync(
        'health_read_workouts',
        details: {
          'workouts': workouts.length,
          'route_samples': routes.length,
          'route_locations': routes.fold<int>(
            0,
            (sum, r) => sum + r.locations.length,
          ),
          'routes_with_uuid': routes.where((r) => r.workoutUuid != null).length,
          'workouts_with_route': workouts.where((w) => w.hasRoute).length,
          'route_read_failed': _routeConsentDeniedCount > 0,
        },
      );

      return workouts;
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException(AppErrorCode.healthReadFailed, cause: e);
    }
  }

  Future<void> _ensureHistoryAuthorization(DateTime start) async {
    if (_targetPlatform() != TargetPlatform.android ||
        !start.isBefore(
          DateTime.now().toUtc().subtract(_healthConnectHistoryWindow),
        )) {
      return;
    }
    if (!await _health.isHealthDataHistoryAvailable()) return;
    if (await _health.isHealthDataHistoryAuthorized()) return;
    if (!await _health.requestHealthDataHistoryAuthorization()) {
      throw const AppException(AppErrorCode.healthPermissionDenied);
    }
  }

  // ── Private helpers ─────────────────────────────────────────────────────

  /// Fetches GPS route samples for the window.
  ///
  /// Each route is returned with its own time window so it can be correlated
  /// to a workout either by `workoutUuid` (Android / Health Connect) or, when
  /// that is absent, by time overlap (iOS — `HKWorkoutRoute` does not expose
  /// the owning workout's UUID).
  ///
  /// If the platform returns a consent-required error for third-party app
  /// routes, the affected workouts will simply have no route points
  /// (handled gracefully rather than throwing).
  Future<List<_RouteData>> _fetchRoutes({
    required DateTime start,
    required DateTime end,
    required int workoutCount,
  }) async {
    final result = <_RouteData>[];
    try {
      final points = await _health.getHealthDataFromTypes(
        types: [HealthDataType.WORKOUT_ROUTE],
        startTime: start,
        endTime: end,
      );
      for (final pt in points) {
        final value = pt.value;
        if (value is! WorkoutRouteHealthValue) continue;
        final metadata = pt.metadata;
        if (metadata?['route_requires_consent'] == true) {
          _routeConsentDeniedCount++;
          continue;
        }
        if (value.locations.isEmpty) continue;
        result.add(
          _RouteData(
            start: pt.dateFrom.toUtc(),
            end: pt.dateTo.toUtc(),
            workoutUuid:
                metadata?['workout_uuid'] as String? ?? value.workoutUuid,
            locations: value.locations,
          ),
        );
      }
    } catch (error) {
      throw AppException(AppErrorCode.healthReadFailed, cause: error);
    }
    return result;
  }

  /// Fetches heart rate samples and returns them sorted by time.
  Future<List<_HrSample>> _fetchHeartRateSamples({
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final points = await _health.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE],
        startTime: start,
        endTime: end,
      );
      final samples = <_HrSample>[];
      for (final pt in points) {
        final value = pt.value;
        if (value is! NumericHealthValue) continue;
        samples.add(
          _HrSample(time: pt.dateFrom, bpm: value.numericValue.round()),
        );
      }
      samples.sort((a, b) => a.time.compareTo(b.time));
      return samples;
    } catch (_) {
      return const [];
    }
  }

  /// Maps a WORKOUT [HealthDataPoint] into a [HealthWorkout].
  ///
  /// Returns `null` when the data point is not a workout type (should not
  /// happen in practice but guards against API changes).
  HealthWorkout? _mapWorkout({
    required HealthDataPoint point,
    required List<_RouteData> routes,
    required List<_HrSample> hrSamples,
  }) {
    final value = point.value;
    if (value is! WorkoutHealthValue) return null;

    final type = HealthWorkoutType.fromPlatformValue(
      value.workoutActivityType.name,
    );

    // Convert total distance to meters.
    double? distanceMeters;
    final rawDist = value.totalDistance;
    if (rawDist != null) {
      distanceMeters = switch (value.totalDistanceUnit) {
        HealthDataUnit.METER => rawDist.toDouble(),
        HealthDataUnit.MILE => rawDist * 1609.344,
        _ => rawDist.toDouble(), // default: assume metres
      };
    }

    // Convert total energy to kilocalories.
    double? energyKcal;
    final rawEnergy = value.totalEnergyBurned;
    if (rawEnergy != null) {
      energyKcal = switch (value.totalEnergyBurnedUnit) {
        HealthDataUnit.KILOCALORIE => rawEnergy.toDouble(),
        HealthDataUnit.JOULE => rawEnergy / 4184.0,
        _ => rawEnergy.toDouble(), // default: assume kcal
      };
    }

    final workoutStart = point.dateFrom.toUtc();
    final workoutEnd = point.dateTo.toUtc();

    // Merge GPS route + HR. Match routes by UUID when available (Android),
    // otherwise by time overlap (iOS).
    final locations = <WorkoutRouteLocation>[];
    for (final r in routes) {
      final matches = healthRouteMatchesWorkout(
        routeWorkoutUuid: r.workoutUuid,
        routeStart: r.start,
        routeEnd: r.end,
        workoutUuid: point.uuid,
        workoutStart: workoutStart,
        workoutEnd: workoutEnd,
      );
      if (matches) locations.addAll(r.locations);
    }
    final route = locations
        .map((loc) => _mergeHr(loc: loc, hrSamples: hrSamples))
        .toList();

    return HealthWorkout(
      sourceId: point.uuid,
      type: type,
      startedAt: workoutStart,
      endedAt: workoutEnd,
      distanceMeters: distanceMeters,
      energyKilocalories: energyKcal,
      route: route,
    );
  }

  /// Attaches a heart rate reading to a route point when a matching HR sample
  /// exists within ±5 seconds.
  HealthRoutePoint _mergeHr({
    required WorkoutRouteLocation loc,
    required List<_HrSample> hrSamples,
  }) {
    const toleranceMs = 5000;
    final targetMs = loc.timestamp.millisecondsSinceEpoch;
    final index = _lowerBound(hrSamples, targetMs);
    final candidates = <_HrSample>[
      if (index > 0) hrSamples[index - 1],
      if (index < hrSamples.length) hrSamples[index],
    ];
    int? hr;
    var closestDiff = toleranceMs + 1;
    for (final sample in candidates) {
      final diff = (sample.time.millisecondsSinceEpoch - targetMs).abs();
      if (diff <= toleranceMs && diff < closestDiff) {
        hr = sample.bpm;
        closestDiff = diff;
      }
    }
    return HealthRoutePoint(
      latitude: loc.latitude,
      longitude: loc.longitude,
      time: loc.timestamp.toUtc(),
      elevation: loc.altitude,
      heartRate: hr,
    );
  }

  int _lowerBound(List<_HrSample> samples, int targetMs) {
    var low = 0;
    var high = samples.length;
    while (low < high) {
      final middle = low + (high - low) ~/ 2;
      if (samples[middle].time.millisecondsSinceEpoch < targetMs) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    return low;
  }
}

/// Lightweight heart-rate sample (private to this file).
class _HrSample {
  const _HrSample({required this.time, required this.bpm});
  final DateTime time;
  final int bpm;
}

/// A GPS route sample with its own time window, used to correlate it to a
/// workout (private to this file).
class _RouteData {
  const _RouteData({
    required this.start,
    required this.end,
    required this.workoutUuid,
    required this.locations,
  });
  final DateTime start;
  final DateTime end;
  final String? workoutUuid;
  final List<WorkoutRouteLocation> locations;
}

/// Tolerance applied to the workout window when correlating a route by time.
const int _routeMatchToleranceMs = 60000;

/// Decides whether a GPS route belongs to a workout.
///
/// When the route carries its owning workout's UUID (Android / Health Connect)
/// the match is exact. On iOS `HKWorkoutRoute` does not expose that UUID, so we
/// fall back to time-overlap: a route belongs to the workout whose time window
/// it overlaps (workouts do not overlap one another), with a small tolerance
/// to absorb clock/rounding differences between the route and workout samples.
@visibleForTesting
bool healthRouteMatchesWorkout({
  required String? routeWorkoutUuid,
  required DateTime routeStart,
  required DateTime routeEnd,
  required String workoutUuid,
  required DateTime workoutStart,
  required DateTime workoutEnd,
}) {
  if (routeWorkoutUuid != null) {
    return routeWorkoutUuid == workoutUuid;
  }
  final routeStartMs = routeStart.millisecondsSinceEpoch;
  final routeEndMs = routeEnd.millisecondsSinceEpoch;
  final windowStartMs =
      workoutStart.millisecondsSinceEpoch - _routeMatchToleranceMs;
  final windowEndMs =
      workoutEnd.millisecondsSinceEpoch + _routeMatchToleranceMs;
  return routeStartMs <= windowEndMs && windowStartMs <= routeEndMs;
}
