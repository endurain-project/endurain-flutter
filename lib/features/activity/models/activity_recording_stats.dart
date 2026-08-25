class ActivityRecordingStats {
  const ActivityRecordingStats({
    required this.distanceMeters,
    required this.durationSeconds,
    this.averageSpeedMetersPerSecond,
    this.currentSpeedMetersPerSecond,
    this.maxSpeedMetersPerSecond,
    this.elevationGainMeters,
    this.currentHeartRateBpm,
    this.averageHeartRateBpm,
    this.currentPowerWatts,
    this.averagePowerWatts,
    this.currentCadenceRpm,
    this.averageCadenceRpm,
  });

  final double distanceMeters;
  final int durationSeconds;

  /// Mean of the per-point speeds derived from position deltas, matching the
  /// average the server derives from the uploaded GPX. The first point in each
  /// segment contributes zero. `null` when the recording holds no points.
  final double? averageSpeedMetersPerSecond;

  final double? currentSpeedMetersPerSecond;

  /// Fastest speed derived from a position delta, or `null` when no point
  /// exists. Surfaced in the post-recording summary.
  final double? maxSpeedMetersPerSecond;

  /// Total ascent after the full GPX elevation stream has been smoothed to
  /// reject altimeter noise. `null` when no point carried valid elevation.
  final double? elevationGainMeters;

  /// Most recent heart rate (bpm) stamped onto a track point, or `null` when no
  /// heart-rate source contributed to the recording. Surfaced live while
  /// recording.
  final int? currentHeartRateBpm;

  /// Backend-rounded mean heart rate (bpm) across every point that carried a
  /// non-zero reading, or `null` when none did. Surfaced in the post-recording
  /// summary.
  final int? averageHeartRateBpm;

  /// Most recent power (watts) stamped onto a track point, or `null` when no
  /// power source contributed to the recording. Surfaced live while recording.
  final int? currentPowerWatts;

  /// Backend-rounded mean power (watts) across every point that carried a
  /// non-zero reading, or `null` when none did. Surfaced in the post-recording
  /// summary.
  final int? averagePowerWatts;

  /// Most recent cadence (rpm) stamped onto a track point, or `null` when no
  /// cadence source contributed to the recording. Surfaced live while
  /// recording.
  final int? currentCadenceRpm;

  /// Backend-rounded mean cadence (rpm) across the zero-filled GPX point
  /// stream, or `null` when no non-zero cadence exists. Surfaced in the
  /// post-recording summary.
  final int? averageCadenceRpm;
}
