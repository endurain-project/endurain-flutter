class ActivityRecordingStats {
  const ActivityRecordingStats({
    required this.distanceMeters,
    required this.durationSeconds,
    this.averageSpeedMetersPerSecond,
    this.currentSpeedMetersPerSecond,
    this.maxSpeedMetersPerSecond,
    this.elevationGainMeters,
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
}
