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

  LatLng _currentLocation = const LatLng(
    MapConstants.defaultLatitude,
    MapConstants.defaultLongitude,
  );
  String _tileServerUrl = MapConstants.defaultTileServerUrl;
  bool _isLoadingLocation = false;
  bool _hasLocationPermission = false;
  bool _hasLocationError = false;
  bool _isLocationLocked = true;
  double _heading = 0.0;

  LatLng get currentLocation => _currentLocation;
  String get tileServerUrl => _tileServerUrl;
  bool get isLoadingLocation => _isLoadingLocation;
  bool get hasLocationPermission => _hasLocationPermission;
  bool get hasLocationError => _hasLocationError;
  bool get isLocationLocked => _isLocationLocked;
  double get heading => _heading;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;

    await Future.wait([_loadSettings(), _loadUserLocation()]);
  }

  Future<void> _loadSettings() async {
    _tileServerUrl = await _mapSettingsRepository.getTileServerUrl();
    _notifyListeners();
  }

  Future<void> _loadUserLocation() async {
    _isLoadingLocation = true;
    _hasLocationError = false;
    _notifyListeners();

    final position = await _locationService.getCurrentPosition();

    if (_isDisposed) {
      return;
    }

    if (position != null) {
      _currentLocation = LatLng(position.latitude, position.longitude);
      _updateHeading(position);
      _hasLocationPermission = true;
      _hasLocationError = false;
      _isLoadingLocation = false;
      _notifyListeners();
      _startPositionUpdates();
      return;
    }

    _hasLocationPermission = false;
    _isLoadingLocation = false;
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
    _currentLocation = LatLng(position.latitude, position.longitude);
    _updateHeading(position);
    _hasLocationPermission = true;
    _hasLocationError = false;
    _notifyListeners();
  }

  void _handlePositionError(Object error, StackTrace stackTrace) {
    _hasLocationPermission = false;
    _hasLocationError = true;
    _isLoadingLocation = false;
    _notifyListeners();
  }

  void _updateHeading(Position position) {
    if (position.heading.isNaN || position.heading < 0) {
      return;
    }
    _heading = position.heading;
  }

  void toggleLocationLock() {
    _isLocationLocked = !_isLocationLocked;
    _notifyListeners();
  }

  void unlockLocation() {
    if (!_isLocationLocked) {
      return;
    }
    _isLocationLocked = false;
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
    if (_positionSubscription == null && _hasLocationPermission) {
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
