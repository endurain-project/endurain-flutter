import XCTest

@testable import Runner

/// Unit tests for `AnnouncementThresholdCalculator`, the pure threshold
/// crossing/interpolation math the on-device announcement scheduler depends
/// on. Mirrors the Android `AnnouncementThresholdCalculatorTest` exactly so
/// both platforms are locked to the identical contract.
final class AnnouncementThresholdCalculatorTests: XCTestCase {

  func testNoCrossingWhenBelowTheFirstThreshold() {
    let crossing = AnnouncementThresholdCalculator.latestCrossing(
      intervalValue: 1000,
      previousCumulative: 200,
      newCumulative: 900,
      lastAnnouncedIndex: 0
    )

    XCTAssertNil(crossing)
  }

  func testCrossesTheFirstThresholdWithInterpolationFraction() {
    let crossing = AnnouncementThresholdCalculator.latestCrossing(
      intervalValue: 1000,
      previousCumulative: 900,
      newCumulative: 1100,
      lastAnnouncedIndex: 0
    )

    XCTAssertEqual(crossing?.thresholdIndex, 1)
    XCTAssertEqual(crossing!.thresholdValue, 1000, accuracy: 0.0001)
    XCTAssertEqual(crossing!.interpolationFraction, 0.5, accuracy: 0.0001)
  }

  func testExactHitOnTheThresholdUsesFractionOne() {
    let crossing = AnnouncementThresholdCalculator.latestCrossing(
      intervalValue: 1000,
      previousCumulative: 500,
      newCumulative: 1000,
      lastAnnouncedIndex: 0
    )

    XCTAssertEqual(crossing!.interpolationFraction, 1.0, accuracy: 0.0001)
  }

  func testAGpsGapReturnsOnlyTheLatestCrossing() {
    let crossing = AnnouncementThresholdCalculator.latestCrossing(
      intervalValue: 1000,
      previousCumulative: 500,
      newCumulative: 3200,
      lastAnnouncedIndex: 0
    )

    XCTAssertEqual(crossing?.thresholdIndex, 3)
    XCTAssertEqual(crossing!.interpolationFraction, 2500.0 / 2700.0, accuracy: 0.0001)
  }

  func testNeverReAnnouncesAThresholdAlreadyCovered() {
    let crossing = AnnouncementThresholdCalculator.latestCrossing(
      intervalValue: 1000,
      previousCumulative: 1500,
      newCumulative: 1800,
      lastAnnouncedIndex: 1
    )

    XCTAssertNil(crossing)
  }

  func testContinuesFromTheLastAnnouncedIndexNotFromZero() {
    let crossing = AnnouncementThresholdCalculator.latestCrossing(
      intervalValue: 1000,
      previousCumulative: 4500,
      newCumulative: 5100,
      lastAnnouncedIndex: 4
    )

    XCTAssertEqual(crossing?.thresholdIndex, 5)
  }

  func testNonPositiveIntervalNeverCrosses() {
    let crossing = AnnouncementThresholdCalculator.latestCrossing(
      intervalValue: 0,
      previousCumulative: 0,
      newCumulative: 5000,
      lastAnnouncedIndex: 0
    )

    XCTAssertNil(crossing)
  }

  func testNoMovementNeverCrosses() {
    let crossing = AnnouncementThresholdCalculator.latestCrossing(
      intervalValue: 1000,
      previousCumulative: 500,
      newCumulative: 500,
      lastAnnouncedIndex: 0
    )

    XCTAssertNil(crossing)
  }

  func testPathologicalJumpReturnsOnlyTheLatestCrossing() {
    let crossing = AnnouncementThresholdCalculator.latestCrossing(
      intervalValue: 1,
      previousCumulative: 0,
      newCumulative: 1000,
      lastAnnouncedIndex: 0
    )

    XCTAssertEqual(crossing?.thresholdIndex, 1000)
    XCTAssertEqual(crossing!.interpolationFraction, 1, accuracy: 0.0001)
  }
}
