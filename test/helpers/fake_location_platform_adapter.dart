import 'dart:async';

import 'package:endurain/core/services/platform/location_platform_adapter.dart';
import 'package:flutter/services.dart';
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
    this.platformError,
  }) : currentPosition = currentPosition ?? testPosition();

  final Position currentPosition;
  final bool completeCurrentPosition;
  final bool serviceEnabled;
  final LocationPermission permission;
  final LocationPermission requestedPermission;

  /// When set, the service/permission calls throw it (e.g. a
  /// PlatformException from the native channel).
  final PlatformException? platformError;
  int openAppSettingsCallCount = 0;
  final _positionController = StreamController<Position>.broadcast();
  final _currentPositionCompleter = Completer<Position>();

  void _throwIfConfigured() {
    final error = platformError;
    if (error != null) {
      throw error;
    }
  }

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
    _throwIfConfigured();
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
    _throwIfConfigured();
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
    _throwIfConfigured();
    return requestedPermission;
  }
}
