import 'package:endurain/core/models/measurement_system.dart';
import 'package:endurain/core/services/platform/device_measurement_system_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('test/device_settings');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('reads the native measurement system', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'getMeasurementSystem');
      return 'metric';
    });
    const service = PlatformDeviceMeasurementSystemService(channel: channel);

    expect(await service.getMeasurementSystem(), MeasurementSystem.metric);
  });

  test('returns null for an unsupported native value', () async {
    messenger.setMockMethodCallHandler(channel, (_) async => 'unknown');
    const service = PlatformDeviceMeasurementSystemService(channel: channel);

    expect(await service.getMeasurementSystem(), isNull);
  });

  test('returns null when the platform method is unavailable', () async {
    const service = PlatformDeviceMeasurementSystemService(channel: channel);

    expect(await service.getMeasurementSystem(), isNull);
  });
}
