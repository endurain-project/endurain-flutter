import XCTest

@testable import Runner

/// Unit tests for `AnnouncementScheduler`: the sequencing that ties the
/// durable `AnnouncementStateData` to `AnnouncementThresholdCalculator` and
/// `AnnouncementSpeechBuilder` for GPS and elapsed-time callbacks. Mirrors
/// the Android `AnnouncementSchedulerTest` exactly, exercising the same
/// "durable, no duplicates, interpolated" contract on both platforms.
final class AnnouncementSchedulerTests: XCTestCase {

  private func baseState(
    intervalUnit: String = AnnouncementStateData.unitDistance,
    distanceIntervalMeters: Double = 1000,
    timeIntervalSeconds: Int = 300
  ) -> AnnouncementStateData {
    return AnnouncementStateData(
      enabled: true,
      duckOtherAudio: true,
      intervalUnit: intervalUnit,
      distanceIntervalMeters: distanceIntervalMeters,
      timeIntervalSeconds: timeIntervalSeconds,
      useImperialUnits: false,
      languageTag: "en-US",
      distanceUnitTemplate: "{value} km",
      paceUnitTemplate: "{value} min/km",
      messageTemplate: "Distance {distance}. Time {duration}. Pace {pace}."
    )
  }

  func testDisabledStateNeverAnnouncesOrAccumulates() {
    let state = AnnouncementStateData(
      enabled: false,
      duckOtherAudio: true,
      intervalUnit: AnnouncementStateData.unitDistance,
      distanceIntervalMeters: 1000,
      timeIntervalSeconds: 300,
      useImperialUnits: false,
      languageTag: "en-US",
      distanceUnitTemplate: "{value} km",
      paceUnitTemplate: "{value} min/km",
      messageTemplate: "Distance {distance}. Time {duration}. Pace {pace}.",
      lastLatitude: 0,
      lastLongitude: 0
    )

    let result = AnnouncementScheduler.onFix(
      state: state,
      latitude: 0.01,
      longitude: 0,
      elapsedSeconds: 100,
      isNewSegment: false
    )

    XCTAssertTrue(result.announcements.isEmpty)
    XCTAssertEqual(result.state.cumulativeDistanceMeters, 0)
  }

  func testFirstFixOnlySeedsWithoutAnnouncing() {
    let result = AnnouncementScheduler.onFix(
      state: baseState(),
      latitude: 38.7169,
      longitude: -9.1399,
      elapsedSeconds: 0,
      isNewSegment: false
    )

    XCTAssertTrue(result.announcements.isEmpty)
    XCTAssertEqual(result.state.lastLatitude, 38.7169)
    XCTAssertEqual(result.state.cumulativeDistanceMeters, 0)
  }

  func testANewSegmentReseedsWithoutCountingTheGapAsDistance() {
    var seeded = baseState()
    seeded.lastLatitude = 0
    seeded.lastLongitude = 0
    seeded.lastElapsedSeconds = 10
    seeded.cumulativeDistanceMeters = 500

    let result = AnnouncementScheduler.onFix(
      state: seeded,
      latitude: 10,
      longitude: 10,
      elapsedSeconds: 400,
      isNewSegment: true
    )

    XCTAssertTrue(result.announcements.isEmpty)
    XCTAssertEqual(result.state.cumulativeDistanceMeters, 500)
    XCTAssertEqual(result.state.lastLatitude, 10)
  }

  func testAnnouncesOnceWhenCrossingADistanceThreshold() {
    var state = baseState()
    state.lastLatitude = 0
    state.lastLongitude = 0
    state.lastElapsedSeconds = 0

    let result = AnnouncementScheduler.onFix(
      state: state,
      latitude: 0,
      longitude: 0.009,
      elapsedSeconds: 300,
      isNewSegment: false
    )

    XCTAssertEqual(result.announcements.count, 1)
    XCTAssertEqual(result.state.lastAnnouncedDistanceIndex, 1)
    XCTAssertTrue(result.announcements[0].contains("1.0 km"))
  }

