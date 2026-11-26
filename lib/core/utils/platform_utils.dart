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
