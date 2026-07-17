import 'dart:async';

import 'package:endurain/features/sensors/models/heart_rate_sample.dart';
import 'package:endurain/features/sensors/models/sensor_connection_status.dart';
import 'package:endurain/features/sensors/services/heart_rate_sensor_service.dart';
import 'package:flutter/foundation.dart';

/// What the map's heart-rate indicator should show.
enum MapHeartRateStatus {
  /// No sensor is remembered; show nothing.
  idle,

  /// A sensor is remembered but not yet reporting; show a "searching" hint.
  searching,

  /// A sensor is connected and reporting; show the live bpm.
  connected,
}

/// Drives the map's heart-rate indicator.
///
/// Observes the app-lifetime [HeartRateSensorService] and, on map open, kicks
/// off an automatic reconnect of a remembered sensor so the user does not have
/// to visit the Sensors screen first. Surfaces the live bpm while connected and
/// a "searching" state while a remembered sensor is being (re)connected.
/// Route-scoped: it owns only its stream subscriptions and must be disposed with
/// the map screen; the underlying service is not disposed here.
class MapHeartRateController extends ChangeNotifier {
  MapHeartRateController({required HeartRateSensorService service})
    : _service = service {
    _currentBpm = _service.isConnected ? _service.latestSample?.bpm : null;
    _sampleSubscription = _service.heartRate.listen((sample) {
      _currentBpm = sample.bpm;
      notifyListeners();
    });
    _statusSubscription = _service.connectionStatus.listen((status) {
      // Clear only on a terminal loss; keep the last reading during a transient
      // reconnect so the map indicator does not flicker.
      final lost =
          status == SensorConnectionStatus.disconnected ||
          status == SensorConnectionStatus.failed;
      if (lost) {
        _currentBpm = null;
      }
      notifyListeners();
    });
  }

  final HeartRateSensorService _service;
  StreamSubscription<HeartRateSample>? _sampleSubscription;
  StreamSubscription<SensorConnectionStatus>? _statusSubscription;

  int? _currentBpm;
  bool _hasRememberedDevice = false;

  /// The latest heart rate in beats per minute while a sensor is connected, or
  /// `null` when no sensor is connected or before the first reading.
  int? get currentBpm => _currentBpm;

  /// What the map indicator should render.
  MapHeartRateStatus get status {
    if (_currentBpm != null) {
      return MapHeartRateStatus.connected;
    }
    if (_hasRememberedDevice) {
      return MapHeartRateStatus.searching;
    }
    return MapHeartRateStatus.idle;
  }

  /// On map open: if a sensor is remembered, reflect the searching state and
  /// trigger an automatic reconnect. Best-effort; a no-op when nothing is
  /// remembered.
  Future<void> initialize() async {
    _hasRememberedDevice = await _service.hasRememberedDevice();
    notifyListeners();
    if (_hasRememberedDevice && !_service.isConnected) {
      await _service.autoConnectRemembered();
    }
  }

  @override
  void dispose() {
    _sampleSubscription?.cancel();
    _statusSubscription?.cancel();
    super.dispose();
  }
}
