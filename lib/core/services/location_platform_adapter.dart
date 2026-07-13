import 'package:geolocator/geolocator.dart';

abstract class LocationPlatformAdapter {
  Future<bool> isLocationServiceEnabled();

  Future<LocationPermission> checkPermission();

  Future<LocationPermission> requestPermission();

  Future<Position> getCurrentPosition({
    required LocationSettings locationSettings,
  });

  Stream<Position> getPositionStream({
    required LocationSettings locationSettings,
  });

  Future<bool> openLocationSettings();

  Future<bool> openAppSettings();
}

class GeolocatorLocationPlatformAdapter implements LocationPlatformAdapter {
  const GeolocatorLocationPlatformAdapter();

  @override
  Future<bool> isLocationServiceEnabled() {
    return Geolocator.isLocationServiceEnabled();
  }

  @override
  Future<LocationPermission> checkPermission() {
    return Geolocator.checkPermission();
  }

  @override
  Future<LocationPermission> requestPermission() {
    return Geolocator.requestPermission();
  }

  @override
  Future<Position> getCurrentPosition({
    required LocationSettings locationSettings,
  }) {
    return Geolocator.getCurrentPosition(locationSettings: locationSettings);
  }

  @override
  Stream<Position> getPositionStream({
    required LocationSettings locationSettings,
  }) {
    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  @override
  Future<bool> openLocationSettings() {
    return Geolocator.openLocationSettings();
  }

  @override
  Future<bool> openAppSettings() {
    return Geolocator.openAppSettings();
  }
}
