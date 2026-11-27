import 'dart:async';

import 'package:endurain/features/sensors/models/ble_sensor_device.dart';
import 'package:endurain/features/sensors/services/sensor_profile.dart';
import 'package:endurain/features/sensors/services/universal_ble_sensor_connection_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_ble/universal_ble.dart';

/// Only the scan surface of the platform is faked; the rest are no-ops.
class _FakePlatform implements UniversalBlePlatform {
  Completer<void>? startGate;
  bool scanning = false;
  int startCalls = 0;
  int stopCalls = 0;

  @override
  Stream<BleDevice> get scanStream => const Stream<BleDevice>.empty();

  @override
  Future<void> startScan({
    ScanFilter? scanFilter,
    PlatformConfig? platformConfig,
  }) async {
    startCalls++;
    await startGate?.future;
    scanning = true;
  }

  @override
  Future<void> stopScan() async {
    stopCalls++;
    scanning = false;
  }

  @override
  Future<bool> isScanning() async => scanning;

  // Scan housekeeping calls (skip-duplicates, dedup reset) are no-ops.
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

void main() {
  late _FakePlatform platform;
  late UniversalBleSensorConnectionAdapter adapter;

  setUp(() {
    platform = _FakePlatform();
    UniversalBle.setInstance(platform);
    adapter = UniversalBleSensorConnectionAdapter(
      profiles: SensorProfiles.heartRate,
    );
  });

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 30));

  test('the timeout closes the stream and stops the scan', () async {
    final done = Completer<void>();
    adapter
        .scanForSensors(timeout: const Duration(milliseconds: 20))
        .listen((_) {}, onDone: done.complete);

    await done.future.timeout(const Duration(seconds: 2));
    await settle();

    expect(platform.scanning, isFalse);
    expect(platform.stopCalls, greaterThanOrEqualTo(1));
  });

  test(
    'cancelling while the scan is starting leaves no scan running',
    () async {
      platform.startGate = Completer<void>();
      final subscription = adapter
          .scanForSensors(timeout: const Duration(seconds: 5))
          .listen((List<BleSensorDevice> _) {});
      await settle();
      expect(platform.startCalls, 1);

      await subscription.cancel();
      platform.startGate!.complete();
      await settle();

      expect(platform.scanning, isFalse);
    },
  );
}
