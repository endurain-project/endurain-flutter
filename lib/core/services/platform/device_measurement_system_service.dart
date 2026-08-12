import 'package:endurain/core/models/measurement_system.dart';
import 'package:flutter/services.dart';

/// Reads the measurement system selected in the operating-system settings.
abstract interface class DeviceMeasurementSystemService {
  Future<MeasurementSystem?> getMeasurementSystem();
}

/// Platform-channel implementation used by the application composition root.
class PlatformDeviceMeasurementSystemService
    implements DeviceMeasurementSystemService {
  const PlatformDeviceMeasurementSystemService({
    MethodChannel channel = const MethodChannel(_channelName),
  }) : _channel = channel;

  static const String _channelName = 'endurain/device_settings';
  static const String _getMeasurementSystem = 'getMeasurementSystem';

  final MethodChannel _channel;

  @override
  Future<MeasurementSystem?> getMeasurementSystem() async {
    try {
      final value = await _channel.invokeMethod<String>(_getMeasurementSystem);
      return MeasurementSystem.fromJson(value);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}

/// Fallback for environments without a native measurement-system API.
class UnsupportedDeviceMeasurementSystemService
    implements DeviceMeasurementSystemService {
  const UnsupportedDeviceMeasurementSystemService();

  @override
  Future<MeasurementSystem?> getMeasurementSystem() async => null;
}
