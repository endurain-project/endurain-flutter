import 'dart:async';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:endurain/core/constants/map_constants.dart';
import 'package:endurain/core/location/location_service.dart';
import 'package:endurain/core/location/location_settings_builder.dart';
import 'package:endurain/core/services/map_settings_repository.dart';
import 'package:endurain/core/services/platform/url_launcher_service.dart';
import 'package:endurain/features/activity/controllers/activity_recording_controller.dart';
import 'package:endurain/features/map/controllers/map_sensor_controller.dart';
import 'package:endurain/features/map/controllers/map_state_controller.dart';
import 'package:endurain/features/map/widgets/location_marker.dart';
import 'package:endurain/features/map/widgets/map_sensor_indicators.dart';
import 'package:endurain/features/sensors/models/sensor_measurement.dart';
import 'package:endurain/features/sensors/services/sensor_service.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:endurain/shared/map/map_tile_layer.dart';
import 'package:endurain/shared/state/owned_controllers.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({
    super.key,
    required this.activityController,
    required this.recordingOverlayBuilder,
    required this.urlLauncher,
    this.controller,
    this.locationService,
    this.mapSettings,
    this.sensorServices = const {},
    this.sensorControllers,
    this.recoverActiveRecordingOnOpen = false,
  }) : assert(
         controller != null || (locationService != null && mapSettings != null),
         'Pass a controller, or the location service and map settings to '
         'build one.',
       );

  /// The app-lifetime recording the map draws and the overlay drives. The map
  /// only observes it.
  final ActivityRecordingController activityController;

  /// Builds the recording UI laid over the map, so the map does not depend on
  /// the activity feature's widgets.
  final Widget Function(
    BuildContext context,
    ActivityRecordingController controller,
    double trailingReservedWidth,
  )
  recordingOverlayBuilder;

  /// Injected controller (tests); otherwise one is built from
  /// [locationService] and [mapSettings] and owned by the screen.
  final MapStateController? controller;
  final LocationService? locationService;
  final MapSettingsRepository? mapSettings;

  /// Opens the tile attribution link.
  final UrlLauncherService urlLauncher;

  /// The sensor coordinators the top-of-map indicators show, one controller
  /// each.
  final Map<SensorMeasurementKind, SensorService> sensorServices;

  /// Injected per-kind controllers (tests); a kind without one gets a
  /// controller built from its entry in [sensorServices].
  final Map<SensorMeasurementKind, MapSensorController>? sensorControllers;

  /// Whether opening the map resumes a recording that was interrupted (the
  /// app was killed mid-activity). The real app's map does; a map shown
  /// beside a stub controller must not.
  final bool recoverActiveRecordingOnOpen;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with OwnedControllers, WidgetsBindingObserver {
  static const double _activityOverlayTrailingReservedWidth =
      LocationMarkerConstants.buttonSize +
      LocationMarkerConstants.buttonOuterPadding * 2;

  final MapController _mapController = MapController();
  late final MapStateController _controller;
  late final ActivityRecordingController _activityController;
  late final Map<SensorMeasurementKind, MapSensorController> _sensorControllers;
  LatLng? _lastFollowedLocation;
  bool _centeredInitialLocation = false;

  // What the map layers were last built from. The recording controller
  // notifies every second for the elapsed time, which only the stats overlay
  // shows, so the map rebuilds only when one of these changes.
  Object? _builtPoints;
  Object? _builtSegments;
  bool _builtIsActive = false;

  List<Polyline> _routePolylines = const [];
  Object? _polylinesSource;

  /// One polyline per segment, reused while the segment is unchanged: a new
  /// GPS point only replaces the last segment, so finished segments are never
  /// converted to [LatLng] again.
  final Expando<Polyline> _polylineCache = Expando<Polyline>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = registerController(
      widget.controller,
      _createController,
      onChanged: _handleControllerChanged,
    );
    _activityController = observeController(
      widget.activityController,
      onChanged: _handleRecordingChanged,
    );
    _rememberBuiltTrack();
    final injectedSensorControllers = widget.sensorControllers;
    final sensorServices = widget.sensorServices;
    _sensorControllers = {
      for (final kind in {
        ...sensorServices.keys,
        ...?injectedSensorControllers?.keys,
      })
        kind: registerController(
          injectedSensorControllers?[kind],
          () => MapSensorController(service: sensorServices[kind]!, kind: kind),
        ),
    };
    // Reconnect any remembered sensors on map open so the user does not have to
    // visit the Sensors screen first; drives the top-of-map indicators (one
    // pill per connected/searching sensor).
    for (final controller in _sensorControllers.values) {
      unawaited(controller.initialize());
    }
    unawaited(_controller.initialize());
    if (widget.recoverActiveRecordingOnOpen) {
      unawaited(_activityController.recoverActiveRecording());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // OwnedControllers.dispose() (via super) tears down the registered
    // controllers; the MapController is owned directly here, so dispose it too.
    _mapController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // No map is visible in the background, so the map's own position stream
    // (separate from the native recorder) is paused until the app returns.
    switch (state) {
      case AppLifecycleState.resumed:
        _controller.setAppInForeground(true);
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _controller.setAppInForeground(false);
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  MapStateController _createController() {
    return MapStateController(
      locationService: widget.locationService!,
      mapSettingsRepository: widget.mapSettings!,
    );
  }

  void _handleControllerChanged() {
    if (!mounted) {
      return;
    }

    _controller.setRecordingActive(_activityController.state.isActive);
    setState(_rememberBuiltTrack);
    _syncMapToLocationState();
  }

  void _handleRecordingChanged() {
    if (!mounted) {
      return;
    }
    final state = _activityController.state;
    final mapChanged =
        !identical(state.points, _builtPoints) ||
        !identical(state.segments, _builtSegments) ||
        state.isActive != _builtIsActive;
    if (mapChanged) {
      _handleControllerChanged();
    }
  }

  void _rememberBuiltTrack() {
    final state = _activityController.state;
    _builtPoints = state.points;
    _builtSegments = state.segments;
    _builtIsActive = state.isActive;
  }

  void _syncMapToLocationState() {
    if (!_shouldShowLocationMarker) {
      return;
    }

    final displayLocation = _displayLocation;

    if (!_centeredInitialLocation) {
      _centeredInitialLocation = true;
      _lastFollowedLocation = displayLocation;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(displayLocation, MapConstants.initialLoadZoom);
      });
      return;
    }

    if (!_controller.isLocationLocked ||
        _lastFollowedLocation == displayLocation) {
      return;
    }

    _lastFollowedLocation = displayLocation;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.move(displayLocation, _mapController.camera.zoom);
    });
  }

  /// Toggle location lock
  void _toggleLocationLock() {
    _controller.toggleLocationLock();

    // If locking, center on current position
    if (_controller.isLocationLocked && _shouldShowLocationMarker) {
      _mapController.moveAndRotate(
        _displayLocation,
        _mapController.camera.zoom,
        0,
      );
    }
  }

  /// Handle map movement by user - unlock location
  void _onMapMoved() {
    _controller.unlockLocation();
  }

  /// Build map options with common configuration
  MapOptions _buildMapOptions() {
    return MapOptions(
      initialCenter: _controller.currentLocation,
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
  List<Widget> _buildMapLayers(BuildContext context) {
    final routePolylines = _polylines();

    return [
      ...buildMapTileLayers(
        tileServerUrl: _controller.tileServerUrl,
        attribution: _controller.tileAttribution,
        urlLauncher: widget.urlLauncher,
      ),
      if (routePolylines.isNotEmpty) PolylineLayer(polylines: routePolylines),
      if (_shouldShowLocationMarker)
        MarkerLayer(
          markers: [
            Marker(
              point: _displayLocation,
              width: LocationMarkerConstants.markerSize,
              height: LocationMarkerConstants.markerSize,
              alignment: Alignment.center,
              child: LocationMarker(heading: _displayHeading),
            ),
          ],
        ),
    ];
  }

  List<Polyline> _polylines() {
    final segments = _activityController.state.segments;
    if (identical(segments, _polylinesSource)) {
      return _routePolylines;
    }
    _polylinesSource = segments;
    return _routePolylines = [
      for (final segment in segments)
        if (segment.points.length > 1)
          _polylineCache[segment] ??= Polyline(
            points: [
              for (final point in segment.points)
                LatLng(point.latitude, point.longitude),
            ],
            strokeWidth: ActivityRouteConstants.strokeWidth,
            color: LocationMarkerConstants.activityBlue,
          ),
    ];
  }

  bool get _shouldShowLocationMarker {
    return _controller.hasLocationPermission ||
        _activityController.state.points.isNotEmpty;
  }

  LatLng get _displayLocation {
    final points = _activityController.state.points;
    if (points.isEmpty) {
      return _controller.currentLocation;
    }
    final lastPoint = points.last;
    return LatLng(lastPoint.latitude, lastPoint.longitude);
  }

  double get _displayHeading {
    final points = _activityController.state.points;
    if (points.isEmpty) {
      return _controller.heading;
    }
    return points.last.headingDegrees ?? _controller.heading;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    _activityController.configureBackgroundTracking(
      BackgroundLocationConfig(
        notificationTitle: l10n.activityTrackingNotificationTitle,
        notificationText: l10n.activityTrackingNotificationText,
      ),
    );

    return AdaptiveScaffold(
      safeArea: false,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: _buildMapOptions(),
            children: _buildMapLayers(context),
          ),
          if (_controller.isLoadingLocation)
            const Center(child: AdaptiveLoadingIndicator()),
          if (!_activityController.state.isActive)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(
                    LocationMarkerConstants.buttonOuterPadding,
                  ),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ListenableBuilder(
                      listenable: Listenable.merge(
                        _sensorControllers.values.toList(),
                      ),
                      builder: (context, _) => MapSensorIndicators(
                        controllers: _sensorControllers.values.toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          widget.recordingOverlayBuilder(
            context,
            _activityController,
            _activityOverlayTrailingReservedWidth,
          ),
        ],
      ),
      floatingActionButton: AdaptiveFloatingActionButton(
        onPressed: _toggleLocationLock,
        tooltip: l10n.myLocation,
        materialIcon: _controller.isLocationLocked
            ? Icons.my_location
            : Icons.location_searching,
        cupertinoIcon: _controller.isLocationLocked
            ? CupertinoIcons.location_solid
            : CupertinoIcons.location,
      ),
    );
  }
}
