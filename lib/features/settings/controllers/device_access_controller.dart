import 'package:endurain/core/location/location_service.dart';
import 'package:endurain/shared/state/safe_notifier.dart';
import 'package:geolocator/geolocator.dart';

class DeviceAccessController extends SafeNotifier {
  DeviceAccessController({required LocationService locationService})
    : _locationService = locationService;

  final LocationService _locationService;

  bool _isLoading = true;
  bool _isLocationServiceEnabled = false;
  LocationPermission _locationPermission = LocationPermission.unableToDetermine;

  bool get isLoading => _isLoading;
  bool get isLocationServiceEnabled => _isLocationServiceEnabled;
  LocationPermission get locationPermission => _locationPermission;

  Future<void> load() async {
    _isLoading = true;
    notify();
    try {
      await _refresh();
    } finally {
      _isLoading = false;
      notify();
    }
  }

  Future<void> _refresh() async {
    try {
      _isLocationServiceEnabled = await _locationService
          .isLocationServiceEnabled();
      _locationPermission = await _locationService.checkPermission();
    } catch (_) {
      // Platform channel failure: report the state as undetermined.
      _isLocationServiceEnabled = false;
      _locationPermission = LocationPermission.unableToDetermine;
    }
  }

  Future<void> requestLocationAccess() async {
    try {
      _locationPermission = await _locationService.requestPermission();
    } catch (_) {
      // Keep the previous permission state when the request itself fails.
    }
    notify();
  }

  Future<void> openLocationSettings() async {
    await _locationService.openLocationSettings();
  }

  Future<void> openAppSettings() async {
    await _locationService.openAppSettings();
  }
}
