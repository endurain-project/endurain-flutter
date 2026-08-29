import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:endurain/core/services/app_scope.dart';
import 'package:endurain/core/services/location_service.dart';
import 'package:endurain/core/services/location_settings_builder.dart';
import 'package:endurain/core/constants/map_constants.dart';
import 'package:endurain/core/utils/dialog_utils.dart';
import 'package:endurain/core/utils/platform_utils.dart';
import 'package:endurain/features/activity/controllers/activity_recording_controller.dart';
import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/models/audio_announcement_config.dart';
import 'package:endurain/features/activity/screens/activity_history_screen.dart';
import 'package:endurain/features/activity/services/activity_stats_formatter_scope.dart';
import 'package:endurain/features/activity/widgets/activity_recording_controls.dart';
import 'package:endurain/features/activity/widgets/activity_stop_confirmation_dialog.dart';
import 'package:endurain/features/map/repositories/map_settings_repository.dart';
import 'package:endurain/features/map/controllers/map_sensor_controller.dart';
import 'package:endurain/features/map/controllers/map_state_controller.dart';
import 'package:endurain/features/sensors/models/sensor_measurement.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:endurain/shared/state/owned_controllers.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({
    super.key,
    this.controller,
    this.activityController,
    this.sensorControllers,
    this.locationService,
    this.mapSettings,
  });

  final MapStateController? controller;
  final ActivityRecordingController? activityController;
  final Map<SensorMeasurementKind, MapSensorController>? sensorControllers;
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
  late final Map<SensorMeasurementKind, MapSensorController> _sensorControllers;
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
    _activityController = observeController(
      widget.activityController ??
          AppScope.servicesOf(
            context,
            listen: false,
          ).activityRecordingController,
      onChanged: _handleControllerChanged,
    );
    final injectedSensorControllers = widget.sensorControllers;
    final sensorServices = AppScope.servicesOf(
      context,
      listen: false,
    ).sensorServices;
    _sensorControllers = {
      for (final entry in sensorServices.entries)
        entry.key: registerController(
          injectedSensorControllers?[entry.key],
          () => MapSensorController(service: entry.value, kind: entry.key),
        ),
    };
    // Reconnect any remembered sensors on map open so the user does not have to
    // visit the Sensors screen first; drives the top-of-map indicators (one
    // pill per connected/searching sensor).
    for (final controller in _sensorControllers.values) {
      controller.initialize();
    }
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
          widget.mapSettings ?? services.createMapSettingsRepository(),
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
    _activityController.configureAudioAnnouncements(
      AudioAnnouncementConfig.build(
        l10n: l10n,
        settings: AppScope.servicesOf(
          context,
          listen: false,
        ).audioAnnouncementSettingsController.settings,
        activityType: _activityController.selectedActivityType,
        measurementSystem: context.measurementSystem,
        languageTag: context.numberFormatLocale,
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
                      builder: (context, _) => _MapSensorIndicators(
                        controllers: _sensorControllers.values.toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
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

/// Shared rounded pill container for the top-of-map indicators.
class _MapPill extends StatelessWidget {
  const _MapPill({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isApplePlatform = PlatformUtils.isApplePlatform;
    final backgroundColor = isApplePlatform
        ? CupertinoDynamicColor.resolve(
            CupertinoTheme.of(context).barBackgroundColor,
            context,
          )
        : Theme.of(context).colorScheme.surface;
    final textColor = isApplePlatform
        ? CupertinoColors.label.resolveFrom(context)
        : Theme.of(context).colorScheme.onSurface;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            blurRadius: 8,
            color: Color(0x33000000),
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
          child: child,
        ),
      ),
    );
  }
}

/// The top-of-map row of live sensor indicators.
///
/// Renders one pill per heart-rate, power, or cadence sensor that is connected
/// (live value) or searching (a remembered sensor still (re)connecting).
/// Sensors with no remembered device contribute nothing.
class _MapSensorIndicators extends StatelessWidget {
  const _MapSensorIndicators({required this.controllers});

  final List<MapSensorController> controllers;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];
    for (final controller in controllers) {
      switch (controller.status) {
        case MapSensorStatus.connected:
          chips.add(
            _MapSensorChip(
              kind: controller.kind,
              value: controller.currentValue!,
            ),
          );
        case MapSensorStatus.searching:
          chips.add(_MapSensorSearchingChip(kind: controller.kind));
        case MapSensorStatus.idle:
          break;
      }
    }
    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: chips,
    );
  }
}

/// The icon for a map sensor pill of [kind], matching the Sensors screen glyphs.
AdaptiveIcon _mapSensorIcon(SensorMeasurementKind kind) {
  return switch (kind) {
    SensorMeasurementKind.heartRate => const AdaptiveIcon(
      materialIcon: Icons.favorite,
      cupertinoIcon: CupertinoIcons.heart_fill,
      color: Color(0xFFE53935),
      size: 16,
    ),
    SensorMeasurementKind.power => const AdaptiveIcon(
      materialIcon: Icons.bolt,
      cupertinoIcon: CupertinoIcons.bolt_fill,
      size: 16,
    ),
    SensorMeasurementKind.cadence => const AdaptiveIcon(
      materialIcon: Icons.autorenew,
      cupertinoIcon: CupertinoIcons.arrow_2_circlepath,
      size: 16,
    ),
  };
}

/// The localized live value for a map sensor pill of [kind].
String _mapSensorValueLabel(
  AppLocalizations l10n,
  SensorMeasurementKind kind,
  int value,
) {
  return switch (kind) {
    SensorMeasurementKind.heartRate => l10n.sensorsBpm('$value'),
    SensorMeasurementKind.power => l10n.sensorsWatts('$value'),
    SensorMeasurementKind.cadence => l10n.sensorsRpm('$value'),
  };
}

/// Compact pill showing a live sensor value on the map.
class _MapSensorChip extends StatelessWidget {
  const _MapSensorChip({required this.kind, required this.value});

  final SensorMeasurementKind kind;
  final int value;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _MapPill(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _mapSensorIcon(kind),
          const SizedBox(width: 6),
          Text(_mapSensorValueLabel(l10n, kind, value)),
        ],
      ),
    );
  }
}

/// Compact pill shown while a remembered sensor of [kind] is being
/// (re)connected.
class _MapSensorSearchingChip extends StatelessWidget {
  const _MapSensorSearchingChip({required this.kind});

  final SensorMeasurementKind kind;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _MapPill(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _mapSensorIcon(kind),
          const SizedBox(width: 6),
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator.adaptive(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text(l10n.sensorsScanning),
        ],
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
