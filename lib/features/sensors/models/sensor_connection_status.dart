/// Lifecycle of the app's connection to a single external sensor.
///
/// The UI layer maps these to localized status text; the sensor layer never
/// emits user-facing strings.
enum SensorConnectionStatus {
  /// No sensor connected and no attempt in progress.
  disconnected,

  /// A connection attempt to a chosen device is underway.
  connecting,

  /// Connected and receiving measurements.
  connected,

  /// The link dropped and the sensor layer is attempting to restore it.
  reconnecting,

  /// The last connection attempt failed.
  failed,
}
