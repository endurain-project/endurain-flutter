import 'dart:math' as math;

import 'package:endurain/features/activity/models/recorded_activity_point.dart';

/// Why the segment policy decided a new track segment is required.
enum ActivitySegmentBreakReason {
  none,
  pauseResume,
  recoveryBoundary,
  timeGap,
  impossibleSpeed,
  poorAccuracy,
}

/// The typed result of evaluating whether a new track segment should start.
class ActivitySegmentDecision {
  const ActivitySegmentDecision({
    required this.requiresNewSegment,
    required this.reason,
  });

  static const ActivitySegmentDecision none = ActivitySegmentDecision(
    requiresNewSegment: false,
    reason: ActivitySegmentBreakReason.none,
  );

  final bool requiresNewSegment;
  final ActivitySegmentBreakReason reason;
}

/// Decides when an unavoidable gap in collected points should be modeled as a
/// new track segment rather than connected with a misleading straight line.
///
/// The policy only returns a typed decision; callers own segment state.
class ActivitySegmentPolicy {
  const ActivitySegmentPolicy({
    this.maxTimeGap = const Duration(seconds: 30),
    this.maxSpeedMetersPerSecond = 90,
    this.maxAccuracyMeters = 100,
  });

  /// Maximum time between consecutive points before a gap is assumed.
  final Duration maxTimeGap;

  /// Speed above which movement between two points is considered impossible
  /// (default ~324 km/h), implying missing data rather than continuous travel.
  final double maxSpeedMetersPerSecond;

  /// Horizontal accuracy worse than this (in meters) is treated as unreliable.
  final double maxAccuracyMeters;

  ActivitySegmentDecision evaluate({
    RecordedActivityPoint? previous,
    required RecordedActivityPoint next,
    bool resumedFromPause = false,
    bool recoveredFromBoundary = false,
  }) {
    if (resumedFromPause) {
      return const ActivitySegmentDecision(
        requiresNewSegment: true,
        reason: ActivitySegmentBreakReason.pauseResume,
      );
    }
    if (recoveredFromBoundary) {
      return const ActivitySegmentDecision(
        requiresNewSegment: true,
        reason: ActivitySegmentBreakReason.recoveryBoundary,
      );
    }
    if (previous == null) {
      return ActivitySegmentDecision.none;
    }

    final elapsed = next.timestamp.difference(previous.timestamp);
    if (elapsed > maxTimeGap) {
      return const ActivitySegmentDecision(
        requiresNewSegment: true,
        reason: ActivitySegmentBreakReason.timeGap,
      );
    }

    final seconds = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    if (seconds > 0) {
      final meters = _distanceMeters(previous, next);
      if (meters / seconds > maxSpeedMetersPerSecond) {
        return const ActivitySegmentDecision(
          requiresNewSegment: true,
          reason: ActivitySegmentBreakReason.impossibleSpeed,
        );
      }
    }

    final accuracy = next.horizontalAccuracyMeters;
    if (accuracy != null && accuracy > maxAccuracyMeters) {
      return const ActivitySegmentDecision(
        requiresNewSegment: true,
        reason: ActivitySegmentBreakReason.poorAccuracy,
      );
    }

    return ActivitySegmentDecision.none;
  }

  static double _distanceMeters(
    RecordedActivityPoint a,
    RecordedActivityPoint b,
  ) {
    const earthRadiusMeters = 6371000.0;
    final lat1 = _toRadians(a.latitude);
    final lat2 = _toRadians(b.latitude);
    final dLat = _toRadians(b.latitude - a.latitude);
    final dLon = _toRadians(b.longitude - a.longitude);
    final h =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
    return earthRadiusMeters * c;
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180;
}
