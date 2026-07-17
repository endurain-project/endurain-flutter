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
  });

  final double distanceMeters;
  final int durationSeconds;
  final double? averageSpeedMetersPerSecond;
  final double? currentSpeedMetersPerSecond;

  /// Fastest instantaneous speed observed across the recording, or `null` when
  /// no moving speed could be derived. Surfaced in the post-recording summary.
  final double? maxSpeedMetersPerSecond;

  /// Total ascent: the sum of positive elevation deltas between consecutive
  /// points within each segment. `null` when no point carried elevation.
  final double? elevationGainMeters;

  /// Most recent heart rate (bpm) stamped onto a track point, or `null` when no
  /// heart-rate source contributed to the recording. Surfaced live while
  /// recording.
  final int? currentHeartRateBpm;

  /// Mean heart rate (bpm) across every point that carried a reading, or `null`
  /// when none did. Surfaced in the post-recording summary.
  final int? averageHeartRateBpm;
}