  func testNeverAnnouncesTheSameThresholdTwiceAcrossCalls() {
    let first = AnnouncementScheduler.onFix(
      state: baseState(),
      latitude: 0,
      longitude: 0,
      elapsedSeconds: 0,
      isNewSegment: false
    )

    let second = AnnouncementScheduler.onFix(
      state: first.state,
      latitude: 0,
      longitude: 0.009,
      elapsedSeconds: 300,
      isNewSegment: false
    )
    XCTAssertEqual(second.announcements.count, 1)

    let third = AnnouncementScheduler.onFix(
      state: second.state,
      latitude: 0,
      longitude: 0.0091,
      elapsedSeconds: 305,
      isNewSegment: false
    )

    XCTAssertTrue(third.announcements.isEmpty)
  }

  func testTimeBasedIntervalAnnouncesOnElapsedSecondsNotDistance() {
    var state = baseState(intervalUnit: AnnouncementStateData.unitTime, timeIntervalSeconds: 300)
    state.lastLatitude = 0
    state.lastLongitude = 0
    state.lastElapsedSeconds = 250

    let result = AnnouncementScheduler.onFix(
      state: state,
      latitude: 0.0001,
      longitude: 0.0001,
      elapsedSeconds: 320,
      isNewSegment: false
    )

    XCTAssertEqual(result.announcements.count, 1)
    XCTAssertEqual(result.state.lastAnnouncedTimeIndex, 1)
    XCTAssertEqual(result.state.lastAnnouncedDistanceIndex, 0)
  }

  func testTimeBasedIntervalAdvancesWithoutALocationFix() {
    var state = baseState(
      intervalUnit: AnnouncementStateData.unitTime,
      timeIntervalSeconds: 300
    )
    state.cumulativeDistanceMeters = 750
    state.lastElapsedSeconds = 250

    let result = AnnouncementScheduler.onElapsedTime(
      state: state,
      elapsedSeconds: 300
    )

    XCTAssertEqual(result.announcements.count, 1)
    XCTAssertEqual(result.state.lastAnnouncedTimeIndex, 1)
    XCTAssertEqual(result.state.lastElapsedSeconds, 300)
    XCTAssertEqual(result.state.cumulativeDistanceMeters, 750)
    XCTAssertTrue(result.announcements[0].contains("5:00"))
  }

  func testLocationFixDoesNotRepeatATimerAnnouncement() {
    var state = baseState(
      intervalUnit: AnnouncementStateData.unitTime,
      timeIntervalSeconds: 300
    )
    state.cumulativeDistanceMeters = 750
    state.lastLatitude = 0
    state.lastLongitude = 0
    state.lastElapsedSeconds = 250
    let timerResult = AnnouncementScheduler.onElapsedTime(
      state: state,
      elapsedSeconds: 300
    )

    let locationResult = AnnouncementScheduler.onFix(
      state: timerResult.state,
      latitude: 0,
      longitude: 0.0001,
      elapsedSeconds: 320,
      isNewSegment: false
    )

    XCTAssertEqual(timerResult.announcements.count, 1)
    XCTAssertTrue(locationResult.announcements.isEmpty)
    XCTAssertEqual(locationResult.state.lastAnnouncedTimeIndex, 1)
  }

  func testDelayedTimerCatchesThresholdAfterElapsedStateAdvanced() {
    var state = baseState(
      intervalUnit: AnnouncementStateData.unitTime,
      timeIntervalSeconds: 300
    )
    state.lastElapsedSeconds = 320
    state.lastAnnouncedTimeIndex = 0

    let result = AnnouncementScheduler.onElapsedTime(
      state: state,
      elapsedSeconds: 320
    )

    XCTAssertEqual(result.announcements.count, 1)
    XCTAssertEqual(result.state.lastAnnouncedTimeIndex, 1)
  }
}
