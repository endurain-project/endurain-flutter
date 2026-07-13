import 'package:endurain/features/activity/models/activity_type.dart';

/// Maps OS workout category identifiers to [ActivityType] values.
///
/// Used by the health import adapter to normalise platform-specific workout
/// types into the canonical Endurain type. Unknown types fall back to
/// [ActivityType.other], mirroring [ActivityType.fromApiValue]'s behaviour.
enum HealthWorkoutType {
  run('run'),
  ride('ride'),
  walk('walk'),
  hike('hike'),
  other('other');

  const HealthWorkoutType(this._apiValue);

  final String _apiValue;

  /// Returns the corresponding [ActivityType] for this workout type.
  ActivityType toActivityType() => ActivityType.fromApiValue(_apiValue);

  /// Maps a platform-level workout type string (e.g. from the `health`
  /// package's `HealthWorkoutActivityType.name`) to a [HealthWorkoutType].
  ///
  /// Unrecognised values return [HealthWorkoutType.other].
  static HealthWorkoutType fromPlatformValue(String? value) {
    if (value == null) return HealthWorkoutType.other;
    final lower = value.toLowerCase();
    if (lower.contains('run') || lower.contains('jogging')) {
      return HealthWorkoutType.run;
    }
    if (lower.contains('cycl') ||
        lower.contains('bik') ||
        lower.contains('ride')) {
      return HealthWorkoutType.ride;
    }
    if (lower.contains('walk')) return HealthWorkoutType.walk;
    if (lower.contains('hik')) return HealthWorkoutType.hike;
    return HealthWorkoutType.other;
  }
}
