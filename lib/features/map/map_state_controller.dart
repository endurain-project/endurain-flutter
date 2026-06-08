import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:endurain/core/constants/map_constants.dart';
import 'package:endurain/core/services/location_service.dart';
import 'package:endurain/features/map/map_settings_repository.dart';

class MapStateController extends ChangeNotifier {
  MapStateController({
    required LocationService locationService,
    required MapSettingsRepository mapSettingsRepository,
  }) : _locationService = locationService,
       _mapSettingsRepository = mapSettingsRepository;

  final LocationService _locationService;
  final MapSettingsRepository _mapSettingsRepository;

  StreamSubscription<Position>? _positionSubscription;
  bool _initialized = false;
  bool _isDisposed = false;

  LatLng currentLocation = const LatLng(
    MapConstants.defaultLatitude,
    MapConstants.defaultLongitude,
  );
  String tileServerUrl = MapConstants.defaultTileServerUrl;
  bool isLoadingLocation = false;
  bool hasLocationPermission = false;
  bool hasLocationError = false;
  bool isLocationLocked = true;
  double heading = 0.0;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;

    await Future.wait([_loadSettings(), _loadUserLocation()]);
  }

  Future<void> _loadSettings() async {
    tileServerUrl = await _mapSettingsRepository.getTileServerUrl();
    _notifyListeners();
  }

  Future<void> _loadUserLocation() async {
    isLoadingLocation = true;
    hasLocationError = false;
    _notifyListeners();

    final position = await _locationService.getCurrentPosition();

    if (_isDisposed) {
      return;
    }

    if (position != null) {
      currentLocation = LatLng(position.latitude, position.longitude);
      _updateHeading(position);
      hasLocationPermission = true;
      hasLocationError = false;
      isLoadingLocation = false;
      _notifyListeners();
      _startPositionUpdates();
      return;
    }

    hasLocationPermission = false;
    isLoadingLocation = false;
    _notifyListeners();
  }

  void _startPositionUpdates() {
    _positionSubscription?.cancel();
    _positionSubscription = _locationService.getPositionStream().listen(
      _handlePositionUpdate,
      onError: _handlePositionError,
    );
  }

  void _handlePositionUpdate(Position position) {
    currentLocation = LatLng(position.latitude, position.longitude);
    _updateHeading(position);
    hasLocationPermission = true;
    hasLocationError = false;
    _notifyListeners();
  }

  void _handlePositionError(Object error, StackTrace stackTrace) {
    hasLocationPermission = false;
    hasLocationError = true;
    isLoadingLocation = false;
    _notifyListeners();
  }

  void _updateHeading(Position position) {
    if (position.heading.isNaN || position.heading < 0) {
      return;
    }
    heading = position.heading;
  }

  void toggleLocationLock() {
    isLocationLocked = !isLocationLocked;
    _notifyListeners();
  }

  void unlockLocation() {
    if (!isLocationLocked) {
      return;
    }
    isLocationLocked = false;
    _notifyListeners();
  }

  /// Pauses or resumes the map position stream based on whether an activity
  /// recording is currently active.
  ///
  /// Call with [isRecording] = true when recording starts so the map no longer
  /// maintains its own GPS subscription (the native recorder owns the durable
  /// stream). Call with [isRecording] = false when recording stops to resume
  /// map position updates.
  void setRecordingActive(bool isRecording) {
    if (isRecording) {
      _positionSubscription?.cancel();
      _positionSubscription = null;
      return;
    }
    if (_positionSubscription == null && hasLocationPermission) {
      _startPositionUpdates();
    }
  }

  void _notifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _positionSubscription?.cancel();
    super.dispose();
  }
}
