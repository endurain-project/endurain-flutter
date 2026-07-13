import 'package:endurain/features/health/models/health_route_point.dart';
import 'package:endurain/features/health/models/health_workout_type.dart';

/// An imported workout from the health platform.
///
/// Immutable snapshot of all data read from HealthKit / Health Connect for a
/// single workout session. [route] may be empty when the workout has no GPS
/// data or when consent for third-party exercise routes was not granted.
class HealthWorkout {
  const HealthWorkout({
    required this.sourceId,
    required this.type,
    required this.startedAt,
    required this.endedAt,
    required this.route,
    this.distanceMeters,
    this.energyKilocalories,
  });

  /// Stable OS-assigned UUID that uniquely identifies this workout.
  ///
  /// Used for deduplication: once a workout is imported its [sourceId] is
  /// persisted so it is never re-imported automatically.
  final String sourceId;

  /// Workout category mapped to an Endurain type.
  final HealthWorkoutType type;

  /// UTC start timestamp of the workout.
  final DateTime startedAt;

  /// UTC end timestamp of the workout.
  final DateTime endedAt;

  /// Total distance covered, in metres. May be null if not recorded.
  final double? distanceMeters;

  /// Total energy burned, in kilocalories. May be null if not recorded.
  ///
  /// Captured from the platform for completeness but **not** part of the v1
  /// upload: the Endurain server ingests GPX (track points only) and recomputes
  /// metrics server-side, and GPX 1.1 has no standard calorie field. This is
  /// retained for a future structured (non-GPX) ingest path; intentionally
  /// unused today rather than dropped, so the mapping is ready when that lands.
  final double? energyKilocalories;

  /// GPS route points for this workout, ordered by time.
  ///
  /// Empty when:
  /// - the workout has no GPS data (e.g. indoor treadmill run), or
  /// - the user has not granted "Always allow" exercise-route consent to the
  ///   source app in Health Connect (Android — `ConsentRequired` result).
  final List<HealthRoutePoint> route;

  /// `true` when this workout has at least one GPS route point and can be
  /// converted to GPX for upload.
  bool get hasRoute => route.isNotEmpty;
}
