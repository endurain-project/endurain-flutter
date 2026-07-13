import 'package:flutter_test/flutter_test.dart';
import 'package:endurain/features/health/models/health_authorization_status.dart';
import 'package:endurain/features/health/models/health_data_access_details.dart';
import 'package:endurain/features/health/models/health_sdk_status.dart';
import 'package:endurain/features/health/services/health_platform_adapter.dart';

void main() {
  group('UnsupportedHealthPlatformAdapter', () {
    const adapter = UnsupportedHealthPlatformAdapter();

    test('getSdkStatus returns unsupported', () async {
      expect(await adapter.getSdkStatus(), HealthSdkStatus.unsupported);
    });

    test('requestAuthorization returns denied', () async {
      expect(
        await adapter.requestAuthorization(),
        HealthAuthorizationStatus.denied,
      );
    });

    test('currentAuthorizationStatus returns denied', () async {
      expect(
        await adapter.currentAuthorizationStatus(),
        HealthAuthorizationStatus.denied,
      );
    });

    test('getAccessDetails returns system-managed access details', () async {
      expect(
        await adapter.getAccessDetails(),
        const HealthDataAccessDetails.systemManaged(),
      );
    });

    test('reports no route consent denials', () {
      expect(adapter.routeConsentDeniedCount, 0);
    });

    test('install and revocation complete without platform calls', () async {
      await adapter.installHealthConnect();
      await adapter.revokePermissions();
    });

    test('readWorkouts returns empty list', () async {
      final workouts = await adapter.readWorkouts(
        start: DateTime.utc(2025, 6, 1),
        end: DateTime.utc(2025, 6, 2),
      );
      expect(workouts, isEmpty);
    });
  });
}
