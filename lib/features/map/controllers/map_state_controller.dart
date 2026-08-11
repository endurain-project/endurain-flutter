import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:endurain/core/constants/map_constants.dart';
import 'package:endurain/core/services/location_service.dart';
import 'package:endurain/features/map/repositories/map_settings_repository.dart';
import 'package:endurain/shared/state/safe_notifier.dart';

class MapStateController extends SafeNotifier {
  MapStateController({
    required this._locationService,
    required MapSettingsRepository mapSettingsRepository,
  }) : _mapSettingsRepository = mapSettingsRepository;

  final LocationService _locationService;
  final MapSettingsRepository _mapSettingsRepository;

  StreamSubscription<Position>? _positionSubscription;
  bool _initialized = false;

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
    notify();
  }

  Future<void> _loadUserLocation() async {
    _isLoadingLocation = true;
    _hasLocationError = false;
    notify();

    final position = await _locationService.getCurrentPosition();

    if (isDisposed) {
      return;
    }

    if (position != null) {
      _currentLocation = LatLng(position.latitude, position.longitude);
      _updateHeading(position);
      _hasLocationPermission = true;
      _hasLocationError = false;
      _isLoadingLocation = false;
      notify();
      _startPositionUpdates();
      return;
    }

    _hasLocationPermission = false;
    _isLoadingLocation = false;
    notify();
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
    notify();
  }

  void _handlePositionError(Object error, StackTrace stackTrace) {
    _hasLocationPermission = false;
    _hasLocationError = true;
    _isLoadingLocation = false;
    notify();
  }

  void _updateHeading(Position position) {
    if (position.heading.isNaN || position.heading < 0) {
      return;
    }
    _heading = position.heading;
  }

  void toggleLocationLock() {
    _isLocationLocked = !_isLocationLocked;
    notify();
  }

  void unlockLocation() {
    if (!_isLocationLocked) {
      return;
    }
    _isLocationLocked = false;
    notify();
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

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }
}
