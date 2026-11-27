import 'package:endurain/core/location/location_service.dart';
import 'package:endurain/features/settings/controllers/device_access_controller.dart';
import 'package:endurain/features/settings/models/bluetooth_access_state.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

import '../../../helpers/fake_location_platform_adapter.dart';

void main() {
  DeviceAccessController makeController(FakeLocationPlatformAdapter adapter) {
    return DeviceAccessController(
      locationService: LocationService(platformAdapter: adapter),
    );
  }

  test('load reads service and permission state', () async {
    final controller = makeController(
      FakeLocationPlatformAdapter(permission: LocationPermission.always),
    );
    addTearDown(controller.dispose);

    await controller.load();

    expect(controller.isLoading, isFalse);
    expect(controller.isLocationServiceEnabled, isTrue);
    expect(controller.locationPermission, LocationPermission.always);
  });

  test('load stops loading when the platform throws', () async {
    final controller = makeController(
      FakeLocationPlatformAdapter(
        platformError: PlatformException(code: 'channel-error'),
      ),
    );
    addTearDown(controller.dispose);

    await controller.load();

    expect(controller.isLoading, isFalse);
    expect(controller.isLocationServiceEnabled, isFalse);
    expect(controller.locationPermission, LocationPermission.unableToDetermine);
  });

  test('requestLocationAccess survives a platform failure', () async {
    final controller = makeController(
      FakeLocationPlatformAdapter(
        platformError: PlatformException(code: 'channel-error'),
      ),
    );
    addTearDown(controller.dispose);

    await controller.requestLocationAccess();

    expect(controller.locationPermission, LocationPermission.unableToDetermine);
  });

  group('bluetooth access', () {
    test('has no Bluetooth row without a checker', () async {
      final controller = makeController(FakeLocationPlatformAdapter());
      addTearDown(controller.dispose);

      await controller.load();
      await controller.requestBluetoothAccess();

      expect(controller.hasBluetooth, isFalse);
    });

    test('load reads the state and request updates it', () async {
      var state = BluetoothAccessState.notDetermined;
      final controller = DeviceAccessController(
        locationService: LocationService(
          platformAdapter: FakeLocationPlatformAdapter(),
        ),
        checkBluetoothAccess: () async => state,
        requestBluetoothAccess: () async => BluetoothAccessState.ready,
      );
      addTearDown(controller.dispose);

      await controller.load();
      expect(controller.hasBluetooth, isTrue);
      expect(controller.bluetoothAccess, BluetoothAccessState.notDetermined);

      state = BluetoothAccessState.off;
      await controller.requestBluetoothAccess();
      expect(controller.bluetoothAccess, BluetoothAccessState.ready);
    });

    test('a failing check reports unavailable', () async {
      final controller = DeviceAccessController(
        locationService: LocationService(
          platformAdapter: FakeLocationPlatformAdapter(),
        ),
        checkBluetoothAccess: () async => throw StateError('boom'),
        requestBluetoothAccess: () async => throw StateError('boom'),
      );
      addTearDown(controller.dispose);

      await controller.load();
      expect(controller.bluetoothAccess, BluetoothAccessState.unavailable);

      await controller.requestBluetoothAccess();
      expect(controller.bluetoothAccess, BluetoothAccessState.unavailable);
    });
  });
}
