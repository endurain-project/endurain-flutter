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

  func testNearestSampleWinsAcrossABatchOfFixes() {
    let samples = [
      (bpm: 120, date: sampleDate),
      (bpm: 130, date: sampleDate.addingTimeInterval(5)),
      (bpm: 140, date: sampleDate.addingTimeInterval(10)),
    ]

    XCTAssertEqual(HealthKitHeartRateMonitor.nearestBpm(samples, at: sampleDate.addingTimeInterval(1)), 120)
    XCTAssertEqual(HealthKitHeartRateMonitor.nearestBpm(samples, at: sampleDate.addingTimeInterval(6)), 130)
    XCTAssertEqual(HealthKitHeartRateMonitor.nearestBpm(samples, at: sampleDate.addingTimeInterval(9)), 140)
    XCTAssertNil(HealthKitHeartRateMonitor.nearestBpm(samples, at: sampleDate.addingTimeInterval(30)))
    XCTAssertNil(HealthKitHeartRateMonitor.nearestBpm([], at: sampleDate))
  }

  func testSampleHistoryIsBounded() {
    var samples: [HealthKitHeartRateMonitor.Sample] = []
    for i in 0..<(HealthKitHeartRateMonitor.maxSamples + 10) {
      samples = HealthKitHeartRateMonitor.appending((bpm: i, date: sampleDate), to: samples)
    }

    XCTAssertEqual(samples.count, HealthKitHeartRateMonitor.maxSamples)
    XCTAssertEqual(samples.first?.bpm, 10)
  }

  /// Late callbacks after `stop()` must not resurrect state or start sessions.
  func testStopWithoutSessionIsSafeAndDropsSamples() {
    let monitor = HealthKitHeartRateMonitor()
    monitor.stop()
    monitor.stop()

    XCTAssertNil(monitor.heartRateBpm(at: sampleDate))
  }
}
