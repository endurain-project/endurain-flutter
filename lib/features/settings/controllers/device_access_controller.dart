import 'package:endurain/core/services/location_service.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class DeviceAccessController extends ChangeNotifier {
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
    notifyListeners();
    _isLocationServiceEnabled = await _locationService
        .isLocationServiceEnabled();
    _locationPermission = await _locationService.checkPermission();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> requestLocationAccess() async {
    _locationPermission = await _locationService.requestPermission();
    notifyListeners();
  }

  Future<void> openLocationSettings() async {
    await _locationService.openLocationSettings();
  }

  Future<void> openAppSettings() async {
    await _locationService.openAppSettings();
  }
}
