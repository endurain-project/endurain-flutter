/// How far a route may lie outside a workout's window and still be given to it
/// when it overlaps no workout, absorbing clock/rounding differences between
/// the route and workout samples.
const int _routeMatchToleranceMs = 60000;

/// Returns the index in [workouts] of the workout that owns a GPS route, or
/// `null` when none does.
///
/// When the route carries its owning workout's UUID (Android / Health Connect)
/// the match is exact. On iOS `HKWorkoutRoute` does not expose that UUID, so
/// the route goes to the one workout it overlaps the most. A route that
/// overlaps none goes to the nearest workout within [_routeMatchToleranceMs],
/// so back-to-back workouts never share each other's tracks. A tie goes to the
/// workout whose start is closest to the route's.
int? healthRouteOwnerIndex({
  required String? routeWorkoutUuid,
  required DateTime routeStart,
  required DateTime routeEnd,
  required List<({String uuid, DateTime start, DateTime end})> workouts,
}) {
  if (routeWorkoutUuid != null) {
    final index = workouts.indexWhere((w) => w.uuid == routeWorkoutUuid);
    return index < 0 ? null : index;
  }
  final routeStartMs = routeStart.millisecondsSinceEpoch;
  final routeEndMs = routeEnd.millisecondsSinceEpoch;
  int? owner;
  // Overlap in ms; negative values are the gap between route and workout.
  var bestOverlapMs = -_routeMatchToleranceMs - 1;
  var bestStartDistanceMs = 0;
  for (var i = 0; i < workouts.length; i++) {
    final workoutStartMs = workouts[i].start.millisecondsSinceEpoch;
    final workoutEndMs = workouts[i].end.millisecondsSinceEpoch;
    final overlapMs =
        (routeEndMs < workoutEndMs ? routeEndMs : workoutEndMs) -
        (routeStartMs > workoutStartMs ? routeStartMs : workoutStartMs);
    final startDistanceMs = (routeStartMs - workoutStartMs).abs();
    if (overlapMs > bestOverlapMs ||
        (owner != null &&
            overlapMs == bestOverlapMs &&
            startDistanceMs < bestStartDistanceMs)) {
      owner = i;
      bestOverlapMs = overlapMs;
      bestStartDistanceMs = startDistanceMs;
    }
  }
  return owner;
}
