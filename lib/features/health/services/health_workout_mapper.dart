import 'package:endurain/core/models/measurement_system.dart';
import 'package:endurain/features/health/models/health_route_point.dart';
import 'package:endurain/features/health/models/health_workout.dart';
import 'package:endurain/features/health/models/health_workout_type.dart';
import 'package:endurain/features/health/services/health_heart_rate_index.dart';
import 'package:endurain/features/health/services/health_route_correlation.dart';
import 'package:endurain/features/health/services/heart_rate_series_reader.dart';
import 'package:health/health.dart';

/// Health platform source ids (the writing app's bundle id or package name)
/// of Endurain's own companion watch apps.
///
/// Their workouts reach the phone through the watch transport, so Health Sync
/// never offers or imports them. Filtering by source (rather than only by the
/// health workout id a handoff carries) also covers a workout that syncs to
/// the phone's health store before the watch's own transfer arrives.
const companionWatchHealthSourceIds = {'com.endurain.endurain.watchkitapp'};

/// Padding around each workout when reading its heart rate series, so a
/// reading just before the start or after the end can still reach the first
/// or last route points.
const healthHeartRateWindowPadding = Duration(minutes: 1);

/// A GPS route sample with its own time window, used to correlate it to a
/// workout.
class HealthRouteData {
  const HealthRouteData({
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

/// Workout points split into the ones to import and the ones skipped.
class HealthWorkoutPartition {
  const HealthWorkoutPartition({
    required this.importable,
    required this.companionSkipped,
    required this.excludedSkipped,
  });

  /// Points left to import.
  final List<HealthDataPoint> importable;

  /// Workouts written by Endurain's companion watch app.
  final int companionSkipped;

  /// Workouts [partitionHealthWorkoutPoints] was told were already handled.
  final int excludedSkipped;
}

/// Drops companion-watch workouts and the ones [exclude] reports as already
/// handled.
Future<HealthWorkoutPartition> partitionHealthWorkoutPoints(
  List<HealthDataPoint> points, {
  Future<bool> Function(String sourceId)? exclude,
}) async {
  final importable = <HealthDataPoint>[];
  var companion = 0;
  var excluded = 0;
  for (final point in points) {
    if (companionWatchHealthSourceIds.contains(point.sourceId)) {
      companion++;
    } else if (exclude != null && await exclude(point.uuid)) {
      excluded++;
    } else {
      importable.add(point);
    }
  }
  return HealthWorkoutPartition(
    importable: importable,
    companionSkipped: companion,
    excludedSkipped: excluded,
  );
}

/// Extracts the usable GPS routes from WORKOUT_ROUTE [points].
///
/// Each route keeps its own time window so it can be correlated to a workout
/// either by `workoutUuid` (Android / Health Connect) or, when that is absent,
/// by time overlap (iOS: `HKWorkoutRoute` does not expose the owning workout's
/// UUID). Routes the platform withheld pending consent are counted in
/// `consentDenied` instead of failing, so those workouts simply import without
/// route points.
({List<HealthRouteData> routes, int consentDenied}) parseHealthRoutes(
  List<HealthDataPoint> points,
) {
  final routes = <HealthRouteData>[];
  var consentDenied = 0;
  for (final pt in points) {
    final value = pt.value;
    if (value is! WorkoutRouteHealthValue) continue;
    final metadata = pt.metadata;
    if (metadata?['route_requires_consent'] == true) {
      consentDenied++;
      continue;
    }
    if (value.locations.isEmpty) continue;
    routes.add(
      HealthRouteData(
        start: pt.dateFrom.toUtc(),
        end: pt.dateTo.toUtc(),
        workoutUuid: metadata?['workout_uuid'] as String? ?? value.workoutUuid,
        locations: value.locations,
      ),
    );
  }
  return (routes: routes, consentDenied: consentDenied);
}

/// Gives each route to the workout in [workoutPoints] that owns it (see
/// [healthRouteOwnerIndex]), keyed by workout uuid.
Map<String, List<WorkoutRouteLocation>> assignHealthRoutes({
  required List<HealthRouteData> routes,
  required List<HealthDataPoint> workoutPoints,
}) {
  final windows = [
    for (final point in workoutPoints)
      (
        uuid: point.uuid,
        start: point.dateFrom.toUtc(),
        end: point.dateTo.toUtc(),
      ),
  ];
  final byWorkout = <String, List<WorkoutRouteLocation>>{};
  for (final route in routes) {
    final owner = healthRouteOwnerIndex(
      routeWorkoutUuid: route.workoutUuid,
      routeStart: route.start,
      routeEnd: route.end,
      workouts: windows,
    );
    if (owner == null) continue;
    (byWorkout[windows[owner].uuid] ??= []).addAll(route.locations);
  }
  return byWorkout;
}

/// The heart rate read window of each workout: its own span padded by
/// [healthHeartRateWindowPadding], rather than the whole page.
List<({DateTime start, DateTime end})> healthHeartRateWindows(
  List<HealthDataPoint> workoutPoints,
) {
  return [
    for (final point in workoutPoints)
      (
        start: point.dateFrom.toUtc().subtract(healthHeartRateWindowPadding),
        end: point.dateTo.toUtc().add(healthHeartRateWindowPadding),
      ),
  ];
}

/// Converts HEART_RATE plugin [points] into interval samples, ignoring points
/// without a numeric value.
///
/// On iOS a condensed series arrives here as one sample spanning the whole
/// series with a single summary value; it still covers its full interval.
List<HealthHeartRateSample> heartRateSamplesFromPoints(
  List<HealthDataPoint> points,
) {
  final samples = <HealthHeartRateSample>[];
  for (final pt in points) {
    final value = pt.value;
    if (value is! NumericHealthValue) continue;
    samples.add(
      HealthHeartRateSample.interval(
        start: pt.dateFrom,
        end: pt.dateTo,
        bpm: value.numericValue.round(),
      ),
    );
  }
  return samples;
}

/// Converts native series [readings] into interval samples.
List<HealthHeartRateSample> heartRateSamplesFromReadings(
  List<HeartRateReading> readings,
) {
  return [
    for (final reading in readings)
      HealthHeartRateSample.interval(
        start: reading.start,
        end: reading.end,
        bpm: reading.bpm.round(),
      ),
  ];
}

/// Maps a WORKOUT [HealthDataPoint] into a [HealthWorkout].
///
/// Returns `null` when the data point is not a workout type (should not
/// happen in practice but guards against API changes).
HealthWorkout? mapHealthWorkout({
  required HealthDataPoint point,
  required List<WorkoutRouteLocation> locations,
  required HealthHeartRateIndex heartRate,
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
      HealthDataUnit.MILE => rawDist * UnitConversions.metersPerMile,
      _ => rawDist.toDouble(), // default: assume metres
    };
  }

  // Merge GPS route + HR. A workout can own several route samples, which
  // arrive in no particular order, so the points are sorted by time.
  final route =
      locations
          .map((loc) => _mergeHeartRate(loc: loc, heartRate: heartRate))
          .toList()
        ..sort((a, b) => a.time.compareTo(b.time));

  return HealthWorkout(
    sourceId: point.uuid,
    type: type,
    startedAt: point.dateFrom.toUtc(),
    endedAt: point.dateTo.toUtc(),
    distanceMeters: distanceMeters,
    route: route,
  );
}

/// Attaches the heart rate reading that covers a route point, or the nearest
/// one within the match tolerance of it.
HealthRoutePoint _mergeHeartRate({
  required WorkoutRouteLocation loc,
  required HealthHeartRateIndex heartRate,
}) {
  return HealthRoutePoint(
    latitude: loc.latitude,
    longitude: loc.longitude,
    time: loc.timestamp.toUtc(),
    elevation: loc.altitude,
    heartRate: heartRate.bpmAt(loc.timestamp.millisecondsSinceEpoch),
  );
}

/// Sanitized counts (never coordinates or PII) for the `healthReadWorkouts`
/// diagnostics breadcrumb, showing where route correlation may be failing.
Map<String, Object?> healthReadDiagnosticsDetails({
  required List<HealthWorkout> workouts,
  required List<HealthRouteData> routes,
  required int routeConsentDenied,
  required bool historyClamped,
  required int companionSkipped,
  required int excludedSkipped,
  required int heartRateReadings,
  required String heartRateSource,
}) {
  return {
    'workouts': workouts.length,
    'route_samples': routes.length,
    'route_locations': routes.fold<int>(
      0,
      (sum, r) => sum + r.locations.length,
    ),
    'routes_with_uuid': routes.where((r) => r.workoutUuid != null).length,
    'workouts_with_route': workouts.where((w) => w.hasRoute).length,
    'route_read_failed': routeConsentDenied > 0,
    'history_clamped': historyClamped,
    'companion_watch_skipped': companionSkipped,
    'already_handled_skipped': excludedSkipped,
    'heart_rate_readings': heartRateReadings,
    'heart_rate_source': heartRateSource,
    'route_points_with_heart_rate': workouts.fold<int>(
      0,
      (sum, w) => sum + w.route.where((p) => p.heartRate != null).length,
    ),
  };
}
