import XCTest

@testable import Runner

/// Unit tests for `MovementAutoPauseDetector`.
///
/// Mirrors the Dart test suite for
/// `lib/features/activity/services/movement_auto_pause_detector.dart` and the
/// Android `MovementAutoPauseDetectorTest`. A regression here would either
/// fail to auto-pause a stopped recording or (worse) auto-resume when it
/// should not, so every branch of the reliable-movement heuristic and the
/// pause/resume hysteresis is locked down.
final class MovementAutoPauseDetectorTests: XCTestCase {
  private let baseMillis: Int64 = 1_700_000_000_000

  private func sample(
    _ second: Int,
    lat: Double = 38.7,
    lon: Double = -9.1,
    speed: Double? = nil,
    accuracy: Double? = 5.0
  ) -> MovementSample {
    return MovementSample(
      timestampMillis: baseMillis + Int64(second) * 1000,
      latitude: lat,
      longitude: lon,
      speedMetersPerSecond: speed,
      horizontalAccuracyMeters: accuracy
    )
  }

  // MARK: - onActivePoint: auto-pause

  func testDisabledConfigNeverAutoPauses() {
    let detector = MovementAutoPauseDetector(
      config: MovementAutoPauseConfig(enabled: false, pauseDelayMillis: 1_000))
    detector.reset(movementAtMillis: baseMillis)

    for second in 0...10 {
      let transition = detector.onActivePoint(sample(second, speed: 0.0))
      guard case .none = transition else {
        return XCTFail("expected .none, got \(transition)")
      }
    }
  }

  func testAutoPausesAfterStillnessPersistsForTheConfiguredDelay() {
    let detector = MovementAutoPauseDetector(
      config: MovementAutoPauseConfig(enabled: true, pauseDelayMillis: 5_000))
    detector.reset(movementAtMillis: baseMillis)

    guard case .none = detector.onActivePoint(sample(1, speed: 0.0)) else {
      return XCTFail("expected .none")
    }
    guard case .none = detector.onActivePoint(sample(4, speed: 0.0)) else {
      return XCTFail("expected .none")
    }
    guard case .autoPause = detector.onActivePoint(sample(5, speed: 0.0)) else {
      return XCTFail("expected .autoPause")
    }
  }

  func testReportedSpeedAboveThresholdResetsTheStillnessTimer() {
    let detector = MovementAutoPauseDetector(
      config: MovementAutoPauseConfig(enabled: true, pauseDelayMillis: 5_000))
    detector.reset(movementAtMillis: baseMillis)

    _ = detector.onActivePoint(sample(3, speed: 0.0))
    _ = detector.onActivePoint(sample(4, speed: 2.0))
    guard case .none = detector.onActivePoint(sample(8, speed: 0.0)) else {
      return XCTFail("expected .none")
    }
    guard case .autoPause = detector.onActivePoint(sample(9, speed: 0.0)) else {
      return XCTFail("expected .autoPause")
    }
  }

  func testUnreliableAccuracyIsNeverCountedAsMovement() {
    let detector = MovementAutoPauseDetector(
      config: MovementAutoPauseConfig(
        enabled: true, pauseDelayMillis: 5_000, maxAccuracyMeters: 30.0))
    detector.reset(movementAtMillis: baseMillis)

    // A fast-looking but inaccurate fix must not reset the stillness timer.
    _ = detector.onActivePoint(sample(1, speed: 10.0, accuracy: 500.0))
    guard case .autoPause = detector.onActivePoint(sample(5, speed: 0.0)) else {
      return XCTFail("expected .autoPause")
    }
  }

