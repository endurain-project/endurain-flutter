import 'dart:async';

import 'package:endurain/features/sensors/models/sensor_connection_status.dart';
import 'package:endurain/features/sensors/models/sensor_measurement.dart';
import 'package:endurain/features/sensors/services/sensor_service.dart';
import 'package:flutter/foundation.dart';

/// What a map sensor indicator should show.
enum MapSensorStatus {
  /// No sensor is remembered; show nothing.
  idle,

  /// A sensor is remembered but not yet reporting; show a "searching" hint.
  searching,

  /// A sensor is connected and reporting; show the live value.
  connected,
}

/// Drives one map sensor indicator (heart rate, power, or cadence).
///
/// Observes the app-lifetime [SensorService] for a single [kind] and, on map
/// open, kicks off an automatic reconnect of a remembered sensor so the user
/// does not have to visit the Sensors screen first. Surfaces the live value
/// while connected and a "searching" state while a remembered sensor is being
/// (re)connected. Route-scoped: it owns only its stream subscriptions and must
/// be disposed with the map screen; the underlying service is not disposed here.
class MapSensorController extends ChangeNotifier {
  MapSensorController({required SensorService service, required this.kind})
    : _service = service {
    _currentValue = _service.isConnected
        ? _service.latestMeasurement?.value
        : null;
    _sampleSubscription = _service.measurements.listen((measurement) {
      _currentValue = measurement.value;
      notifyListeners();
    });
    _statusSubscription = _service.connectionStatus.listen((status) {
      // Clear only on a terminal loss; keep the last reading during a transient
      // reconnect so the map indicator does not flicker.
      final lost =
          status == SensorConnectionStatus.disconnected ||
          status == SensorConnectionStatus.failed;
      if (lost) {
        _currentValue = null;
      }
      notifyListeners();
    });
  }

  /// The sensor kind this indicator represents.
  final SensorMeasurementKind kind;

  final SensorService _service;
  StreamSubscription<SensorMeasurement>? _sampleSubscription;
  StreamSubscription<SensorConnectionStatus>? _statusSubscription;

  int? _currentValue;
  bool _hasRememberedDevice = false;

  /// The latest value while a sensor is connected — bpm, watts, or rpm per
  /// [kind] — or `null` when no sensor is connected or before the first reading.
  int? get currentValue => _currentValue;

  /// What the indicator should render.
  MapSensorStatus get status {
    if (_currentValue != null) {
      return MapSensorStatus.connected;
    }
    if (_hasRememberedDevice) {
      return MapSensorStatus.searching;
    }
    return MapSensorStatus.idle;
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
