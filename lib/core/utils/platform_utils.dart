import 'dart:io';

/// Platform utility functions
class PlatformUtils {
  /// Check if the current platform is iOS or macOS
  static bool get isApplePlatform => Platform.isIOS || Platform.isMacOS;

  /// Check if the current platform is mobile (iOS or Android)
  static bool get isMobile => Platform.isIOS || Platform.isAndroid;
}
