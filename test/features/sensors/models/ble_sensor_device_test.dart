import 'package:endurain/features/sensors/models/ble_sensor_device.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BleSensorDevice', () {
    test('equality and hashCode are based on the device id', () {
      const a = BleSensorDevice(id: 'AA:BB', name: 'Polar H10', rssi: -50);
      const b = BleSensorDevice(id: 'AA:BB', name: 'Different', rssi: -80);
      const c = BleSensorDevice(id: 'CC:DD', name: 'Polar H10');

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
    });
  });
}
