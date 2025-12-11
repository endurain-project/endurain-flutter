import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:endurain/core/services/location_service.dart';
import 'package:endurain/core/services/secure_storage_service.dart';
import 'package:endurain/core/utils/platform_utils.dart';
import 'package:endurain/core/constants/map_constants.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  final SecureStorageService _storage = SecureStorageService();
  LatLng _currentLocation = const LatLng(
    MapConstants.defaultLatitude,
    MapConstants.defaultLongitude,
  );
  String _tileServerUrl = MapConstants.defaultTileServerUrl;
  bool _isLoadingLocation = false;
  bool _hasLocationPermission = false;
  bool _isLocationLocked = true; // Track if location is locked to user
  double _heading = 0.0; // Device heading in degrees
  StreamSubscription<CompassEvent>? _compassSubscription;
  StreamSubscription<Position>? _positionSubscription;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadUserLocation();
    _startCompassUpdates();
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    _positionSubscription?.cancel();
    super.dispose();
  }

  /// Start listening to compass heading updates
  void _startCompassUpdates() {
    // Compass is only supported on iOS and Android (not macOS)
    if (PlatformUtils.isMobile) {
      _compassSubscription = FlutterCompass.events?.listen((
        CompassEvent event,
      ) {
        if (mounted && event.heading != null) {
          setState(() {
            _heading = event.heading!;
          });
        }
      });
    }
  }

  Future<void> _loadSettings() async {
    final tileUrl = await _storage.getTileServerUrl();
    if (mounted && tileUrl != null && tileUrl.isNotEmpty) {
      setState(() {
        _tileServerUrl = tileUrl;
      });
    }
  }

  Future<void> _loadUserLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    final position = await _locationService.getCurrentPosition();

    if (mounted) {
      if (position != null) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _hasLocationPermission = true;
          _isLoadingLocation = false;
        });
        // Wait for next frame to ensure map is ready
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _mapController.move(_currentLocation, MapConstants.initialLoadZoom);
        });
        // Start continuous position tracking
        _startPositionUpdates();
      } else {
        setState(() {
          _hasLocationPermission = false;
          _isLoadingLocation = false;
        });
      }
    }
  }

  /// Start listening to continuous position updates
  void _startPositionUpdates() {
    _positionSubscription = _locationService.getPositionStream().listen((
      Position position,
    ) {
      if (mounted) {
        final newLocation = LatLng(position.latitude, position.longitude);
        setState(() {
          _currentLocation = newLocation;
        });

        // If location is locked, move map to follow user
        if (_isLocationLocked) {
          _mapController.move(newLocation, _mapController.camera.zoom);
        }
      }
    });
  }

  /// Toggle location lock
  void _toggleLocationLock() {
    setState(() {
      _isLocationLocked = !_isLocationLocked;
    });

    // If locking, center on current position
    if (_isLocationLocked && _hasLocationPermission) {
      _mapController.move(_currentLocation, _mapController.camera.zoom);
    }
  }

  /// Handle map movement by user - unlock location
  void _onMapMoved() {
    if (_isLocationLocked) {
      setState(() {
        _isLocationLocked = false;
      });
    }
  }

  /// Build map options with common configuration
  MapOptions _buildMapOptions() {
    return MapOptions(
      initialCenter: _currentLocation,
      initialZoom: MapConstants.defaultZoom,
      minZoom: MapConstants.minZoom,
      maxZoom: MapConstants.maxZoom,
      onPositionChanged: (position, hasGesture) {
        // Only unlock if user manually moved the map
        if (hasGesture) {
          _onMapMoved();
        }
      },
    );
  }

  /// Build map layers (tile + marker)
  List<Widget> _buildMapLayers() {
    return [
      TileLayer(
        urlTemplate: _tileServerUrl,
        userAgentPackageName: MapConstants.userAgent,
      ),
      if (_hasLocationPermission)
        MarkerLayer(
          markers: [
            Marker(
              point: _currentLocation,
              width: LocationMarkerConstants.markerSize,
              height: LocationMarkerConstants.markerSize,
              alignment: Alignment.center,
              child: _LocationMarker(heading: _heading),
            ),
          ],
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Cupertino style for iOS/macOS
    if (PlatformUtils.isApplePlatform) {
      return CupertinoPageScaffold(
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: _buildMapOptions(),
              children: _buildMapLayers(),
            ),
            if (_isLoadingLocation)
              const Center(child: CupertinoActivityIndicator()),
            // Position button with SafeArea to avoid tab bar
            SafeArea(
              child: Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(
                    LocationMarkerConstants.buttonOuterPadding,
                  ),
                  child: CupertinoButton.filled(
                    padding: const EdgeInsets.all(
                      LocationMarkerConstants.buttonInnerPadding,
                    ),
                    onPressed: _toggleLocationLock,
                    child: Icon(
                      _isLocationLocked
                          ? CupertinoIcons.location_solid
                          : CupertinoIcons.location,
                      color: CupertinoColors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Material style for Android
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: _buildMapOptions(),
            children: _buildMapLayers(),
          ),
          if (_isLoadingLocation)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleLocationLock,
        tooltip: 'My Location',
        child: Icon(
          _isLocationLocked ? Icons.my_location : Icons.location_searching,
        ),
      ),
    );
  }
}

/// Blue dot with white border and directional cone
class _LocationMarker extends StatelessWidget {
  const _LocationMarker({required this.heading});

  final double heading;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: heading * math.pi / 180, // Convert degrees to radians
      child: CustomPaint(
        size: const Size(
          LocationMarkerConstants.markerSize,
          LocationMarkerConstants.markerSize,
        ),
        painter: _LocationMarkerPainter(),
      ),
    );
  }
}

/// Custom painter for the location marker
class _LocationMarkerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 5;

    // Draw directional cone (pointing upward when heading is 0)
    final conePaint = Paint()
      ..color = Colors.blue.withValues(
        alpha: LocationMarkerConstants.coneOpacity,
      )
      ..style = PaintingStyle.fill;

    final conePath = ui.Path()
      ..moveTo(center.dx, center.dy) // Center of circle
      ..lineTo(
        center.dx - radius * LocationMarkerConstants.coneWidthMultiplier,
        center.dy - radius * LocationMarkerConstants.coneHeightMultiplier,
      ) // Left point
      ..arcToPoint(
        Offset(
          center.dx + radius * LocationMarkerConstants.coneWidthMultiplier,
          center.dy - radius * LocationMarkerConstants.coneHeightMultiplier,
        ), // Right point
        radius: Radius.circular(
          radius * LocationMarkerConstants.coneArcRadiusMultiplier,
        ),
        clockwise: true,
      )
      ..close();

    canvas.drawPath(conePath, conePaint);

    // Draw white border circle
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      center,
      radius + LocationMarkerConstants.borderWidth,
      borderPaint,
    );

    // Draw blue dot
    final dotPaint = Paint()
      ..color = const Color(LocationMarkerConstants.markerBlue)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
