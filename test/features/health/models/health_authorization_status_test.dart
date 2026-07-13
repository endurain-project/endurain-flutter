import 'package:flutter_test/flutter_test.dart';
import 'package:endurain/features/health/models/health_authorization_status.dart';

void main() {
  group('HealthAuthorizationStatus', () {
    test('all values exist', () {
      expect(
        HealthAuthorizationStatus.values,
        containsAll([
          HealthAuthorizationStatus.granted,
          HealthAuthorizationStatus.denied,
          HealthAuthorizationStatus.notDetermined,
        ]),
      );
    });

    test('has exactly 3 values', () {
      expect(HealthAuthorizationStatus.values.length, 3);
    });
  });
}
