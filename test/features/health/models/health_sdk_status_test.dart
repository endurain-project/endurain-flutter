import 'package:flutter_test/flutter_test.dart';
import 'package:endurain/features/health/models/health_sdk_status.dart';

void main() {
  group('HealthSdkStatus', () {
    test('all values exist', () {
      expect(
        HealthSdkStatus.values,
        containsAll([
          HealthSdkStatus.available,
          HealthSdkStatus.needsProviderInstall,
          HealthSdkStatus.unsupported,
        ]),
      );
    });

    test('has exactly 3 values', () {
      expect(HealthSdkStatus.values.length, 3);
    });
  });
}
