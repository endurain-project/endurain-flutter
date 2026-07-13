import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:endurain/core/services/app_scope.dart';
import 'package:endurain/core/services/location_service.dart';
import 'package:endurain/core/services/location_settings_builder.dart';
import 'package:endurain/core/constants/map_constants.dart';
import 'package:endurain/core/utils/dialog_utils.dart';
import 'package:endurain/features/activity/controllers/activity_recording_controller.dart';
import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/screens/activity_history_screen.dart';
import 'package:endurain/features/activity/widgets/activity_recording_controls.dart';
import 'package:endurain/features/activity/widgets/activity_stop_confirmation_dialog.dart';
import 'package:endurain/features/map/repositories/map_settings_repository.dart';
import 'package:endurain/features/map/controllers/map_state_controller.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:endurain/shared/state/owned_controllers.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({
    super.key,
    this.controller,
    this.activityController,
    this.locationService,
    this.mapSettings,
  });

  final MapStateController? controller;
  final ActivityRecordingController? activityController;
  final LocationService? locationService;
  final MapSettingsRepository? mapSettings;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with OwnedControllers {
  static const double _activityOverlayTrailingReservedWidth =
      LocationMarkerConstants.buttonSize +
      LocationMarkerConstants.buttonOuterPadding * 2;

  final MapController _mapController = MapController();
  late final MapStateController _controller;
  late final ActivityRecordingController _activityController;
  LatLng? _lastFollowedLocation;
  bool _centeredInitialLocation = false;
  bool _isStopConfirmationOpen = false;
  bool _isBackgroundPermissionFlowOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = registerController(
      widget.controller,
      _createController,
      onChanged: _handleControllerChanged,
    );
    _activityController = registerController(
      widget.activityController ??
          AppScope.servicesOf(
            context,
            listen: false,
          ).activityRecordingController,
      // create() is unreachable because we always supply an injected value
      // above; the controller is owned by AppServices for the app lifetime.
      () => throw StateError('unreachable: activity controller not in scope'),
      onChanged: _handleControllerChanged,
    );
    _controller.initialize();
    if (widget.activityController == null) {
      unawaited(_activityController.recoverActiveRecording());
    }
  }

  @override
  void dispose() {
    // OwnedControllers.dispose() (via super) tears down the registered
    // controllers; the MapController is owned directly here, so dispose it too.
    _mapController.dispose();
    super.dispose();
  }

  MapStateController _createController() {
    final services = AppScope.servicesOf(context, listen: false);
    return MapStateController(
      locationService: widget.locationService ?? services.location,
      mapSettingsRepository:
          widget.mapSettings ??
          MapSettingsRepository(
            preferences: services.preferences,
            activeConnectionOrigin: services.authSession.getAuthenticatedOrigin,
          ),
    );
  }

  void _handleControllerChanged() {
    if (!mounted) {
      return;
    }

    _controller.setRecordingActive(_activityController.state.isActive);
    setState(() {});
    _syncMapToLocationState();
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

  Future<void> _confirmStopActivity() async {
    if (_isStopConfirmationOpen || !_activityController.state.isActive) {
      return;
    }

    _isStopConfirmationOpen = true;
    final action = await showActivityStopConfirmationDialog(context);
    _isStopConfirmationOpen = false;

    if (!mounted) {
      return;
    }

    switch (action) {
      case ActivityStopAction.cancel:
        return;
      case ActivityStopAction.stop:
        await _activityController.stop();
      case ActivityStopAction.discard:
        await _activityController.discard();
    }
  }

  Future<void> _startActivity(ActivityType type) async {
    if (_isBackgroundPermissionFlowOpen) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final backgroundTrackingReady = await _activityController
        .isBackgroundTrackingReady();
    if (!mounted) {
      return;
    }

    if (!backgroundTrackingReady) {
      _isBackgroundPermissionFlowOpen = true;
      final shouldContinue = await DialogUtils.showConfirmDialog(
        context,
        title: l10n.activityBackgroundPermissionTitle,
        message: l10n.activityBackgroundPermissionMessage,
        confirmText: l10n.activityBackgroundPermissionContinue,
      );
      _isBackgroundPermissionFlowOpen = false;
      if (!mounted || !shouldContinue) {
        return;
      }

      final permissionReady = await _activityController
          .requestBackgroundTrackingPermission();
      if (!mounted) {
        return;
      }
      if (!permissionReady) {
        _isBackgroundPermissionFlowOpen = true;
        final openSettings = await DialogUtils.showConfirmDialog(
          context,
          title: l10n.activityBackgroundPermissionSettingsTitle,
          message: l10n.activityBackgroundPermissionSettingsMessage,
          confirmText: l10n.activityOpenSettings,
        );
        _isBackgroundPermissionFlowOpen = false;
        if (mounted && openSettings) {
          await _activityController.openLocationSettings();
        }
        return;
      }
    }

    await _activityController.start(type);
  }

  Future<void> _deleteCompletedActivity() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await DialogUtils.showConfirmDialog(
      context,
      title: l10n.activityDeleteLocalConfirmTitle,
      message: l10n.activityDeleteLocalConfirmMessage,
      confirmText: l10n.activityDeleteLocal,
      isDestructive: true,
    );
    if (!mounted || !confirmed) {
      return;
    }
    await _activityController.discard();
  }

  void _openActivityHistory() {
    adaptivePush<void>(context, (context) => const ActivityHistoryScreen());
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
    final routePolylines = _activityController.state.segments
        .where((segment) => segment.points.length > 1)
        .map(
          (segment) => Polyline(
            points: [
              for (final point in segment.points)
                LatLng(point.latitude, point.longitude),
            ],
            strokeWidth: ActivityRouteConstants.strokeWidth,
            color: LocationMarkerConstants.activityBlue,
          ),
        )
        .toList(growable: false);

    return [
      TileLayer(
        urlTemplate: _controller.tileServerUrl,
        userAgentPackageName: MapConstants.userAgent,
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
              child: _LocationMarker(heading: _displayHeading),
            ),
          ],
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
          ActivityRecordingControls(
            state: _activityController.state,
            selectedActivityType: _activityController.selectedActivityType,
            trailingReservedWidth: _activityOverlayTrailingReservedWidth,
            onActivityTypeChanged: _activityController.selectActivityType,
            onStart: _startActivity,
            onPause: _activityController.pause,
            onResume: _activityController.resume,
            onStop: _confirmStopActivity,
            uploadStatus: _activityController.uploadStatus,
            uploadError: _activityController.uploadError,
            onRetryUpload: _activityController.uploadCompletedGpx,
            onDone: _activityController.clearCompleted,
            onDelete: _deleteCompletedActivity,
            onViewHistory: _openActivityHistory,
            onOpenLocationSettings: _activityController.openLocationSettings,
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
      ..color = LocationMarkerConstants.activityBlue.withValues(
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
      ..color = LocationMarkerConstants.activityBlue
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
