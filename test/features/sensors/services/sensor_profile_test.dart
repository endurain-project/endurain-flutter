import 'package:endurain/features/sensors/models/ble_sensor_device.dart';
import 'package:endurain/features/sensors/models/sensor_bluetooth_state.dart';
import 'package:endurain/features/sensors/models/sensor_measurement.dart';
import 'package:endurain/features/sensors/services/sensor_connection_adapter.dart';
import 'package:endurain/features/sensors/services/sensor_measurement_decoder.dart';
import 'package:endurain/features/sensors/services/sensor_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SensorProfiles', () {
    test('power profile targets the Cycling Power GATT service', () {
      expect(SensorProfiles.cyclingPower.serviceUuid, '1818');
      expect(SensorProfiles.cyclingPower.measurementCharacteristicUuid, '2A63');
      expect(SensorProfiles.cyclingPower.kind, SensorMeasurementKind.power);
      expect(SensorProfiles.power, [SensorProfiles.cyclingPower]);
    });

    test('cadence covers both cycling (CSC) and running (RSC) services', () {
      expect(SensorProfiles.cyclingSpeedCadence.serviceUuid, '1816');
      expect(
        SensorProfiles.cyclingSpeedCadence.measurementCharacteristicUuid,
        '2A5B',
      );
      expect(SensorProfiles.runningSpeedCadence.serviceUuid, '1814');
      expect(
        SensorProfiles.runningSpeedCadence.measurementCharacteristicUuid,
        '2A53',
      );
      expect(SensorProfiles.cadence, [
        SensorProfiles.cyclingSpeedCadence,
        SensorProfiles.runningSpeedCadence,
      ]);
    });

    test('createDecoder builds the matching decoder implementation', () {
      expect(
        SensorProfiles.cyclingPower.createDecoder(),
        isA<CyclingPowerMeasurementDecoder>(),
      );
      expect(
        SensorProfiles.cyclingSpeedCadence.createDecoder(),
        isA<CyclingSpeedCadenceMeasurementDecoder>(),
      );
      expect(
        SensorProfiles.runningSpeedCadence.createDecoder(),
        isA<RunningSpeedCadenceMeasurementDecoder>(),
      );
    });

    test('createDecoder yields independent (per-connection) instances', () {
      expect(
        SensorProfiles.cyclingSpeedCadence.createDecoder(),
        isNot(same(SensorProfiles.cyclingSpeedCadence.createDecoder())),
      );
    });
  });

  group('UnsupportedSensorConnectionAdapter', () {
    const adapter = UnsupportedSensorConnectionAdapter();

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

    test('never grants permission and never scans', () async {
      expect(await adapter.ensurePermissions(), isFalse);
      expect(await adapter.scanForSensors().isEmpty, isTrue);
    });

    test('emits no status or measurements', () async {
      expect(await adapter.connectionStatus.isEmpty, isTrue);
      expect(await adapter.measurements.isEmpty, isTrue);
    });

    test('connect, disconnect, stopScan, and dispose are no-ops', () async {
      await adapter.stopScan();
      await adapter.connect(const BleSensorDevice(id: 'x', name: 'y'));
      await adapter.disconnect();
      await adapter.dispose();
    });
  });
}
