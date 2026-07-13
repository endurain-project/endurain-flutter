import 'package:flutter_test/flutter_test.dart';
import 'package:endurain/features/health/models/health_route_point.dart';

void main() {
  group('HealthRoutePoint', () {
    test('constructs with required fields', () {
      final time = DateTime.utc(2025, 6, 1, 10, 0, 0);
      final point = HealthRoutePoint(
        latitude: 38.7169,
        longitude: -9.1395,
        time: time,
      );
      expect(point.latitude, 38.7169);
      expect(point.longitude, -9.1395);
      expect(point.time, DateTime.utc(2025, 6, 1, 10, 0, 0));
      expect(point.elevation, isNull);
      expect(point.heartRate, isNull);
    });

    test('constructs with optional fields', () {
      final point = HealthRoutePoint(
        latitude: 38.7169,
        longitude: -9.1395,
        time: DateTime.utc(2025, 6, 1, 10, 0, 0),
        elevation: 42.5,
        heartRate: 145,
      );
      expect(point.elevation, 42.5);
      expect(point.heartRate, 145);
    });
  });
}
