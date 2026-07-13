import 'package:flutter_test/flutter_test.dart';
import 'package:endurain/features/health/models/health_route_point.dart';
import 'package:endurain/features/health/models/health_workout.dart';
import 'package:endurain/features/health/models/health_workout_type.dart';

void main() {
  group('HealthWorkout', () {
    final start = DateTime.utc(2025, 6, 1, 9, 0);
    final end = DateTime.utc(2025, 6, 1, 10, 0);

    test('constructs with route — hasRoute is true', () {
      final workout = HealthWorkout(
        sourceId: 'uuid-1',
        type: HealthWorkoutType.run,
        startedAt: start,
        endedAt: end,
        route: [
          HealthRoutePoint(
            latitude: 38.0,
            longitude: -9.0,
            time: DateTime.utc(2025, 6, 1, 9, 0),
          ),
        ],
      );
      expect(workout.hasRoute, isTrue);
      expect(workout.sourceId, 'uuid-1');
      expect(workout.type, HealthWorkoutType.run);
      expect(workout.distanceMeters, isNull);
      expect(workout.energyKilocalories, isNull);
    });

    test('constructs without route — hasRoute is false', () {
      final workout = HealthWorkout(
        sourceId: 'uuid-2',
        type: HealthWorkoutType.other,
        startedAt: start,
        endedAt: end,
        route: const [],
      );
      expect(workout.hasRoute, isFalse);
    });

    test('optional fields are stored', () {
      final workout = HealthWorkout(
        sourceId: 'uuid-3',
        type: HealthWorkoutType.ride,
        startedAt: start,
        endedAt: end,
        route: const [],
        distanceMeters: 15000,
        energyKilocalories: 450,
      );
      expect(workout.distanceMeters, 15000);
      expect(workout.energyKilocalories, 450);
    });
  });
}
