import 'package:endurain/core/auth/secure_storage_service.dart';
import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/services/platform/package_info_service.dart';
import 'package:endurain/features/settings/controllers/settings_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  SettingsController buildController({
    PackageInfoService? packageInfo,
    SecureStorageService? storage,
    Listenable? connectionChanges,
  }) {
    return SettingsController(
      packageInfoService:
          packageInfo ?? const _FakePackageInfoService(version: '1.2.3'),
      secureStorage: storage ?? SecureStorageService(),
      connectionChanges: connectionChanges,
    );
  }

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      'server_url': 'https://endurain.example.test',
    });
  });

  group('SettingsController.load', () {
    test('loads version and server URL', () async {
      final controller = buildController();
      addTearDown(controller.dispose);

      await controller.load();

      expect(controller.appVersion, '1.2.3');
      expect(controller.serverUrl, 'https://endurain.example.test');
    });

    test('notifies listeners as values arrive', () async {
      final controller = buildController();
      addTearDown(controller.dispose);
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.load();

      // One notification per successfully loaded field.
      expect(notifications, greaterThanOrEqualTo(2));
    });

    test('a failing secure storage does not block the other fields', () async {
      final controller = buildController(storage: _ThrowingSecureStorage());
      addTearDown(controller.dispose);

      await controller.load();

      // Settings must stay usable when the keychain is unavailable.
      expect(controller.serverUrl, isNull);
      expect(controller.appVersion, '1.2.3');
    });

    test('a failing package info does not block the other fields', () async {
      final controller = buildController(
        packageInfo: const _ThrowingPackageInfoService(),
      );
      addTearDown(controller.dispose);

      await controller.load();

      expect(controller.appVersion, isNull);
      expect(controller.serverUrl, 'https://endurain.example.test');
    });
  });

  group('SettingsController connection changes', () {
    test('re-reads the server URL when the session changes', () async {
      final changes = ValueNotifier<int>(0);
      addTearDown(changes.dispose);
      final storage = SecureStorageService();
      final controller = buildController(
        storage: storage,
        connectionChanges: changes,
      );
      addTearDown(controller.dispose);
      await controller.load();
      expect(controller.serverUrl, 'https://endurain.example.test');

      // Signed in to another server while the settings tab stayed alive.
      await storage.setServerUrl('https://other.example.test');
      changes.value++;
      await pumpEventQueue();

      expect(controller.serverUrl, 'https://other.example.test');
    });

    test('stops listening once disposed', () async {
      final changes = ValueNotifier<int>(0);
      addTearDown(changes.dispose);
      final controller = buildController(connectionChanges: changes);
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.dispose();
      changes.value++;
      await pumpEventQueue();

      expect(notifications, 0);
    });
  });

  test('does not notify after dispose', () async {
    final controller = buildController();
    var notifications = 0;
    controller.addListener(() => notifications++);
    controller.dispose();

    await controller.load();

    expect(notifications, 0);
  });
}

class _ThrowingSecureStorage extends SecureStorageService {
  @override
  Future<String?> getServerUrl() async {
    throw const AppException(AppErrorCode.secureStorageReadFailed);
  }
}

class _FakePackageInfoService extends PackageInfoService {
  const _FakePackageInfoService({required this.version});

  final String version;

  @override
  Future<PackageInfo> fromPlatform() async {
    return PackageInfo(
      appName: 'Endurain',
      packageName: 'com.endurain.mobile',
      version: version,
      buildNumber: '1',
    );
  }
}

class _ThrowingPackageInfoService extends PackageInfoService {
  const _ThrowingPackageInfoService();

  @override
  Future<PackageInfo> fromPlatform() async {
    throw StateError('package info unavailable');
  }
}
