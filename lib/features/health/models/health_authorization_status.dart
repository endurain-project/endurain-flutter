/// Authorization status for health data access.
enum HealthAuthorizationStatus {
  /// Access to health data has been granted by the user.
  granted,

  /// Access to health data has been denied by the user or the OS.
  denied,

  /// The user has not yet been asked for health data access.
  notDetermined,
}
