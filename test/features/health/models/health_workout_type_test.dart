import 'package:flutter_test/flutter_test.dart';
import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/health/models/health_workout_type.dart';

void main() {
  group('HealthWorkoutType.toActivityType', () {
    test('run maps to ActivityType.run', () {
      expect(HealthWorkoutType.run.toActivityType(), ActivityType.run);
    });

    test('ride maps to ActivityType.ride', () {
      expect(HealthWorkoutType.ride.toActivityType(), ActivityType.ride);
    });

    test('walk maps to ActivityType.walk', () {
      expect(HealthWorkoutType.walk.toActivityType(), ActivityType.walk);
    });

    test('hike maps to ActivityType.hike', () {
      expect(HealthWorkoutType.hike.toActivityType(), ActivityType.hike);
    });

    test('other maps to ActivityType.other', () {
      expect(HealthWorkoutType.other.toActivityType(), ActivityType.other);
    });
  });

  group('HealthWorkoutType.fromPlatformValue', () {
    test('null returns other', () {
      expect(
        HealthWorkoutType.fromPlatformValue(null),
        HealthWorkoutType.other,
      );
    });

    test('running variants map to run', () {
      expect(
        HealthWorkoutType.fromPlatformValue('RUNNING'),
        HealthWorkoutType.run,
      );
      expect(
        HealthWorkoutType.fromPlatformValue('jogging'),
        HealthWorkoutType.run,
      );
    });

    test('cycling variants map to ride', () {
      expect(
        HealthWorkoutType.fromPlatformValue('CYCLING'),
        HealthWorkoutType.ride,
      );
      expect(
        HealthWorkoutType.fromPlatformValue('biking'),
        HealthWorkoutType.ride,
      );
    });

    test('walking maps to walk', () {
      expect(
        HealthWorkoutType.fromPlatformValue('WALKING'),
        HealthWorkoutType.walk,
      );
    });

    test('hiking maps to hike', () {
      expect(
        HealthWorkoutType.fromPlatformValue('HIKING'),
        HealthWorkoutType.hike,
      );
    });

    test('unknown returns other', () {
      expect(
        HealthWorkoutType.fromPlatformValue('SWIMMING'),
        HealthWorkoutType.other,
      );
    });
  });
}
