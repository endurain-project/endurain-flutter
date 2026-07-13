import 'package:endurain/features/health/models/health_workout.dart';

class HealthWorkoutPage {
  const HealthWorkoutPage({required this.items, required this.hasMore});

  final List<HealthWorkout> items;
  final bool hasMore;
}
