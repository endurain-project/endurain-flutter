import Foundation

/// Configuration for `MovementAutoPauseDetector`.
///
/// Mirrors the Dart `MovementAutoPauseConfig`
/// (lib/features/activity/services/movement_auto_pause_detector.dart) and the
/// Android `MovementAutoPauseConfig`; keep all three implementations in sync.
/// Dart owns the canonical algorithm doc.
struct MovementAutoPauseConfig {
    var enabled: Bool = false
    var pauseDelayMillis: Int64 = 5_000
    var movingSpeedThresholdMetersPerSecond: Double = 0.6
    var maxAccuracyMeters: Double = 30.0
    var consecutiveMovingSamplesToResume: Int = 3
}

/// The result of feeding a sample into `MovementAutoPauseDetector`.
enum MovementAutoPauseTransition {
    /// No pause/resume boundary was crossed.
    case none

    /// Stillness has persisted long enough; the caller should auto-pause.
    case autoPause

    /// Enough consecutive movement was observed while auto-paused; the caller
    /// should auto-resume (starting a new track segment).
    case autoResume
}

/// A single location sample as seen by the detector.
///
/// Deliberately independent of `CLLocation` so this type (and
/// `MovementAutoPauseDetector`) stay plain, easily unit-testable Swift.
struct MovementSample {
    let timestampMillis: Int64
    let latitude: Double
    let longitude: Double
    let speedMetersPerSecond: Double?
    let horizontalAccuracyMeters: Double?
}

/// Detects when an active recording should auto-pause due to inactivity, and
/// when it should auto-resume once movement is observed again.
///
/// Mirrors `MovementAutoPauseDetector` in
/// lib/features/activity/services/movement_auto_pause_detector.dart (the Dart
/// geolocator fallback recorder implements the same algorithm) and the
/// Android `MovementAutoPauseDetector.kt`; keep all three in sync.
///
/// The detector combines two signals to decide whether a sample counts as
/// "moving": the fix's own reported speed (when its horizontal accuracy is
/// good), or otherwise the displacement-derived speed between this fix and the
/// last reliable fix (only when both fixes have good accuracy). A fix with poor
/// accuracy and no usable previous fix is never treated as movement, so noisy
/// fixes cannot mask genuine stillness.
final class MovementAutoPauseDetector {
    private let config: MovementAutoPauseConfig

    private var lastReliableSample: MovementSample?
    private var lastMovementAtMillis: Int64?
    private var consecutiveMovingSamples = 0

    init(config: MovementAutoPauseConfig) {
        self.config = config
    }

    /// Resets all tracked history. Call this whenever the recording (re)starts
    /// or transitions between manual and auto pause/resume, so stale movement
    /// history from before the reset can never trigger a spurious transition
    /// afterward.
    func reset(movementAtMillis: Int64? = nil) {
        lastReliableSample = nil
        lastMovementAtMillis = movementAtMillis
        consecutiveMovingSamples = 0
    }

    /// Feeds `sample` while the recording is actively collecting (not paused).
    /// Returns `.autoPause` once stillness has persisted for at least
    /// `config.pauseDelayMillis`. No-ops (always returns `.none`) when
    /// auto-pause is disabled.
    func onActivePoint(_ sample: MovementSample) -> MovementAutoPauseTransition {
        guard config.enabled else {
            return .none
        }
        let isMoving = isReliableMovement(sample)
        rememberIfReliable(sample)
        if isMoving {
            lastMovementAtMillis = sample.timestampMillis
            return .none
        }
        let since = lastMovementAtMillis ?? sample.timestampMillis
        lastMovementAtMillis = since
        let stillForMillis = sample.timestampMillis - since
        return stillForMillis >= config.pauseDelayMillis ? .autoPause : .none
    }

    /// Feeds `sample` while the recording is auto-paused (monitoring continues
    /// so movement can be detected without user interaction). Returns
    /// `.autoResume` once `config.consecutiveMovingSamplesToResume` consecutive
    /// reliable samples show movement.
    func onAutoPausedPoint(_ sample: MovementSample) -> MovementAutoPauseTransition {
        let isMoving = isReliableMovement(sample)
        rememberIfReliable(sample)
        consecutiveMovingSamples = isMoving ? consecutiveMovingSamples + 1 : 0
        if consecutiveMovingSamples >= config.consecutiveMovingSamplesToResume {
            consecutiveMovingSamples = 0
            lastMovementAtMillis = sample.timestampMillis
            return .autoResume
        }
        return .none
    }

    private func rememberIfReliable(_ sample: MovementSample) {
        if hasReliableAccuracy(sample) {
            lastReliableSample = sample
        }
    }

    private func hasReliableAccuracy(_ sample: MovementSample) -> Bool {
        guard let accuracy = sample.horizontalAccuracyMeters else {
            return true
        }
        return accuracy <= config.maxAccuracyMeters
    }

    private func isReliableMovement(_ sample: MovementSample) -> Bool {
        guard hasReliableAccuracy(sample) else {
            return false
        }
        if let reportedSpeed = sample.speedMetersPerSecond {
            return reportedSpeed >= config.movingSpeedThresholdMetersPerSecond
        }
        guard let previous = lastReliableSample else {
            return false
        }
        let seconds = Double(sample.timestampMillis - previous.timestampMillis) / 1000.0
        guard seconds > 0 else {
            return false
        }
        let meters = MovementAutoPauseDetector.haversineMeters(
            previous.latitude,
            previous.longitude,
            sample.latitude,
            sample.longitude
        )
        return (meters / seconds) >= config.movingSpeedThresholdMetersPerSecond
    }

    private static let earthRadiusMeters = 6_371_000.0

    /// Great-circle distance in meters between two coordinates.
    ///
    /// Kept dependency-free (no `CLLocation.distance(from:)`) so this class
    /// stays a plain, easily unit-testable Swift type.
    static func haversineMeters(_ lat1: Double, _ lon1: Double, _ lat2: Double, _ lon2: Double) -> Double {
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180
        let sinHalfLat = sin(dLat / 2)
        let sinHalfLon = sin(dLon / 2)
        let a = sinHalfLat * sinHalfLat
            + cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) * sinHalfLon * sinHalfLon
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return earthRadiusMeters * c
    }
}