  func testDisplacementDerivedSpeedIsUsedWhenReportedSpeedIsAbsent() {
    let detector = MovementAutoPauseDetector(
      config: MovementAutoPauseConfig(
        enabled: true, pauseDelayMillis: 5_000,
        movingSpeedThresholdMetersPerSecond: 0.6))
    detector.reset(movementAtMillis: baseMillis)

    // ~0.0009 degrees of latitude is roughly 100 meters; moving that far in
    // one second is far above the 0.6 m/s threshold, so the timer resets.
    _ = detector.onActivePoint(sample(0, lat: 38.7, speed: nil))
    guard
      case .none = detector.onActivePoint(sample(1, lat: 38.7009, speed: nil))
    else {
      return XCTFail("expected .none")
    }
    // Two stationary (displacement ~0) fixes after that should reach the
    // configured delay and auto-pause.
    _ = detector.onActivePoint(sample(2, lat: 38.7009, speed: nil))
    guard
      case .autoPause = detector.onActivePoint(sample(6, lat: 38.7009, speed: nil))
    else {
      return XCTFail("expected .autoPause")
    }
  }

  // MARK: - onAutoPausedPoint: auto-resume

  func testAutoResumesOnlyAfterEnoughConsecutiveMovingSamples() {
    let detector = MovementAutoPauseDetector(
      config: MovementAutoPauseConfig(
        enabled: true, consecutiveMovingSamplesToResume: 3))
    detector.reset(movementAtMillis: baseMillis)

    guard case .none = detector.onAutoPausedPoint(sample(1, speed: 2.0)) else {
      return XCTFail("expected .none")
    }
    guard case .none = detector.onAutoPausedPoint(sample(2, speed: 2.0)) else {
      return XCTFail("expected .none")
    }
    guard case .autoResume = detector.onAutoPausedPoint(sample(3, speed: 2.0))
    else {
      return XCTFail("expected .autoResume")
    }
  }

  func testASingleStillSampleResetsTheConsecutiveMovingCounter() {
    let detector = MovementAutoPauseDetector(
      config: MovementAutoPauseConfig(
        enabled: true, consecutiveMovingSamplesToResume: 3))
    detector.reset(movementAtMillis: baseMillis)

    _ = detector.onAutoPausedPoint(sample(1, speed: 2.0))
    _ = detector.onAutoPausedPoint(sample(2, speed: 2.0))
    // Movement noise briefly drops out; hysteresis must not resume yet.
    _ = detector.onAutoPausedPoint(sample(3, speed: 0.0))
    guard case .none = detector.onAutoPausedPoint(sample(4, speed: 2.0)) else {
      return XCTFail("expected .none")
    }
    guard case .none = detector.onAutoPausedPoint(sample(5, speed: 2.0)) else {
      return XCTFail("expected .none")
    }
    guard case .autoResume = detector.onAutoPausedPoint(sample(6, speed: 2.0))
    else {
      return XCTFail("expected .autoResume")
    }
  }

  func testResetClearsStillnessAndConsecutiveMovementHistory() {
    let detector = MovementAutoPauseDetector(
      config: MovementAutoPauseConfig(enabled: true, pauseDelayMillis: 1_000))
    detector.reset(movementAtMillis: baseMillis)
    _ = detector.onActivePoint(sample(5, speed: 0.0))

    // A manual pause/resume resets tracking; the next active point must not
    // immediately auto-pause using stale history.
    detector.reset(movementAtMillis: baseMillis + 100_000)
    guard case .none = detector.onActivePoint(sample(100, speed: 0.0)) else {
      return XCTFail("expected .none")
    }
  }

  // MARK: - haversineMeters

  func testHaversineMetersIsZeroForIdenticalCoordinates() {
    let meters = MovementAutoPauseDetector.haversineMeters(38.7, -9.1, 38.7, -9.1)
    XCTAssertEqual(meters, 0.0, accuracy: 0.0001)
  }

  func testHaversineMetersApproximatesKnownShortDistance() {
    // One arc-minute of latitude is ~1852 meters (a nautical mile).
    let meters = MovementAutoPauseDetector.haversineMeters(0.0, 0.0, 1.0 / 60.0, 0.0)
    XCTAssertEqual(meters, 1852.0, accuracy: 5.0)
  }
}
