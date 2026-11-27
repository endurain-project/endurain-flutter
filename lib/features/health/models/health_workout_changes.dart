/// What changed in the health platform's workouts since a change token was
/// taken (a Health Connect changes token, HealthKit query anchors).
class HealthWorkoutChanges {
  const HealthWorkoutChanges({
    required String this.nextToken,
    this.earliestStart,
  });

  /// The token can no longer be used (Health Connect expires one after 30
  /// days, or when too much changed), so the caller reads a time window
  /// instead and takes a new token.
  const HealthWorkoutChanges.expired() : nextToken = null, earliestStart = null;

  /// The token to read the next changes from, or `null` when [expired].
  final String? nextToken;

  /// The start of the earliest workout (or workout route) added or changed,
  /// or `null` when none was.
  final DateTime? earliestStart;

  bool get expired => nextToken == null;
}
