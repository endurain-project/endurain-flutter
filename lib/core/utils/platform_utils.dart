import 'dart:io';

import 'package:flutter/foundation.dart';

/// Platform utility functions
class PlatformUtils {
  @visibleForTesting
  static bool? debugIsApplePlatformOverride;

  @visibleForTesting
  static void debugResetOverrides() {
    debugIsApplePlatformOverride = null;
  }

  /// Check if the current platform is iOS or macOS
  static bool get isApplePlatform =>
      debugIsApplePlatformOverride ?? (Platform.isIOS || Platform.isMacOS);
}

/// Whether the app runs on Android or iOS, the platforms that host the native
/// recorder, sensor, health and watch integrations.
///
/// Reads [defaultTargetPlatform], so tests can steer it with
/// `debugDefaultTargetPlatformOverride`.
bool get isMobilePlatform =>
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS;
