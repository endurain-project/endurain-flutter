import 'package:endurain/features/sensors/models/sensor_bluetooth_state.dart';
import 'package:endurain/features/sensors/models/sensor_permission_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SensorPermissionResult.fromBluetoothState', () {
    test('maps unauthorized to denied', () {
      expect(
        SensorPermissionResult.fromBluetoothState(
          SensorBluetoothState.unauthorized,
        ),
        SensorPermissionResult.denied,
      );
    });

    test('maps unsupported to unavailable', () {
      expect(
        SensorPermissionResult.fromBluetoothState(
          SensorBluetoothState.unsupported,
        ),
        SensorPermissionResult.unavailable,
      );
    });

    test('grants scanning for every usable or undetermined state', () {
      for (final state in [
        SensorBluetoothState.unknown,
        SensorBluetoothState.off,
        SensorBluetoothState.ready,
      ]) {
        expect(
          SensorPermissionResult.fromBluetoothState(state).isGranted,
          isTrue,
          reason: '$state',
        );
      }
    });
  });
}
