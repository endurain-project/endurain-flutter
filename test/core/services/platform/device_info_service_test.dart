import 'package:device_info_plus/device_info_plus.dart';
import 'package:endurain/core/services/platform/device_info_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DeviceInfoService', () {
    test('reports the Android release and model, never the device name', () {
      final summary = DeviceInfoService.androidSummary(
        AndroidDeviceInfo.setMockInitialValues(
          version: AndroidBuildVersion.setMockInitialValues(
            codename: 'REL',
            incremental: '123',
            previewSdkInt: 0,
            release: '15',
            sdkInt: 35,
            securityPatch: '2026-10-01',
          ),
          board: 'board',
          bootloader: 'bootloader',
          brand: 'google',
          device: 'device',
          display: 'display',
          fingerprint: 'google/device/secret-fingerprint',
          hardware: 'hardware',
          host: 'build-host',
          id: 'BUILD.ID',
          manufacturer: 'Google',
          model: 'Pixel 9',
          product: 'product',
          name: "Jane's Pixel",
          supported32BitAbis: const [],
          supported64BitAbis: const [],
          supportedAbis: const [],
          tags: 'release-keys',
          time: 0,
          type: 'user',
          isPhysicalDevice: true,
          freeDiskSize: 1,
          totalDiskSize: 2,
          systemFeatures: const [],
          isLowRamDevice: false,
          physicalRamSize: 8,
          availableRamSize: 4,
        ),
      );

      expect(summary, {
        'osVersion': 'Android 15 (SDK 35)',
        'manufacturer': 'Google',
        'model': 'Pixel 9',
        'physicalDevice': true,
        'lowRamDevice': false,
      });
    });

    test('reports the iOS version and model, never the name or identifier', () {
      final summary = DeviceInfoService.iosSummary(
        IosDeviceInfo.setMockInitialValues(
          name: "Jane's iPhone",
          systemName: 'iOS',
          systemVersion: '26.1',
          model: 'iPhone',
          modelName: 'iPhone 15 Pro',
          localizedModel: 'iPhone',
          freeDiskSize: 1,
          totalDiskSize: 2,
          identifierForVendor: 'VENDOR-ID-1234',
          isPhysicalDevice: true,
          isiOSAppOnMac: false,
          isiOSAppOnVision: false,
          physicalRamSize: 8,
          availableRamSize: 4,
          utsname: IosUtsname.setMockInitialValues(
            sysname: 'Darwin',
            nodename: 'Janes-iPhone',
            release: '25.0.0',
            version: 'Darwin Kernel',
            machine: 'iPhone16,1',
          ),
        ),
      );

      expect(summary, {
        'osVersion': 'iOS 26.1',
        'model': 'iPhone16,1',
        'modelName': 'iPhone 15 Pro',
        'physicalDevice': true,
      });
    });
  });
}
