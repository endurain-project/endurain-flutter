import 'package:endurain/features/activity/models/recorded_sensor_sample.dart';
import 'package:geolocator/geolocator.dart';

class ActivityTrackPoint {
  const ActivityTrackPoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.elevationMeters,
    this.speedMetersPerSecond,
    this.headingDegrees,
    this.horizontalAccuracyMeters,
    this.verticalAccuracyMeters,
    this.speedAccuracyMetersPerSecond,
    this.headingAccuracyDegrees,
    this.heartRateBpm,
    this.powerWatts,
    this.cadenceRpm,
  }) : assert(latitude >= -90 && latitude <= 90),
       assert(longitude >= -180 && longitude <= 180);

  factory ActivityTrackPoint.fromPosition(Position position) {
    return ActivityTrackPoint(
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: position.timestamp,
      elevationMeters: _finiteOrNull(position.altitude),
      speedMetersPerSecond: _nonNegativeOrNull(position.speed),
      headingDegrees: _headingOrNull(position.heading),
      horizontalAccuracyMeters: _nonNegativeOrNull(position.accuracy),
      verticalAccuracyMeters: _nonNegativeOrNull(position.altitudeAccuracy),
      speedAccuracyMetersPerSecond: _nonNegativeOrNull(position.speedAccuracy),
      headingAccuracyDegrees: _nonNegativeOrNull(position.headingAccuracy),
    );
  }

  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? elevationMeters;
  final double? speedMetersPerSecond;
  final double? headingDegrees;
  final double? horizontalAccuracyMeters;
  final double? verticalAccuracyMeters;
  final double? speedAccuracyMetersPerSecond;
  final double? headingAccuracyDegrees;

  /// Heart rate in beats per minute from a paired external sensor, when one is
  /// connected. `null` when no heart-rate source contributed to this point.
  final int? heartRateBpm;

  /// Mechanical power in watts from a paired external power meter, when one is
  /// connected. `null` when no power source contributed to this point.
  final int? powerWatts;

  /// Cadence in revolutions per minute (cycling) or steps per minute (running)
  /// from a paired external sensor. `null` when no cadence source contributed
  /// to this point.
  final int? cadenceRpm;

  /// Returns a copy of this point with [heartRateBpm] set to [bpm].
  ActivityTrackPoint withHeartRateBpm(int bpm) {
    return ActivityTrackPoint(
      latitude: latitude,
      longitude: longitude,
      timestamp: timestamp,
      elevationMeters: elevationMeters,
      speedMetersPerSecond: speedMetersPerSecond,
      headingDegrees: headingDegrees,
      horizontalAccuracyMeters: horizontalAccuracyMeters,
      verticalAccuracyMeters: verticalAccuracyMeters,
      speedAccuracyMetersPerSecond: speedAccuracyMetersPerSecond,
      headingAccuracyDegrees: headingAccuracyDegrees,
      heartRateBpm: bpm,
      powerWatts: powerWatts,
      cadenceRpm: cadenceRpm,
    );
  }

  /// Returns a copy of this point with [powerWatts] set to [watts].
  ActivityTrackPoint withPowerWatts(int watts) {
    return ActivityTrackPoint(
      latitude: latitude,
      longitude: longitude,
      timestamp: timestamp,
      elevationMeters: elevationMeters,
      speedMetersPerSecond: speedMetersPerSecond,
      headingDegrees: headingDegrees,
      horizontalAccuracyMeters: horizontalAccuracyMeters,
      verticalAccuracyMeters: verticalAccuracyMeters,
      speedAccuracyMetersPerSecond: speedAccuracyMetersPerSecond,
      headingAccuracyDegrees: headingAccuracyDegrees,
      heartRateBpm: heartRateBpm,
      powerWatts: watts,
      cadenceRpm: cadenceRpm,
    );
  }

  /// Returns a copy of this point with [cadenceRpm] set to [rpm].
  ActivityTrackPoint withCadenceRpm(int rpm) {
    return ActivityTrackPoint(
      latitude: latitude,
      longitude: longitude,
      timestamp: timestamp,
      elevationMeters: elevationMeters,
      speedMetersPerSecond: speedMetersPerSecond,
      headingDegrees: headingDegrees,
      horizontalAccuracyMeters: horizontalAccuracyMeters,
      verticalAccuracyMeters: verticalAccuracyMeters,
      speedAccuracyMetersPerSecond: speedAccuracyMetersPerSecond,
      headingAccuracyDegrees: headingAccuracyDegrees,
      heartRateBpm: heartRateBpm,
      powerWatts: powerWatts,
      cadenceRpm: rpm,
    );
  }

  /// Returns a copy of this point with the value for [kind] set to [value].
  ActivityTrackPoint withSensorValue(RecordedSensorKind kind, int value) {
    return switch (kind) {
      RecordedSensorKind.heartRate => withHeartRateBpm(value),
      RecordedSensorKind.power => withPowerWatts(value),
      RecordedSensorKind.cadence => withCadenceRpm(value),
    };
  }

  static double? _finiteOrNull(double value) {
    return value.isFinite ? value : null;
  }

  static double? _nonNegativeOrNull(double value) {
    return value.isFinite && !value.isNegative ? value : null;
  }

  static double? _headingOrNull(double value) {
    if (!value.isFinite || value.isNegative) {
      return null;
    }
    return value.remainder(360);
  }
}
