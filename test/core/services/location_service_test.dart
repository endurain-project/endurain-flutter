import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:endurain/core/services/location_platform_adapter.dart';
import 'package:endurain/core/services/location_service.dart';

void main() {
  group('LocationService', () {
    test('returns null when location services are disabled', () async {
      final adapter = _FakeLocationPlatformAdapter(serviceEnabled: false);
      final service = LocationService(platformAdapter: adapter);

      expect(await service.getCurrentPosition(), isNull);
      expect(adapter.requestPermissionCalled, isFalse);
    });

    test(
      'requests permission and returns current position when granted',
      () async {
        final position = _position(latitude: 41.1, longitude: -8.6);
        final adapter = _FakeLocationPlatformAdapter(
          permission: LocationPermission.denied,
          requestedPermission: LocationPermission.whileInUse,
          currentPosition: position,
        );
        final service = LocationService(platformAdapter: adapter);

        expect(await service.getCurrentPosition(), position);
        expect(adapter.requestPermissionCalled, isTrue);
      },
    );

    test('returns null when permission is denied forever', () async {
      final adapter = _FakeLocationPlatformAdapter(
        permission: LocationPermission.deniedForever,
      );
      final service = LocationService(platformAdapter: adapter);

      expect(await service.getCurrentPosition(), isNull);
    });
  });
}

Position _position({required double latitude, required double longitude}) {
  return Position(
    latitude: latitude,
    longitude: longitude,
    timestamp: DateTime.utc(2026),
    accuracy: 5,
    altitude: 10,
    altitudeAccuracy: 1,
    heading: 90,
    headingAccuracy: 1,
    speed: 3,
    speedAccuracy: 1,
  );
}

class _FakeLocationPlatformAdapter implements LocationPlatformAdapter {
  _FakeLocationPlatformAdapter({
    this.serviceEnabled = true,
    this.permission = LocationPermission.whileInUse,
    this.requestedPermission = LocationPermission.whileInUse,
    Position? currentPosition,
  }) : currentPosition =
           currentPosition ?? _position(latitude: 41.0, longitude: -8.0);

  final bool serviceEnabled;
  LocationPermission permission;
  final LocationPermission requestedPermission;
  final Position currentPosition;
  bool requestPermissionCalled = false;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<Position> getCurrentPosition({
    required LocationSettings locationSettings,
  }) async {
    return currentPosition;
  }

  @override
  Stream<Position> getPositionStream({
    required LocationSettings locationSettings,
  }) {
    return Stream.value(currentPosition);
  }

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<bool> openLocationSettings() async => true;

  @override
  Future<bool> openAppSettings() async => true;

  @override
  Future<LocationPermission> requestPermission() async {
    requestPermissionCalled = true;
    permission = requestedPermission;
    return permission;
  }
}
