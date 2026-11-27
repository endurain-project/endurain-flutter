import 'package:flutter/foundation.dart';

/// Configuration for the movement auto-pause algorithm.
///
/// The algorithm itself runs natively (`MovementAutoPauseDetector.kt` and
/// `MovementAutoPauseDetector.swift`); a Dart reference implementation lives in
/// `test/helpers/movement_auto_pause_detector.dart`, and all three run the
/// shared vectors in `test/fixtures/movement_auto_pause_vectors.json`.
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
  @visibleForTesting
  final double movingSpeedThresholdMetersPerSecond;

  /// Horizontal accuracy worse than this (in meters) is treated as
  /// unreliable and never counted as movement. This is intentionally stricter
  /// than the track-retention threshold so coarse fixes cannot drive automatic
  /// pause or resume transitions.
  @visibleForTesting
  final double maxAccuracyMeters;

  /// Number of consecutive reliable "moving" samples required to auto-resume,
  /// providing hysteresis so a single noisy fix cannot resume prematurely.
  @visibleForTesting
  final int consecutiveMovingSamplesToResume;
}
