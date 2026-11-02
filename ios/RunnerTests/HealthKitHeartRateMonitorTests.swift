import HealthKit
import XCTest

@testable import Runner

/// Unit tests for the pure parts of `HealthKitHeartRateMonitor`: the freshness
/// window that decides whether a point gets the latest heart rate, and the
/// recording type to HealthKit workout type mapping.
@MainActor
final class HealthKitHeartRateMonitorTests: XCTestCase {

  private let sampleDate = Date(timeIntervalSince1970: 1_800_000_000)

  func testNoSampleYieldsNoHeartRate() {
    XCTAssertNil(HealthKitHeartRateMonitor.freshBpm(nil, at: sampleDate))
  }

  func testSampleWithinFreshnessIsUsedOnEitherSide() {
    let sample = (bpm: 142, date: sampleDate)

    XCTAssertEqual(HealthKitHeartRateMonitor.freshBpm(sample, at: sampleDate.addingTimeInterval(10)), 142)
    XCTAssertEqual(HealthKitHeartRateMonitor.freshBpm(sample, at: sampleDate.addingTimeInterval(-10)), 142)
  }

  func testStaleSampleIsIgnored() {
    let sample = (bpm: 142, date: sampleDate)

    XCTAssertNil(HealthKitHeartRateMonitor.freshBpm(sample, at: sampleDate.addingTimeInterval(10.5)))
  }

  func testActivityTypesMapToWorkoutTypes() {
    XCTAssertEqual(HealthKitHeartRateMonitor.workoutActivityType(for: "run"), .running)
    XCTAssertEqual(HealthKitHeartRateMonitor.workoutActivityType(for: "ride"), .cycling)
    XCTAssertEqual(HealthKitHeartRateMonitor.workoutActivityType(for: "walk"), .walking)
    XCTAssertEqual(HealthKitHeartRateMonitor.workoutActivityType(for: "hike"), .hiking)
    XCTAssertEqual(HealthKitHeartRateMonitor.workoutActivityType(for: "other"), .other)
    XCTAssertEqual(HealthKitHeartRateMonitor.workoutActivityType(for: "unknown"), .other)
  }
}
