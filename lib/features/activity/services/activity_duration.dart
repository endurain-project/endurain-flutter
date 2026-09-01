/// The duration reported for a finished recording, in seconds.
///
/// Normally this is [elapsedDurationSeconds]: wall-clock time spent recording,
/// with paused stretches excluded. The GPS point span ([statsDurationSeconds])
/// wins when it is longer, which happens for a session recovered after the app
/// was killed, where persisted points outlived the timer state.
///
/// Every surface that shows a finished activity's duration resolves it here so
/// the completion summary, history list, and details screen cannot disagree.
int reportedActivityDurationSeconds({
  required int statsDurationSeconds,
  required int elapsedDurationSeconds,
}) {
  final elapsed = elapsedDurationSeconds < 0 ? 0 : elapsedDurationSeconds;
  final stats = statsDurationSeconds < 0 ? 0 : statsDurationSeconds;
  return stats > elapsed ? stats : elapsed;
}
