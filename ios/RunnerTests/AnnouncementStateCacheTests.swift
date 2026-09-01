import XCTest

@testable import Runner

final class AnnouncementStateCacheTests: XCTestCase {
  private func state(distanceMeters: Double = 0) -> AnnouncementStateData {
    return AnnouncementStateData(
      enabled: true,
      duckOtherAudio: true,
      intervalUnit: AnnouncementStateData.unitDistance,
      distanceIntervalMeters: 1000,
      timeIntervalSeconds: 300,
      useImperialUnits: false,
      metric: AnnouncementStateData.metricPace,
      languageTag: "en-US",
      distanceUnitTemplate: "{value} km",
      metricUnitTemplate: "{value} min/km",
      metricLabel: "Pace",
      messageTemplate: "{distance} {duration} {lapMetric} {overallMetric}",
      cumulativeDistanceMeters: distanceMeters
    )
  }

  func testUnchangedStateDoesNotNeedPersistence() {
    let cache = AnnouncementStateCache(checkpointInterval: 60)
    cache.restore(state(), uptime: 1)

    XCTAssertNil(cache.stateToPersist(uptime: 61))
  }

  func testChangedStateWaitsForCheckpointInterval() {
    let cache = AnnouncementStateCache(checkpointInterval: 60)
    let updated = state(distanceMeters: 25)
    cache.restore(state(), uptime: 1)
    cache.update(updated)

    XCTAssertNil(cache.stateToPersist(uptime: 60.999))
    XCTAssertEqual(updated, cache.stateToPersist(uptime: 61))
  }

  func testForcedCheckpointIsAvailableImmediately() {
    let cache = AnnouncementStateCache(checkpointInterval: 60)
    let updated = state(distanceMeters: 25)
    cache.restore(state(), uptime: 1)
    cache.update(updated)

    XCTAssertEqual(updated, cache.stateToPersist(uptime: 1.001, force: true))
  }

  func testPersistedStateIsNotReturnedAgain() {
    let cache = AnnouncementStateCache(checkpointInterval: 60)
    cache.restore(state(), uptime: 1)
    cache.update(state(distanceMeters: 25))
    cache.markPersisted(uptime: 1.001)

    XCTAssertNil(cache.stateToPersist(uptime: 61.001, force: true))
  }
}