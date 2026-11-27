import 'package:endurain/core/location/location_service.dart';
import 'package:endurain/features/settings/controllers/device_access_controller.dart';
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
}
