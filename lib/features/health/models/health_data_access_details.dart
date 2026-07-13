/// Whether Endurain can read one requested category of health data.
enum HealthDataAccessStatus { allowed, needsAttention }

/// Platform-aware detail for Endurain's read-only health-data requests.
///
/// Health Connect reports the status of each requested type. HealthKit does
/// not disclose read grants, so [canInspectIndividualPermissions] is false on
/// Apple platforms and the individual statuses must not be shown as facts.
class HealthDataAccessDetails {
  const HealthDataAccessDetails({
    required this.canInspectIndividualPermissions,
    this.workouts = HealthDataAccessStatus.needsAttention,
    this.workoutRoutes = HealthDataAccessStatus.needsAttention,
    this.heartRate = HealthDataAccessStatus.needsAttention,
    this.distance = HealthDataAccessStatus.needsAttention,
    this.calories = HealthDataAccessStatus.needsAttention,
    this.steps = HealthDataAccessStatus.needsAttention,
  });

  const HealthDataAccessDetails.systemManaged()
    : canInspectIndividualPermissions = false,
      workouts = HealthDataAccessStatus.needsAttention,
      workoutRoutes = HealthDataAccessStatus.needsAttention,
      heartRate = HealthDataAccessStatus.needsAttention,
      distance = HealthDataAccessStatus.needsAttention,
      calories = HealthDataAccessStatus.needsAttention,
      steps = HealthDataAccessStatus.needsAttention;

  final bool canInspectIndividualPermissions;
  final HealthDataAccessStatus workouts;
  final HealthDataAccessStatus workoutRoutes;
  final HealthDataAccessStatus heartRate;
  final HealthDataAccessStatus distance;
  final HealthDataAccessStatus calories;
  final HealthDataAccessStatus steps;

  HealthDataAccessStatus get workoutSummary {
    return distance == HealthDataAccessStatus.allowed &&
            calories == HealthDataAccessStatus.allowed &&
            steps == HealthDataAccessStatus.allowed
        ? HealthDataAccessStatus.allowed
        : HealthDataAccessStatus.needsAttention;
  }

  bool get hasItemsNeedingAttention =>
      workouts == HealthDataAccessStatus.needsAttention ||
      workoutRoutes == HealthDataAccessStatus.needsAttention ||
      heartRate == HealthDataAccessStatus.needsAttention ||
      distance == HealthDataAccessStatus.needsAttention ||
      calories == HealthDataAccessStatus.needsAttention ||
      steps == HealthDataAccessStatus.needsAttention;
}
