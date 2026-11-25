import 'dart:async';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:endurain/app/app_scope.dart';
import 'package:endurain/core/constants/map_constants.dart';
import 'package:endurain/core/location/location_service.dart';
import 'package:endurain/core/location/location_settings_builder.dart';
import 'package:endurain/core/utils/dialog_utils.dart';
import 'package:endurain/features/activity/controllers/activity_recording_controller.dart';
import 'package:endurain/features/activity/models/activity_recording_state.dart';
import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/models/audio_announcement_config.dart';
import 'package:endurain/features/activity/repositories/start_countdown_settings_repository.dart';
import 'package:endurain/features/activity/screens/activity_history_screen.dart';
import 'package:endurain/features/activity/services/activity_stats_formatter_scope.dart';
import 'package:endurain/features/activity/services/start_countdown.dart';
import 'package:endurain/features/activity/services/start_countdown_platform_adapter.dart';
import 'package:endurain/features/activity/widgets/activity_recording_controls.dart';
import 'package:endurain/features/activity/widgets/activity_stop_confirmation_dialog.dart';
import 'package:endurain/features/activity/widgets/start_countdown_dialog.dart';
import 'package:endurain/features/map/controllers/map_sensor_controller.dart';
import 'package:endurain/features/map/controllers/map_state_controller.dart';
import 'package:endurain/features/map/repositories/map_settings_repository.dart';
import 'package:endurain/features/map/widgets/location_marker.dart';
import 'package:endurain/features/map/widgets/map_sensor_indicators.dart';
import 'package:endurain/features/sensors/models/sensor_measurement.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:endurain/shared/state/owned_controllers.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({
    super.key,
    this.controller,
    this.activityController,
    this.sensorControllers,
    this.locationService,
    this.mapSettings,
    this.startCountdownSettings,
    this.startCountdownPlatform,
    this.countdownClock,
  });

  final MapStateController? controller;
  final ActivityRecordingController? activityController;
  final Map<SensorMeasurementKind, MapSensorController>? sensorControllers;
  final LocationService? locationService;
  final MapSettingsRepository? mapSettings;

  /// Test overrides for the start countdown; otherwise from [AppScope].
  final StartCountdownSettingsRepository? startCountdownSettings;
  final StartCountdownPlatformAdapter? startCountdownPlatform;

  /// Clock for the start countdown (tests pass the fake test clock).
  final DateTime Function()? countdownClock;

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
  bool _isStartCountdownOpen = false;

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
    final state = _activityController.state;
    if (_isStopConfirmationOpen || (!state.isActive && !state.canRecover)) {
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
    if (_isBackgroundPermissionFlowOpen || _isStartCountdownOpen) {
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

    final services = AppScope.servicesOf(context, listen: false);
    final announcements = AudioAnnouncementConfig.build(
      l10n: l10n,
      settings: services.audioAnnouncementSettingsController.settings,
      activityType: type,
      measurementSystem: context.measurementSystem,
      languageTag: context.numberFormatLocale,
    );
    final countdown =
        await (widget.startCountdownSettings ??
                services.activityStartCountdownSettings)
            .getConfig();
    if (!mounted) {
      return;
    }

    final countdownPlatform =
        widget.startCountdownPlatform ??
        services.activityStartCountdownPlatform;
    var countedDown = false;
    if (countdown.enabled) {
      final outcome = await _runStartCountdown(
        type: type,
        config: countdown,
        announcements: announcements,
        platform: countdownPlatform,
      );
      if (outcome == null) {
        // Skipped: location is not ready, so start right away and let the
        // recording report the problem as usual.
      } else if (outcome == StartCountdownOutcome.cancel || !mounted) {
        await _safely(countdownPlatform.endWarmUp);
        return;
      } else {
        countedDown = true;
      }
    }

    _activityController.configureAudioAnnouncements(announcements);
    try {
      await _activityController.start(type);
    } finally {
      // Ended only after the recorder has started, so the app stays awake
      // (and GPS warm) right up to the first point. On Android the recording
      // has taken over the warm-up's service by now, so this leaves it alone.
      if (countedDown) {
        await _safely(countdownPlatform.endWarmUp);
      }
    }
    if (countedDown &&
        countdown.voiceEnabled &&
        _activityController.state.status == ActivityRecordingStatus.recording) {
      await _safely(
        () => countdownPlatform.speakCue(
          l10n.audioAnnouncementsRecordingStarted,
          duckOtherAudio: announcements.duckOtherAudio,
          languageTag: announcements.languageTag,
        ),
      );
    }
  }

  /// Shows the start countdown. Returns null when it was skipped because
  /// location is not ready, otherwise how it ended.
  Future<StartCountdownOutcome?> _runStartCountdown({
    required ActivityType type,
    required StartCountdownConfig config,
    required AudioAnnouncementConfig announcements,
    required StartCountdownPlatformAdapter platform,
  }) async {
    // Settle any location prompt now, while the phone is still in hand.
    final locationReady = await _activityController.isLocationReady();
    if (!mounted || !locationReady) {
      return null;
    }
    _isStartCountdownOpen = true;
    try {
      await _safely(platform.beginWarmUp);
      if (!mounted) {
        return StartCountdownOutcome.cancel;
      }
      return await showStartCountdownDialog(
        context,
        seconds: config.seconds,
        activityType: type,
        now: widget.countdownClock,
        onCue: config.voiceEnabled
            ? (secondsLeft) => unawaited(
                _safely(
                  () => platform.speakCue(
                    '$secondsLeft',
                    duckOtherAudio: announcements.duckOtherAudio,
                    languageTag: announcements.languageTag,
                  ),
                ),
              )
            : null,
      );
    } finally {
      _isStartCountdownOpen = false;
    }
  }

  /// Runs a best-effort native countdown call: a missing speech engine or
  /// warm-up must never block starting a recording.
  Future<void> _safely(Future<void> Function() call) async {
    try {
      await call();
    } catch (_) {}
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
              child: LocationMarker(heading: _displayHeading),
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
