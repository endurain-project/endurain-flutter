import 'package:endurain/app/app_services.dart';
import 'package:endurain/features/health/services/health_package_platform_adapter.dart';
import 'package:endurain/features/health/services/health_platform_adapter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppServices services;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    services = AppServices();
  });

  tearDown(() => debugDefaultTargetPlatformOverride = null);

  group('HealthModule', () {
    test('shares one sync service and builds a controller per route', () {
      final health = services.health;

      expect(identical(health.syncService, health.syncService), isTrue);
      expect(identical(health.autoSyncService, health.autoSyncService), isTrue);
      expect(identical(health.syncSettings, health.syncSettings), isTrue);
      expect(
        identical(health.importRepository, health.importRepository),
        isTrue,
      );

      final first = health.createSyncController();
      final second = health.createSyncController();
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      expect(identical(first, second), isFalse);
    });

    test('uses the health package on Android and iOS', () {
      for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
        debugDefaultTargetPlatformOverride = platform;
        expect(
          services.health.createPlatformAdapter(),
          isA<HealthPackagePlatformAdapter>(),
          reason: '$platform',
        );
      }
    });

    test('falls back to the unsupported adapter elsewhere', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;

      expect(
        services.health.createPlatformAdapter(),
        isA<UnsupportedHealthPlatformAdapter>(),
      );
    });
  });
}
