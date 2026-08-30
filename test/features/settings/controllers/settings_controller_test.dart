import 'package:endurain/core/models/measurement_system.dart';
import 'package:endurain/core/models/app_exception.dart';
import 'package:endurain/core/services/platform/package_info_service.dart';
import 'package:endurain/core/services/secure_storage_service.dart';
import 'package:endurain/features/activity/repositories/activity_retention_settings_repository.dart';
import 'package:endurain/features/settings/controllers/measurement_system_controller.dart';
import 'package:endurain/features/settings/controllers/settings_controller.dart';
import 'package:endurain/features/settings/repositories/measurement_settings_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../helpers/fake_preferences_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MeasurementSystemController measurement;
  late _FakeRetentionSettings retention;

  SettingsController buildController({
    PackageInfoService? packageInfo,
    ActivityRetentionSettingsRepository? retentionRepository,
    SecureStorageService? storage,
  }) {
    return SettingsController(
      packageInfoService:
          packageInfo ?? const _FakePackageInfoService(version: '1.2.3'),
      retentionSettingsRepository: retentionRepository ?? retention,
      measurementSystemController: measurement,
      secureStorage: storage ?? SecureStorageService(),
    );
  }

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      'server_url': 'https://endurain.example.test',
    });
    retention = _FakeRetentionSettings();
    measurement = MeasurementSystemController(
      repository: MeasurementSettingsRepository(
        preferences: FakePreferencesStore(),
      ),
    );
  });

  tearDown(() => measurement.dispose());

  group('SettingsController.load', () {
    test('loads version, server URL, and retention preference', () async {
      retention.retainUploadedGpx = false;
      final controller = buildController();
      addTearDown(controller.dispose);

      await controller.load();

      expect(controller.appVersion, '1.2.3');
      expect(controller.serverUrl, 'https://endurain.example.test');
      expect(controller.retainUploadedGpx, isFalse);
    });

    test('notifies listeners as values arrive', () async {
      final controller = buildController();
      addTearDown(controller.dispose);
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.load();

      // One notification per successfully loaded field.
      expect(notifications, greaterThanOrEqualTo(3));
    });

    test('a failing secure storage does not block the other fields', () async {
      final controller = buildController(storage: _ThrowingSecureStorage());
      addTearDown(controller.dispose);

      await controller.load();

      // Settings must stay usable when the keychain is unavailable.
      expect(controller.serverUrl, isNull);
      expect(controller.appVersion, '1.2.3');
      expect(controller.retainUploadedGpx, isTrue);
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

    test('keeps the safe retention default when the read fails', () async {
      final controller = buildController(
        retentionRepository: _ThrowingRetentionSettings(),
      );
      addTearDown(controller.dispose);

      await controller.load();

      expect(controller.retainUploadedGpx, isTrue);
    });
  });

  group('SettingsController.setRetainUploadedGpx', () {
    test('persists the new value', () async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.load();

      await controller.setRetainUploadedGpx(false);

      expect(controller.retainUploadedGpx, isFalse);
      expect(retention.retainUploadedGpx, isFalse);
    });

    test('reverts the optimistic update when the write fails', () async {
      final controller = buildController(
        retentionRepository: _ThrowingRetentionSettings(),
      );
      addTearDown(controller.dispose);
      await controller.load();
      expect(controller.retainUploadedGpx, isTrue);

      await controller.setRetainUploadedGpx(false);

      // The switch must not keep showing a value that was never stored.
      expect(controller.retainUploadedGpx, isTrue);
    });
  });

  group('SettingsController measurement system', () {
    test('reflects the app-lifetime controller', () async {
      await measurement.setPreference(MeasurementSystem.imperial);
      final controller = buildController();
      addTearDown(controller.dispose);

      expect(controller.measurementSystem, MeasurementSystem.imperial);
    });

    test('delegates writes so the whole app sees the change', () async {
      final controller = buildController();
      addTearDown(controller.dispose);

      await controller.setMeasurementSystem(MeasurementSystem.imperial);

      expect(measurement.preference, MeasurementSystem.imperial);
      expect(controller.measurementSystem, MeasurementSystem.imperial);
    });

    test('null restores the device-region default', () async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.setMeasurementSystem(MeasurementSystem.metric);

      await controller.setMeasurementSystem(null);

      expect(measurement.preference, isNull);
      expect(controller.measurementSystem, isNull);
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

class _FakeRetentionSettings extends ActivityRetentionSettingsRepository {
  _FakeRetentionSettings() : super(preferences: FakePreferencesStore());

  bool retainUploadedGpx = true;

  @override
  Future<bool> isRetainUploadedGpxEnabled() async => retainUploadedGpx;

  @override
  Future<void> setRetainUploadedGpxEnabled(bool enabled) async {
    retainUploadedGpx = enabled;
  }
}

class _ThrowingRetentionSettings extends ActivityRetentionSettingsRepository {
  _ThrowingRetentionSettings() : super(preferences: FakePreferencesStore());

  @override
  Future<bool> isRetainUploadedGpxEnabled() async {
    throw const AppException(AppErrorCode.secureStorageReadFailed);
  }

  @override
  Future<void> setRetainUploadedGpxEnabled(bool enabled) async {
    throw const AppException(AppErrorCode.secureStorageWriteFailed);
  }
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
