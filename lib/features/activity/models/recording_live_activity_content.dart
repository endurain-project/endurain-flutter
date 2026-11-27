/// What the Lock Screen and Dynamic Island show for a recording, localized
/// and formatted exactly as the recording screen shows it.
///
/// The elapsed time and the paused state are not part of it: the native
/// recorder owns them, so they stay right while Flutter is not running.
class RecordingLiveActivityContent {
  const RecordingLiveActivityContent({
    required this.localSessionId,
    required this.title,
    required this.distanceLabel,
    required this.distanceValue,
    required this.speedLabel,
    required this.speedValue,
    required this.pausedLabel,
  });

  /// The recording the content belongs to.
  final String localSessionId;

  /// The activity type's name.
  final String title;
  final String distanceLabel;
  final String distanceValue;

  /// Pace for a run, speed for any other activity, as on the recording
  /// screen.
  final String speedLabel;
  final String speedValue;

  /// Shown next to the title while the recording is paused.
  final String pausedLabel;

  /// The `updateLiveActivity` method-channel arguments, without the payload
  /// version.
  Map<String, Object> toChannelMap() => {
    'localSessionId': localSessionId,
    'title': title,
    'distanceLabel': distanceLabel,
    'distanceValue': distanceValue,
    'speedLabel': speedLabel,
    'speedValue': speedValue,
    'pausedLabel': pausedLabel,
  };

  @override
  bool operator ==(Object other) =>
      other is RecordingLiveActivityContent &&
      other.localSessionId == localSessionId &&
      other.title == title &&
      other.distanceLabel == distanceLabel &&
      other.distanceValue == distanceValue &&
      other.speedLabel == speedLabel &&
      other.speedValue == speedValue &&
      other.pausedLabel == pausedLabel;

  @override
  int get hashCode => Object.hash(
    localSessionId,
    title,
    distanceLabel,
    distanceValue,
    speedLabel,
    speedValue,
    pausedLabel,
  );
}
