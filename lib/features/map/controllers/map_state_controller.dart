import 'dart:async';

import 'package:endurain/core/constants/map_constants.dart';
import 'package:endurain/core/location/location_service.dart';
import 'package:endurain/core/services/map_settings_repository.dart';
import 'package:endurain/shared/state/safe_notifier.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class MapStateController extends SafeNotifier {
  MapStateController({
    required this._locationService,
    required MapSettingsRepository mapSettingsRepository,
  }) : _mapSettingsRepository = mapSettingsRepository;

  final LocationService _locationService;
  final MapSettingsRepository _mapSettingsRepository;

  StreamSubscription<Position>? _positionSubscription;
  bool _initialized = false;
  bool _recordingActive = false;
  bool _appInForeground = true;

  /// Bumped by each [_loadSettings], so a slower earlier read cannot
  /// overwrite the result of a later one.
  int _settingsGeneration = 0;

  LatLng _currentLocation = const LatLng(
    MapConstants.defaultLatitude,
    MapConstants.defaultLongitude,
  );
  String _tileServerUrl = MapConstants.defaultTileServerUrl;
  String? _tileAttribution;
  bool _isLoadingLocation = false;
  bool _hasLocationPermission = false;
  bool _isLocationLocked = true;
  double _heading = 0.0;

  LatLng get currentLocation => _currentLocation;
  String get tileServerUrl => _tileServerUrl;

  /// Attribution of the custom tile source, or null for OpenStreetMap.
  String? get tileAttribution => _tileAttribution;
  bool get isLoadingLocation => _isLoadingLocation;
  bool get hasLocationPermission => _hasLocationPermission;
  bool get isLocationLocked => _isLocationLocked;
  double get heading => _heading;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;
    // The map outlives the settings screens and sign-in/out, so re-read the
    // tile URL whenever it is saved or the connected server changes.
    _mapSettingsRepository.changes?.addListener(_handleSettingsChanged);

    await Future.wait([_loadSettings(), _loadUserLocation()]);
  }

  void _handleSettingsChanged() {
    if (isDisposed) {
      return;
    }
    unawaited(_loadSettings());
  }

  Future<void> _loadSettings() async {
    final generation = ++_settingsGeneration;
    final String tileServerUrl;
    final String? tileAttribution;
    try {
      tileServerUrl = await _mapSettingsRepository.getTileServerUrl();
      tileAttribution = await _mapSettingsRepository.getTileAttribution();
    } catch (_) {
      // Storage unavailable: keep drawing with the URL already in use.
      return;
    }
    if (isDisposed || generation != _settingsGeneration) {
      return;
    }
    _tileServerUrl = tileServerUrl;
    _tileAttribution = tileAttribution;
    notify();
  }

  Future<void> _loadUserLocation() async {
    _isLoadingLocation = true;
    notify();

    Position? position;
    try {
      position = await _locationService.getCurrentPosition();
    } catch (_) {
      // Treated like "no location": the map keeps its default centre.
      position = null;
    } finally {
      _isLoadingLocation = false;
    }

    if (isDisposed) {
      return;
    }

    if (position != null) {
      _currentLocation = LatLng(position.latitude, position.longitude);
      _updateHeading(position);
      _hasLocationPermission = true;
      notify();
      _syncPositionStream();
      return;
    }

    _hasLocationPermission = false;
    notify();
  }

  /// Keeps the position subscription in step with the state that decides
  /// whether it should exist: permission granted, no recording (the native
  /// recorder owns the durable stream then) and the app in the foreground
  /// (nothing is drawn in the background, so the GPS would only burn battery).
  void _syncPositionStream() {
    if (isDisposed) {
      return;
    }
    final shouldRun =
        _hasLocationPermission && !_recordingActive && _appInForeground;
    if (!shouldRun) {
      _cancelPositionStream();
      return;
    }
    if (_positionSubscription != null) {
      return;
    }
    _positionSubscription = _locationService.getPositionStream().listen(
      _handlePositionUpdate,
      onError: _handlePositionError,
    );
  }

  void _cancelPositionStream() {
    final cancelled = _positionSubscription?.cancel();
    _positionSubscription = null;
    if (cancelled != null) {
      // A cancel failure has nothing to recover; it only must not surface as
      // an unhandled async error.
      unawaited(cancelled.catchError((Object _) {}));
    }
  }

  void _handlePositionUpdate(Position position) {
    _currentLocation = LatLng(position.latitude, position.longitude);
    _updateHeading(position);
    _hasLocationPermission = true;
    notify();
  }

  void _handlePositionError(Object error, StackTrace stackTrace) {
    _hasLocationPermission = false;
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
    _recordingActive = isRecording;
    _syncPositionStream();
  }

  /// Pauses the position stream while the app is backgrounded and resumes it
  /// when it returns to the foreground (unless a recording is active).
  void setAppInForeground(bool inForeground) {
    _appInForeground = inForeground;
    _syncPositionStream();
  }

  @override
  void dispose() {
    _mapSettingsRepository.changes?.removeListener(_handleSettingsChanged);
    _cancelPositionStream();
    super.dispose();
  }
}
