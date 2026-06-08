import 'dart:convert';

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
    );
  }

  Map<String, Object?> toJson() {
    return {
      't': timestamp.toUtc().toIso8601String(),
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
    };
  }

  /// Serializes the point to a single JSON line for append-only storage.
  String toJsonLine() => jsonEncode(toJson());

  factory RecordedActivityPoint.fromJson(Map<dynamic, dynamic> json) {
    final timestamp = _dateTime(json['t']);
    final latitude = _double(json['lat']);
    final longitude = _double(json['lon']);
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
      segmentIndex: _int(json['seg']) ?? 0,
      elevationMeters: _double(json['ele']),
      horizontalAccuracyMeters: _double(json['hAcc']),
      verticalAccuracyMeters: _double(json['vAcc']),
      headingDegrees: _double(json['head']),
      headingAccuracyDegrees: _double(json['headAcc']),
      speedMetersPerSecond: _double(json['spd']),
      speedAccuracyMetersPerSecond: _double(json['spdAcc']),
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

double? _double(Object? value) {
  if (value is num) {
    final result = value.toDouble();
    return result.isFinite ? result : null;
  }
  return null;
}

int? _int(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return null;
}

DateTime? _dateTime(Object? value) {
  if (value is! String) {
    return null;
  }
  return DateTime.tryParse(value)?.toUtc();
}
