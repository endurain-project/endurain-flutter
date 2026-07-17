import 'package:endurain/features/sensors/models/ble_sensor_device.dart';
import 'package:endurain/features/sensors/models/sensor_bluetooth_state.dart';
import 'package:endurain/features/sensors/services/heart_rate_sensor_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UnsupportedHeartRateSensorAdapter', () {
    const adapter = UnsupportedHeartRateSensorAdapter();

    test('reports Bluetooth as unsupported', () async {
      expect(
        await adapter.currentBluetoothState(),
        SensorBluetoothState.unsupported,
      );
      expect(
        await adapter.bluetoothState.first,
        SensorBluetoothState.unsupported,
      );
    });

    test('denies permissions and yields no scan results', () async {
      expect(await adapter.ensurePermissions(), isFalse);
      expect(await adapter.scanForHeartRateSensors().isEmpty, isTrue);
    });

    test('connect, disconnect, stopScan, and dispose are no-ops', () async {
      await adapter.connect(const BleSensorDevice(id: 'x', name: 'y'));
      await adapter.disconnect();
      await adapter.stopScan();
      await adapter.dispose();
      expect(await adapter.connectionStatus.isEmpty, isTrue);
      expect(await adapter.heartRate.isEmpty, isTrue);
    });
  });
}
