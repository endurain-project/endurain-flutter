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
  /// average the server derives from the uploaded GPX. `null` when the
  /// recording holds no consecutive point pair.
  final double? averageSpeedMetersPerSecond;

  final double? currentSpeedMetersPerSecond;

  /// Fastest speed derived from a position delta, or `null` when no pair of
  /// points exists. Surfaced in the post-recording summary.
  final double? maxSpeedMetersPerSecond;

  /// Total ascent within each segment, summed after the elevation series has
  /// been smoothed to reject altimeter noise. `null` when no point carried
  /// elevation.
  final double? elevationGainMeters;

  /// Most recent heart rate (bpm) stamped onto a track point, or `null` when no
  /// heart-rate source contributed to the recording. Surfaced live while
  /// recording.
  final int? currentHeartRateBpm;

  /// Mean heart rate (bpm) across every point that carried a non-zero reading,
  /// or `null` when none did. Surfaced in the post-recording summary.
  final int? averageHeartRateBpm;

  /// Most recent power (watts) stamped onto a track point, or `null` when no
  /// power source contributed to the recording. Surfaced live while recording.
  final int? currentPowerWatts;

  /// Mean power (watts) across every point that carried a non-zero reading, or
  /// `null` when none did. Surfaced in the post-recording summary.
  final int? averagePowerWatts;

  /// Most recent cadence (rpm) stamped onto a track point, or `null` when no
  /// cadence source contributed to the recording. Surfaced live while
  /// recording.
  final int? currentCadenceRpm;

  /// Mean cadence (rpm) across every point that carried a reading, or `null`
  /// when none did. Surfaced in the post-recording summary.
  final int? averageCadenceRpm;
}
