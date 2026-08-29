import XCTest

@testable import Runner

/// Unit tests for `AnnouncementThresholdCalculator`, the pure threshold
/// crossing/interpolation math the on-device announcement scheduler depends
/// on. Mirrors the Android `AnnouncementThresholdCalculatorTest` exactly so
/// both platforms are locked to the identical contract.
final class AnnouncementThresholdCalculatorTests: XCTestCase {

  func testNoCrossingWhenBelowTheFirstThreshold() {
    let crossings = AnnouncementThresholdCalculator.crossedThresholds(
      intervalValue: 1000,
      previousCumulative: 200,
      newCumulative: 900,
      lastAnnouncedIndex: 0
    )

    XCTAssertTrue(crossings.isEmpty)
  }

  func testCrossesTheFirstThresholdWithInterpolationFraction() {
    let crossings = AnnouncementThresholdCalculator.crossedThresholds(
      intervalValue: 1000,
      previousCumulative: 900,
      newCumulative: 1100,
      lastAnnouncedIndex: 0
    )

    XCTAssertEqual(crossings.count, 1)
    XCTAssertEqual(crossings[0].thresholdIndex, 1)
    XCTAssertEqual(crossings[0].thresholdValue, 1000, accuracy: 0.0001)
    XCTAssertEqual(crossings[0].interpolationFraction, 0.5, accuracy: 0.0001)
  }

  func testExactHitOnTheThresholdUsesFractionOne() {
    let crossings = AnnouncementThresholdCalculator.crossedThresholds(
      intervalValue: 1000,
      previousCumulative: 500,
      newCumulative: 1000,
      lastAnnouncedIndex: 0
    )

    XCTAssertEqual(crossings.count, 1)
    XCTAssertEqual(crossings[0].interpolationFraction, 1.0, accuracy: 0.0001)
  }

  func testAGpsGapCanCrossSeveralThresholdsAtOnce() {
    let crossings = AnnouncementThresholdCalculator.crossedThresholds(
      intervalValue: 1000,
      previousCumulative: 500,
      newCumulative: 3200,
      lastAnnouncedIndex: 0
    )

    XCTAssertEqual(crossings.map { $0.thresholdIndex }, [1, 2, 3])
    let expectedFractions = [500.0 / 2700.0, 1500.0 / 2700.0, 2500.0 / 2700.0]
    for (index, crossing) in crossings.enumerated() {
      XCTAssertEqual(crossing.interpolationFraction, expectedFractions[index], accuracy: 0.0001)
    }
  }

  func testNeverReAnnouncesAThresholdAlreadyCovered() {
    let crossings = AnnouncementThresholdCalculator.crossedThresholds(
      intervalValue: 1000,
      previousCumulative: 1500,
      newCumulative: 1800,
      lastAnnouncedIndex: 1
    )

    XCTAssertTrue(crossings.isEmpty)
  }

  func testContinuesFromTheLastAnnouncedIndexNotFromZero() {
    let crossings = AnnouncementThresholdCalculator.crossedThresholds(
      intervalValue: 1000,
      previousCumulative: 4500,
      newCumulative: 5100,
      lastAnnouncedIndex: 4
    )

    XCTAssertEqual(crossings.map { $0.thresholdIndex }, [5])
  }

  func testNonPositiveIntervalNeverCrosses() {
    let crossings = AnnouncementThresholdCalculator.crossedThresholds(
      intervalValue: 0,
      previousCumulative: 0,
      newCumulative: 5000,
      lastAnnouncedIndex: 0
    )

    XCTAssertTrue(crossings.isEmpty)
  }

  func testNoMovementNeverCrosses() {
    let crossings = AnnouncementThresholdCalculator.crossedThresholds(
      intervalValue: 1000,
      previousCumulative: 500,
      newCumulative: 500,
      lastAnnouncedIndex: 0
    )

    XCTAssertTrue(crossings.isEmpty)
  }

  func testCapsCrossingsPerUpdateForAPathologicalJump() {
    let crossings = AnnouncementThresholdCalculator.crossedThresholds(
      intervalValue: 1,
      previousCumulative: 0,
      newCumulative: 1000,
      lastAnnouncedIndex: 0,
      maxCrossingsPerUpdate: 5
    )

    XCTAssertEqual(crossings.count, 5)
    XCTAssertEqual(crossings.map { $0.thresholdIndex }, [1, 2, 3, 4, 5])
  }
}
