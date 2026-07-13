import 'dart:async';

import 'package:endurain/core/services/location_platform_adapter.dart';
import 'package:geolocator/geolocator.dart';

Position testPosition({
  double latitude = 41.0,
  double longitude = -8.0,
  double heading = 0,
}) {
  return Position(
    latitude: latitude,
    longitude: longitude,
    timestamp: DateTime.utc(2026),
    accuracy: 5,
    altitude: 10,
    altitudeAccuracy: 1,
    heading: heading,
    headingAccuracy: 1,
    speed: 3,
    speedAccuracy: 1,
  );
}

class FakeLocationPlatformAdapter implements LocationPlatformAdapter {
  FakeLocationPlatformAdapter({
    Position? currentPosition,
    this.completeCurrentPosition = true,
    this.serviceEnabled = true,
    this.permission = LocationPermission.whileInUse,
    this.requestedPermission = LocationPermission.whileInUse,
  }) : currentPosition = currentPosition ?? testPosition();

  final Position currentPosition;
  final bool completeCurrentPosition;
  final bool serviceEnabled;
  final LocationPermission permission;
  final LocationPermission requestedPermission;
  int openAppSettingsCallCount = 0;
  final _positionController = StreamController<Position>.broadcast();
  final _currentPositionCompleter = Completer<Position>();

  void addPosition(Position position) {
    _positionController.add(position);
  }

  void addPositionError(Object error) {
    _positionController.addError(error);
  }

  void completePosition() {
    if (!_currentPositionCompleter.isCompleted) {
      _currentPositionCompleter.complete(currentPosition);
    }
  }

  Future<void> close() {
    return _positionController.close();
  }

  @override
  Future<LocationPermission> checkPermission() async {
    return permission;
  }

  @override
  Future<Position> getCurrentPosition({
    required LocationSettings locationSettings,
  }) async {
    if (completeCurrentPosition) {
      return currentPosition;
    }

    return _currentPositionCompleter.future;
  }

  @override
  Stream<Position> getPositionStream({
    required LocationSettings locationSettings,
  }) {
    return _positionController.stream;
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
    openAppSettingsCallCount += 1;
    return true;
  }

  @override
  Future<LocationPermission> requestPermission() async {
    return requestedPermission;
  }
}
