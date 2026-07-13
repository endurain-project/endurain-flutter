import 'package:endurain/features/activity/models/local_activity_record.dart';

class HealthImportedWorkout {
  const HealthImportedWorkout({
    required this.sourceId,
    required this.localActivityId,
    required this.importedAt,
    this.localActivity,
  });

  final String sourceId;
  final String localActivityId;
  final DateTime importedAt;
  final LocalActivityRecord? localActivity;

  bool get isAvailableLocally => localActivity != null;
}

class HealthImportedWorkoutPage {
  const HealthImportedWorkoutPage({required this.items, required this.hasMore});

  final List<HealthImportedWorkout> items;
  final bool hasMore;
}
