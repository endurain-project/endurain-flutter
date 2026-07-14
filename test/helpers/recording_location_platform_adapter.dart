import 'dart:async';

import 'package:endurain/core/services/platform/location_platform_adapter.dart';
import 'package:geolocator/geolocator.dart';

/// Builds a deterministic [Position] for activity-recording tests.
Position recordingPosition({
  double latitude = 41,
  double longitude = -8,
  DateTime? timestamp,
  double accuracy = 5,
}) {
  return Position(
    latitude: latitude,
    longitude: longitude,
    timestamp: timestamp ?? DateTime.utc(2026),
    accuracy: accuracy,
    altitude: 10,
    altitudeAccuracy: 1,
    heading: 90,
    headingAccuracy: 1,
    speed: 3,
    speedAccuracy: 1,
  );
}

/// A controllable [LocationPlatformAdapter] fake for recording flows.
///
/// Each call to [getPositionStream] creates a fresh subscription-counting
/// controller so tests can assert how many times the service listened to or
/// cancelled the location stream, and push positions/errors on demand.
class RecordingLocationPlatformAdapter implements LocationPlatformAdapter {
  RecordingLocationPlatformAdapter({
    this.serviceEnabled = true,
    this.permission = LocationPermission.whileInUse,
    this.requestedPermission = LocationPermission.whileInUse,
  });

  final List<StreamController<Position>> _controllers = [];
  final bool serviceEnabled;
  LocationPermission permission;
  final LocationPermission requestedPermission;
  int listenCount = 0;
  int cancelCount = 0;
  bool requestPermissionCalled = false;
  LocationSettings? lastPositionStreamSettings;

  void addPosition(Position position) {
    _controllers.last.add(position);
  }

  void addError(Object error) {
    _controllers.last.addError(error);
  }

  /// Closes the most recent position stream so the service's `onDone`
  /// handler fires, mirroring an OS-side stream shutdown.
  Future<void> closeStream() {
    return _controllers.last.close();
  }

  @override
  Future<LocationPermission> checkPermission() async {
    return permission;
  }

  @override
  Future<Position> getCurrentPosition({
    required LocationSettings locationSettings,
  }) async {
    return recordingPosition();
  }

  @override
  Stream<Position> getPositionStream({
    required LocationSettings locationSettings,
  }) {
    lastPositionStreamSettings = locationSettings;
    final controller = StreamController<Position>(
      onListen: () => listenCount += 1,
      onCancel: () => cancelCount += 1,
    );
    _controllers.add(controller);
    return controller.stream;
  }

  @override
  Future<bool> isLocationServiceEnabled() async {
    return serviceEnabled;
  }

  @override
  Future<bool> openLocationSettings() async {
    return true;
  }

  @override
  Future<bool> openAppSettings() async {
    return true;
  }

  @override
  Future<LocationPermission> requestPermission() async {
    requestPermissionCalled = true;
    permission = requestedPermission;
    return permission;
  }
}
