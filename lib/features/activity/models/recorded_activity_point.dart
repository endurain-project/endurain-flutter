import 'dart:convert';

import 'package:endurain/core/utils/json_parsing.dart';
import 'package:endurain/features/activity/models/activity_track_point.dart';

/// A single location sample persisted to the durable active-recording store.
///
/// Unlike [ActivityTrackPoint], this model carries an explicit [segmentIndex]
/// so stored points preserve track breaks across pauses, gaps, and recorder
/// recovery boundaries even before they are loaded back into UI state.
class RecordedActivityPoint {
  const RecordedActivityPoint({
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.segmentIndex,
    this.elevationMeters,
    this.horizontalAccuracyMeters,
    this.verticalAccuracyMeters,
    this.headingDegrees,
    this.headingAccuracyDegrees,
    this.speedMetersPerSecond,
    this.speedAccuracyMetersPerSecond,
    this.heartRateBpm,
  });

  factory RecordedActivityPoint.fromTrackPoint(
    ActivityTrackPoint point, {
    required int segmentIndex,
  }) {
    return RecordedActivityPoint(
      timestamp: point.timestamp,
      latitude: point.latitude,
      longitude: point.longitude,
      segmentIndex: segmentIndex,
      elevationMeters: point.elevationMeters,
      horizontalAccuracyMeters: point.horizontalAccuracyMeters,
      verticalAccuracyMeters: point.verticalAccuracyMeters,
      headingDegrees: point.headingDegrees,
      headingAccuracyDegrees: point.headingAccuracyDegrees,
      speedMetersPerSecond: point.speedMetersPerSecond,
      speedAccuracyMetersPerSecond: point.speedAccuracyMetersPerSecond,
      heartRateBpm: point.heartRateBpm,
    );
  }

  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final int segmentIndex;
  final double? elevationMeters;
  final double? horizontalAccuracyMeters;
  final double? verticalAccuracyMeters;
  final double? headingDegrees;
  final double? headingAccuracyDegrees;
  final double? speedMetersPerSecond;
  final double? speedAccuracyMetersPerSecond;
  final int? heartRateBpm;

  ActivityTrackPoint toTrackPoint() {
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
    );
  }

  Map<String, Object?> toJson() {
    return {
      't': timestamp.toUtcIso8601(),
      'lat': latitude,
      'lon': longitude,
      'seg': segmentIndex,
      if (elevationMeters != null) 'ele': elevationMeters,
      if (horizontalAccuracyMeters != null) 'hAcc': horizontalAccuracyMeters,
      if (verticalAccuracyMeters != null) 'vAcc': verticalAccuracyMeters,
      if (headingDegrees != null) 'head': headingDegrees,
      if (headingAccuracyDegrees != null) 'headAcc': headingAccuracyDegrees,
      if (speedMetersPerSecond != null) 'spd': speedMetersPerSecond,
      if (speedAccuracyMetersPerSecond != null)
        'spdAcc': speedAccuracyMetersPerSecond,
      if (heartRateBpm != null) 'hr': heartRateBpm,
    };
  }

  /// Serializes the point to a single JSON line for append-only storage.
  String toJsonLine() => jsonEncode(toJson());

  factory RecordedActivityPoint.fromJson(Map<dynamic, dynamic> json) {
    final timestamp = jsonDateTime(json['t']);
    final latitude = jsonDouble(json['lat']);
    final longitude = jsonDouble(json['lon']);
    if (timestamp == null || latitude == null || longitude == null) {
      throw const FormatException('Invalid recorded activity point');
    }
    if (latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      throw const FormatException('Recorded activity point out of range');
    }

    return RecordedActivityPoint(
      timestamp: timestamp,
      latitude: latitude,
      longitude: longitude,
      segmentIndex: jsonInt(json['seg']) ?? 0,
      elevationMeters: jsonDouble(json['ele']),
      horizontalAccuracyMeters: jsonDouble(json['hAcc']),
      verticalAccuracyMeters: jsonDouble(json['vAcc']),
      headingDegrees: jsonDouble(json['head']),
      headingAccuracyDegrees: jsonDouble(json['headAcc']),
      speedMetersPerSecond: jsonDouble(json['spd']),
      speedAccuracyMetersPerSecond: jsonDouble(json['spdAcc']),
      heartRateBpm: jsonInt(json['hr']),
    );
  }

  /// Parses one stored JSONL line, returning `null` for blank or malformed
  /// lines so a single corrupt entry never aborts recovery of the rest.
  static RecordedActivityPoint? tryParseLine(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is! Map) {
        return null;
      }
      return RecordedActivityPoint.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }
}
