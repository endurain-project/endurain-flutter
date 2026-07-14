import 'package:endurain/features/health/models/health_data_access_details.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HealthDataAccessDetails', () {
    test('system-managed access does not claim individual grants', () {
      const details = HealthDataAccessDetails.systemManaged();

      expect(details.canInspectIndividualPermissions, isFalse);
      expect(details.workouts, HealthDataAccessStatus.needsAttention);
      expect(details.workoutRoutes, HealthDataAccessStatus.needsAttention);
      expect(details.heartRate, HealthDataAccessStatus.needsAttention);
      expect(details.hasItemsNeedingAttention, isTrue);
    });

    test('reports when every inspectable category is allowed', () {
      const details = HealthDataAccessDetails(
        canInspectIndividualPermissions: true,
        workouts: HealthDataAccessStatus.allowed,
        workoutRoutes: HealthDataAccessStatus.allowed,
        heartRate: HealthDataAccessStatus.allowed,
      );

      expect(details.hasItemsNeedingAttention, isFalse);
    });
  });
}
