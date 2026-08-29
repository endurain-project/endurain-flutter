import XCTest

@testable import Runner

/// Unit tests for `AnnouncementStateData` serialization: the durability
/// contract between one location fix and the next (and across the process
/// being suspended/relaunched), so a regression here would silently reset the
/// "already announced" bookkeeping and cause duplicate announcements. Mirrors
/// the Android `AnnouncementModelsTest`.
final class AnnouncementModelsTests: XCTestCase {

  private func sampleState() -> AnnouncementStateData {
    return AnnouncementStateData(
      enabled: true,
      duckOtherAudio: false,
      intervalUnit: AnnouncementStateData.unitTime,
      distanceIntervalMeters: 2500,
      timeIntervalSeconds: 600,
      useImperialUnits: true,
      languageTag: "fr-FR",
      distanceUnitTemplate: "{value} mi",
      paceUnitTemplate: "{value} min/mi",
      messageTemplate: "Distance {distance}. Time {duration}. Pace {pace}.",
      cumulativeDistanceMeters: 4321.5,
      lastAnnouncedDistanceIndex: 4,
      lastAnnouncedTimeIndex: 2,
      lastLatitude: 38.7169,
      lastLongitude: -9.1399,
      lastElapsedSeconds: 1234
    )
  }

  func testRoundTripsThroughMapPreservingEveryField() {
    let state = sampleState()

    let decoded = AnnouncementStateData.fromJson(state.toMap())

    XCTAssertEqual(decoded, state)
  }

  func testIsTimeBasedReflectsTheIntervalUnit() {
    XCTAssertTrue(sampleState().isTimeBased)
    var distanceState = sampleState()
    distanceState = AnnouncementStateData(
      enabled: distanceState.enabled,
      duckOtherAudio: distanceState.duckOtherAudio,
      intervalUnit: AnnouncementStateData.unitDistance,
      distanceIntervalMeters: distanceState.distanceIntervalMeters,
      timeIntervalSeconds: distanceState.timeIntervalSeconds,
      useImperialUnits: distanceState.useImperialUnits,
      languageTag: distanceState.languageTag,
      distanceUnitTemplate: distanceState.distanceUnitTemplate,
      paceUnitTemplate: distanceState.paceUnitTemplate,
      messageTemplate: distanceState.messageTemplate
    )
    XCTAssertFalse(distanceState.isTimeBased)
  }

  func testFromJsonReturnsNilWithoutALanguageTag() {
    var map = sampleState().toMap()
    map.removeValue(forKey: "languageTag")

    XCTAssertNil(AnnouncementStateData.fromJson(map))
  }

  func testFromJsonToleratesAMissingOptionalLastPoint() {
    var map = sampleState().toMap()
    map.removeValue(forKey: "lastLatitude")
    map.removeValue(forKey: "lastLongitude")

    let decoded = AnnouncementStateData.fromJson(map)

    XCTAssertNil(decoded?.lastLatitude)
    XCTAssertNil(decoded?.lastLongitude)
  }

  func testFromStartArgumentsParsesTheDartChannelPayload() {
    let args: [String: Any] = [
      "enabled": true,
      "duckOtherAudio": false,
      "intervalUnit": "distance",
      "distanceIntervalMeters": 1000.0,
      "timeIntervalSeconds": 300,
      "useImperialUnits": false,
      "languageTag": "en-US",
      "distanceUnitTemplate": "{value} km",
      "paceUnitTemplate": "{value} min/km",
      "messageTemplate": "Distance {distance}. Time {duration}. Pace {pace}.",
    ]

    let state = AnnouncementStateData.fromStartArguments(args)

    XCTAssertEqual(state?.enabled, true)
    XCTAssertEqual(state?.duckOtherAudio, false)
    XCTAssertEqual(state?.languageTag, "en-US")
    XCTAssertEqual(state?.cumulativeDistanceMeters, 0)
    XCTAssertEqual(state?.lastAnnouncedDistanceIndex, 0)
  }

  func testFromStartArgumentsReturnsNilWithoutArguments() {
    XCTAssertNil(AnnouncementStateData.fromStartArguments(nil))
  }

  func testFromStartArgumentsReturnsNilWithoutALanguageTag() {
    XCTAssertNil(AnnouncementStateData.fromStartArguments(["enabled": true]))
  }

  func testToMapOmitsAbsentOptionalLastPoint() {
    var state = sampleState()
    state.lastLatitude = nil
    state.lastLongitude = nil

    let map = state.toMap()

    XCTAssertNil(map["lastLatitude"])
    XCTAssertNil(map["lastLongitude"])
  }
}
