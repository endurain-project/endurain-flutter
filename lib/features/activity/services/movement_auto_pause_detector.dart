import 'package:endurain/features/activity/models/recorded_activity_point.dart';
import 'package:endurain/features/activity/services/geo_distance.dart';

/// Configuration for [MovementAutoPauseDetector].
///
/// A snapshot of these values is persisted onto the active session (see
/// `ActiveActivitySession.autoPauseEnabled`/`autoPauseDelaySeconds`) so a
/// recovered recording keeps behaving the way it did when it started, even if
/// the user changes the app preference mid-recording.
class MovementAutoPauseConfig {
  const MovementAutoPauseConfig({
    this.enabled = false,
    this.pauseDelay = const Duration(seconds: 5),
    this.movingSpeedThresholdMetersPerSecond = 0.6,
    this.maxAccuracyMeters = 30,
    this.consecutiveMovingSamplesToResume = 3,
  }) : assert(consecutiveMovingSamplesToResume > 0);

  /// Whether auto-pause is active for this recording.
  final bool enabled;

  /// How long movement must be absent before the recording auto-pauses.
  final Duration pauseDelay;

  /// Speed at or above which a sample counts as "moving" (m/s). The default
  /// (~2.2 km/h) is comfortably below a walking pace while still filtering
  /// GPS jitter recorded while stationary.
  final double movingSpeedThresholdMetersPerSecond;

  /// Horizontal accuracy worse than this (in meters) is treated as
  /// unreliable and never counted as movement. This is intentionally stricter
  /// than the track-retention threshold so coarse fixes cannot drive automatic
  /// pause or resume transitions.
  final double maxAccuracyMeters;

  /// Number of consecutive reliable "moving" samples required to auto-resume,
  /// providing hysteresis so a single noisy fix cannot resume prematurely.
  final int consecutiveMovingSamplesToResume;
}

/// The result of feeding a point into [MovementAutoPauseDetector].
enum MovementAutoPauseTransition {
  /// No pause/resume boundary was crossed.
  none,

  /// Stillness has persisted for at least the configured delay; the caller
  /// should transition the recording to auto-paused.
  autoPause,

  /// Enough consecutive movement has been observed while auto-paused; the
  /// caller should resume the recording (starting a new track segment).
  autoResume,
}

/// Detects when an active recording should auto-pause due to inactivity, and
/// when it should auto-resume once movement is observed again.
///
/// This is pure logic with no platform dependency, shared by the Dart
/// geolocator fallback recorder; the native Android/iOS recorders implement
/// the same algorithm directly (see `MovementAutoPauseDetector.kt` and
/// `MovementAutoPauseDetector.swift`) since they cannot depend on Dart code.
///
/// The detector combines two signals to decide whether a sample counts as
/// "moving", per the task's "reliable speed and accuracy-filtered
/// displacement" requirement:
///  1. The fix's own reported speed, when its horizontal accuracy is good.
///  2. Otherwise, the displacement-derived speed between this fix and the
///     last reliable fix, only when both fixes have good accuracy.
/// A fix with poor accuracy and no usable previous fix is never treated as
/// movement, so noisy fixes cannot mask genuine stillness.
class MovementAutoPauseDetector {
  MovementAutoPauseDetector({required this.config});

  final MovementAutoPauseConfig config;

  RecordedActivityPoint? _lastReliablePoint;
  DateTime? _lastMovementAt;
  int _consecutiveMovingSamples = 0;

  /// Resets all tracked history.
  ///
  /// Call this whenever the recording (re)starts or transitions between
  /// manual and auto pause/resume, so stale movement history from before the
  /// reset can never trigger a spurious transition afterward.
  void reset({DateTime? movementAt}) {
    _lastReliablePoint = null;
    _lastMovementAt = movementAt;
    _consecutiveMovingSamples = 0;
  }

  /// Feeds [point] while the recording is actively collecting (not paused).
  ///
  /// Returns [MovementAutoPauseTransition.autoPause] once stillness has
  /// persisted for at least [MovementAutoPauseConfig.pauseDelay]; otherwise
  /// [MovementAutoPauseTransition.none]. No-ops (always returns `none`) when
  /// auto-pause is disabled.
  MovementAutoPauseTransition onActivePoint(RecordedActivityPoint point) {
    if (!config.enabled) {
      return MovementAutoPauseTransition.none;
    }
    final isMoving = _isReliableMovement(point);
    _rememberIfReliable(point);
    if (isMoving) {
      _lastMovementAt = point.timestamp;
      return MovementAutoPauseTransition.none;
    }
    // `??=` on a nullable field has a nullable static type even after the
    // assignment, so read back through `!` rather than binding its result.
    _lastMovementAt ??= point.timestamp;
    final stillFor = point.timestamp.difference(_lastMovementAt!);
    if (stillFor >= config.pauseDelay) {
      return MovementAutoPauseTransition.autoPause;
    }
    return MovementAutoPauseTransition.none;
  }

  /// Feeds [point] while the recording is auto-paused (monitoring continues
  /// so movement can be detected without user interaction).
  ///
  /// Returns [MovementAutoPauseTransition.autoResume] once
  /// [MovementAutoPauseConfig.consecutiveMovingSamplesToResume] consecutive
  /// reliable samples show movement; otherwise
  /// [MovementAutoPauseTransition.none].
  MovementAutoPauseTransition onAutoPausedPoint(RecordedActivityPoint point) {
    final isMoving = _isReliableMovement(point);
    _rememberIfReliable(point);
    _consecutiveMovingSamples = isMoving ? _consecutiveMovingSamples + 1 : 0;
    if (_consecutiveMovingSamples >= config.consecutiveMovingSamplesToResume) {
      _consecutiveMovingSamples = 0;
      _lastMovementAt = point.timestamp;
      return MovementAutoPauseTransition.autoResume;
    }
    return MovementAutoPauseTransition.none;
  }

  void _rememberIfReliable(RecordedActivityPoint point) {
    if (_hasReliableAccuracy(point)) {
      _lastReliablePoint = point;
    }
  }

  bool _hasReliableAccuracy(RecordedActivityPoint point) {
    final accuracy = point.horizontalAccuracyMeters;
    return accuracy == null || accuracy <= config.maxAccuracyMeters;
  }

  bool _isReliableMovement(RecordedActivityPoint point) {
    if (!_hasReliableAccuracy(point)) {
      return false;
    }
    final reportedSpeed = point.speedMetersPerSecond;
    if (reportedSpeed != null) {
      return reportedSpeed >= config.movingSpeedThresholdMetersPerSecond;
    }
    final previous = _lastReliablePoint;
    if (previous == null || identical(previous, point)) {
      return false;
    }
    final seconds =
        point.timestamp.difference(previous.timestamp).inMicroseconds /
        Duration.microsecondsPerSecond;
    if (seconds <= 0) {
      return false;
    }
    final meters = geoDistanceMeters(
      previous.latitude,
      previous.longitude,
      point.latitude,
      point.longitude,
    );
    return (meters / seconds) >= config.movingSpeedThresholdMetersPerSecond;
  }
}
