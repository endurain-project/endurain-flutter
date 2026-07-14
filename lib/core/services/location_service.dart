import 'package:geolocator/geolocator.dart';
import 'package:endurain/core/services/platform/location_platform_adapter.dart';
import 'package:endurain/core/services/location_settings_builder.dart';

class LocationService {
  LocationService({LocationPlatformAdapter? platformAdapter})
    : _platformAdapter =
          platformAdapter ?? const GeolocatorLocationPlatformAdapter();

  final LocationPlatformAdapter _platformAdapter;

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return _platformAdapter.isLocationServiceEnabled();
  }

  /// Check location permission status
  Future<LocationPermission> checkPermission() async {
    return _platformAdapter.checkPermission();
  }

  /// Request location permission
  Future<LocationPermission> requestPermission() async {
    return _platformAdapter.requestPermission();
  }

  /// Get current position
  /// Returns null if permission is denied or location service is disabled
  Future<Position?> getCurrentPosition() async {
    // Check if location services are enabled
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    // Check permission
    LocationPermission permission = await checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    // Get position
    try {
      return await _platformAdapter.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: LocationDistanceFilters.currentPositionMeters,
        ),
      );
    } catch (e) {
      return null;
    }
  }

  /// Get position stream for continuous tracking
  ///
  /// Pass [background] to keep receiving updates while the app is backgrounded
  /// (e.g. during an activity recording). When omitted, foreground-only
  /// settings are used.
  Stream<Position> getPositionStream({
    BackgroundLocationConfig? background,
    int distanceFilter = LocationDistanceFilters.mapMeters,
  }) {
    return _platformAdapter.getPositionStream(
      locationSettings: buildLocationSettings(
        background: background,
        distanceFilter: distanceFilter,
      ),
    );
  }

  /// Opens the system page for device-wide location services.
  Future<bool> openLocationSettings() async {
    return _platformAdapter.openLocationSettings();
  }

  /// Open app settings (useful when permission is permanently denied)
  Future<bool> openAppSettings() async {
    return _platformAdapter.openAppSettings();
  }
}
