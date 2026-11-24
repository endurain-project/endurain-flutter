import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

/// Reads the device facts the diagnostics report header needs.
///
/// Only an explicit allowlist of fields leaves this class. The plugin also
/// exposes the name the user gave the device (`name`, e.g. "Jane's iPhone"),
/// a per-vendor device identifier (`identifierForVendor`), and build
/// fingerprints; none of those may reach a report.
class DeviceInfoService {
  DeviceInfoService({DeviceInfoPlugin? plugin})
    : _plugin = plugin ?? DeviceInfoPlugin();

  final DeviceInfoPlugin _plugin;

  /// The OS version and device model for the current platform, or an empty
  /// map on a platform the app does not ship on.
  Future<Map<String, Object?>> diagnosticsSummary() async {
    if (Platform.isAndroid) {
      return androidSummary(await _plugin.androidInfo);
    }
    if (Platform.isIOS) {
      return iosSummary(await _plugin.iosInfo);
    }
    return const {};
  }

  @visibleForTesting
  static Map<String, Object?> androidSummary(AndroidDeviceInfo info) => {
    'osVersion': 'Android ${info.version.release} (SDK ${info.version.sdkInt})',
    'manufacturer': info.manufacturer,
    'model': info.model,
    'physicalDevice': info.isPhysicalDevice,
    // Low-RAM devices are where the OS most often kills the app in the
    // background (e.g. during SSO in the browser).
    'lowRamDevice': info.isLowRamDevice,
  };

  @visibleForTesting
  static Map<String, Object?> iosSummary(IosDeviceInfo info) => {
    'osVersion': '${info.systemName} ${info.systemVersion}',
    // The hardware identifier (`iPhone15,2`), plus its marketing name.
    'model': info.utsname.machine,
    'modelName': info.modelName,
    'physicalDevice': info.isPhysicalDevice,
    if (info.isiOSAppOnMac) 'iosAppOnMac': true,
  };
}
