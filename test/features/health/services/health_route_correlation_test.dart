import 'package:endurain/features/health/services/health_route_correlation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('healthRouteOwnerIndex', () {
    final workouts = [
      (
        uuid: 'w1',
        start: DateTime.utc(2025, 6, 1, 9, 0),
        end: DateTime.utc(2025, 6, 1, 10, 0),
      ),
      // Starts 30 s after w1 ends: inside the time tolerance of w1.
      (
        uuid: 'w2',
        start: DateTime.utc(2025, 6, 1, 10, 0, 30),
        end: DateTime.utc(2025, 6, 1, 11, 0),
      ),
    ];

    int? owner({
      String? uuid,
      required DateTime routeStart,
      required DateTime routeEnd,
    }) => healthRouteOwnerIndex(
      routeWorkoutUuid: uuid,
      routeStart: routeStart,
      routeEnd: routeEnd,
      workouts: workouts,
    );

    test('matches by UUID when the route carries the workout UUID', () {
      expect(
        owner(
          uuid: 'w2',
          routeStart: DateTime.utc(2030), // time ignored when UUID present
          routeEnd: DateTime.utc(2030),
        ),
        1,
      );
    });

    test('rejects an unknown UUID even if the times overlap', () {
      expect(
        owner(
          uuid: 'other',
          routeStart: DateTime.utc(2025, 6, 1, 9, 0),
          routeEnd: DateTime.utc(2025, 6, 1, 10, 0),
        ),
        isNull,
      );
    });

    test('gives a route to the one workout it overlaps (iOS)', () {
      expect(
        owner(
          routeStart: DateTime.utc(2025, 6, 1, 9, 0),
          routeEnd: DateTime.utc(2025, 6, 1, 10, 0),
        ),
        0,
      );
      expect(
        owner(
          routeStart: DateTime.utc(2025, 6, 1, 10, 0, 30),
          routeEnd: DateTime.utc(2025, 6, 1, 11, 0),
        ),
        1,
      );
    });

    test('a route overlapping two workouts goes to the larger overlap', () {
      expect(
        owner(
          routeStart: DateTime.utc(2025, 6, 1, 9, 55),
          routeEnd: DateTime.utc(2025, 6, 1, 10, 50),
        ),
        1,
      );
    });

    test('does not match a route well outside every workout', () {
      expect(
        owner(
          routeStart: DateTime.utc(2025, 6, 1, 12, 0),
          routeEnd: DateTime.utc(2025, 6, 1, 13, 0),
        ),
        isNull,
      );
    });

    test('tolerates a small clock skew when nothing overlaps', () {
      // Route ends 30 s before w1 starts — within the 60 s tolerance.
      expect(
        owner(
          routeStart: DateTime.utc(2025, 6, 1, 8, 58, 30),
          routeEnd: DateTime.utc(2025, 6, 1, 8, 59, 30),
        ),
        0,
      );
    });
  });
}
