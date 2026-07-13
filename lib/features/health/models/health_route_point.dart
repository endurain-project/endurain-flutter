/// A single GPS route point from a health platform workout.
///
/// Immutable snapshot of a recorded location sample with optional elevation
/// and heart-rate data.
class HealthRoutePoint {
  const HealthRoutePoint({
    required this.latitude,
    required this.longitude,
    required this.time,
    this.elevation,
    this.heartRate,
  });

  /// WGS-84 latitude in decimal degrees.
  final double latitude;

  /// WGS-84 longitude in decimal degrees.
  final double longitude;

  /// UTC timestamp of this sample.
  final DateTime time;

  /// Elevation above sea level in metres, if available.
  final double? elevation;

  /// Heart rate in beats per minute at this sample, if available.
  final int? heartRate;
}
