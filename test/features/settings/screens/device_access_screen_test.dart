import 'package:endurain/core/services/location_platform_adapter.dart';
import 'package:endurain/core/services/location_service.dart';
import 'package:endurain/features/health/controllers/health_sync_controller.dart';
import 'package:endurain/features/health/models/health_sdk_status.dart';
import 'package:endurain/features/settings/controllers/device_access_controller.dart';
import 'package:endurain/features/settings/screens/device_access_screen.dart';
import 'package:endurain/l10n/app_localizations_en.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

import '../../health/fakes/fake_health_sync_service.dart';

void main() {
  final l10n = AppLocalizationsEn();

  testWidgets('requests location access when it is not allowed', (
    tester,
  ) async {
    final adapter = _FakeLocationPlatformAdapter(
      permission: LocationPermission.denied,
      requestedPermission: LocationPermission.whileInUse,
    );
    final controller = DeviceAccessController(
      locationService: LocationService(platformAdapter: adapter),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      AdaptiveApp(
        title: 'Test',
        home: DeviceAccessScreen(
          controller: controller,
          healthSyncEnabled: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.deviceAccessLocationNotAllowed), findsOneWidget);

    await tester.tap(find.text(l10n.deviceAccessLocationTitle));
    await tester.pumpAndSettle();

    expect(adapter.requestPermissionCalled, isTrue);
    expect(find.text(l10n.deviceAccessLocationWhileUsing), findsOneWidget);
  });

  testWidgets('opens device settings when location services are off', (
    tester,
  ) async {
    final adapter = _FakeLocationPlatformAdapter(
      permission: LocationPermission.whileInUse,
      requestedPermission: LocationPermission.whileInUse,
      locationServiceEnabled: false,
    );
    final controller = DeviceAccessController(
      locationService: LocationService(platformAdapter: adapter),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      AdaptiveApp(
        title: 'Test',
        home: DeviceAccessScreen(
          controller: controller,
          healthSyncEnabled: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.deviceAccessLocationServicesOff), findsOneWidget);

    await tester.tap(find.text(l10n.deviceAccessLocationTitle));
    expect(adapter.openLocationSettingsCalled, isTrue);
  });

  testWidgets('opens app settings when location access is blocked', (
    tester,
  ) async {
    final adapter = _FakeLocationPlatformAdapter(
      permission: LocationPermission.deniedForever,
      requestedPermission: LocationPermission.deniedForever,
    );
    final controller = DeviceAccessController(
      locationService: LocationService(platformAdapter: adapter),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      AdaptiveApp(
        title: 'Test',
        home: DeviceAccessScreen(
          controller: controller,
          healthSyncEnabled: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.deviceAccessLocationBlocked), findsOneWidget);

    await tester.tap(find.text(l10n.deviceAccessLocationTitle));
    expect(adapter.openAppSettingsCalled, isTrue);
  });

  testWidgets('shows unavailable health access through the health section', (
    tester,
  ) async {
    final adapter = _FakeLocationPlatformAdapter(
      permission: LocationPermission.always,
      requestedPermission: LocationPermission.always,
    );
    final controller = DeviceAccessController(
      locationService: LocationService(platformAdapter: adapter),
    );
    final healthController = HealthSyncController(
      service: FakeHealthSyncService(sdkStatus: HealthSdkStatus.unsupported),
    );
    addTearDown(controller.dispose);
    addTearDown(healthController.dispose);

    await tester.pumpWidget(
      AdaptiveApp(
        title: 'Test',
        home: DeviceAccessScreen(
          controller: controller,
          healthController: healthController,
          healthSyncEnabled: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.deviceAccessLocationAlways), findsOneWidget);
    expect(find.text(l10n.deviceAccessHealthUnavailable), findsOneWidget);
  });
}

class _FakeLocationPlatformAdapter implements LocationPlatformAdapter {
  _FakeLocationPlatformAdapter({
    required this.permission,
    required this.requestedPermission,
    this.locationServiceEnabled = true,
  });

  LocationPermission permission;
  final LocationPermission requestedPermission;
  final bool locationServiceEnabled;
  bool requestPermissionCalled = false;
  bool openAppSettingsCalled = false;
  bool openLocationSettingsCalled = false;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<Position> getCurrentPosition({
    required LocationSettings locationSettings,
  }) {
    throw UnimplementedError();
  }

  @override
  Stream<Position> getPositionStream({
    required LocationSettings locationSettings,
  }) {
    return const Stream.empty();
  }

  @override
  Future<bool> isLocationServiceEnabled() async => locationServiceEnabled;

  @override
  Future<bool> openAppSettings() async {
    openAppSettingsCalled = true;
    return true;
  }

  @override
  Future<bool> openLocationSettings() async {
    openLocationSettingsCalled = true;
    return true;
  }

  @override
  Future<LocationPermission> requestPermission() async {
    requestPermissionCalled = true;
    permission = requestedPermission;
    return permission;
  }
}
