import 'package:endurain/core/services/platform/location_platform_adapter.dart';
import 'package:flutter/services.dart';

/// Opens the Health Connect permission screen for this app (Android only).
///
/// Health Connect stops showing its permission dialog after two denials, and
/// the `health` package has no API to reach the screen where access can still
/// be granted, so a thin native channel does it.
abstract interface class HealthConnectSettingsService {
  /// Opens the screen where the user can allow Endurain's Health Connect
  /// access. Resolves to whether a settings screen was launched; never throws.
  Future<bool> openPermissions();
}

/// Platform-channel implementation used by the application composition root.
///
/// Falls back to the app's system settings when the channel is missing, fails,
/// or reports that no Health Connect screen could be launched, so the user is
/// never left without a way forward.
class PlatformHealthConnectSettingsService
    implements HealthConnectSettingsService {
  const PlatformHealthConnectSettingsService({
    MethodChannel channel = const MethodChannel(_channelName),
    Future<bool> Function() openAppSettings = _defaultOpenAppSettings,
  }) : _channel = channel,
       _openAppSettings = openAppSettings;

  static const String _channelName = 'endurain/health_connect_settings';
  static const String _openPermissions = 'openPermissions';

  final MethodChannel _channel;
  final Future<bool> Function() _openAppSettings;

  static Future<bool> _defaultOpenAppSettings() =>
      const GeolocatorLocationPlatformAdapter().openAppSettings();

  @override
  Future<bool> openPermissions() async {
    try {
      final launched = await _channel.invokeMethod<bool>(_openPermissions);
      if (launched ?? false) {
        return true;
      }
    } on MissingPluginException {
      // Fall through to the app settings.
    } on PlatformException {
      // Fall through to the app settings.
    }
    try {
      return await _openAppSettings();
    } catch (_) {
      return false;
    }
  }
}
