/// Runtime availability of the health platform on the current device.
enum HealthSdkStatus {
  /// Health platform is available and ready to use.
  available,

  /// Health Connect is not installed (Android < 14).
  ///
  /// The user should be prompted to install it from the Play Store via
  /// `installHealthConnect()`.
  needsProviderInstall,

  /// Health sync is not supported on this platform or OS version.
  ///
  /// The feature degrades gracefully: GPS recording and manual upload still
  /// work; health-related UI elements are hidden or show an explanation.
  unsupported,
}
