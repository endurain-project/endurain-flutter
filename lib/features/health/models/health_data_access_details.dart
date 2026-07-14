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
  });

  const HealthDataAccessDetails.systemManaged()
    : canInspectIndividualPermissions = false,
      workouts = HealthDataAccessStatus.needsAttention,
      workoutRoutes = HealthDataAccessStatus.needsAttention,
      heartRate = HealthDataAccessStatus.needsAttention;

  final bool canInspectIndividualPermissions;
  final HealthDataAccessStatus workouts;
  final HealthDataAccessStatus workoutRoutes;
  final HealthDataAccessStatus heartRate;

  bool get hasItemsNeedingAttention =>
      workouts == HealthDataAccessStatus.needsAttention ||
      workoutRoutes == HealthDataAccessStatus.needsAttention ||
      heartRate == HealthDataAccessStatus.needsAttention;
}
