import XCTest

@testable import Runner

/// Unit tests for `AnnouncementSpeechBuilder`, the pure text formatting that
/// turns a threshold crossing into the exact sentence `AudioAnnouncer`
/// speaks. Mirrors the Android `AnnouncementSpeechBuilderTest` exactly.
final class AnnouncementSpeechBuilderTests: XCTestCase {

  private func metricState(
    messageTemplate: String = "Distance {distance}. Time {duration}. Pace {pace}."
  ) -> AnnouncementStateData {
    return AnnouncementStateData(
      enabled: true,
      duckOtherAudio: true,
      intervalUnit: AnnouncementStateData.unitDistance,
      distanceIntervalMeters: 1000,
      timeIntervalSeconds: 300,
      useImperialUnits: false,
      languageTag: "en-US",
      distanceUnitTemplate: "{value} km",
      paceUnitTemplate: "{value} min/km",
      messageTemplate: messageTemplate
    )
  }

  func testBuildsTheMetricSentenceAtOneKilometer() {
    let text = AnnouncementSpeechBuilder.build(
      state: metricState(),
      distanceMeters: 1000,
      elapsedSeconds: 330
    )

    XCTAssertEqual(text, "Distance 1.0 km. Time 5:30. Pace 5:30 min/km.")
  }

  func testFormatsElapsedTimeWithHoursOnceAnHourHasPassed() {
    let text = AnnouncementSpeechBuilder.build(
      state: metricState(),
      distanceMeters: 10_000,
      elapsedSeconds: 3661
    )

    XCTAssertTrue(text.contains("1:01:01"))
  }

  func testConvertsToMilesWhenImperial() {
    let state = AnnouncementStateData(
      enabled: true,
      duckOtherAudio: true,
      intervalUnit: AnnouncementStateData.unitDistance,
      distanceIntervalMeters: 1000,
      timeIntervalSeconds: 300,
      useImperialUnits: true,
      languageTag: "en-US",
      distanceUnitTemplate: "{value} mi",
      paceUnitTemplate: "{value} min/mi",
      messageTemplate: "Distance {distance}. Time {duration}. Pace {pace}."
    )

    let text = AnnouncementSpeechBuilder.build(
      state: state,
      distanceMeters: 1609.344,
      elapsedSeconds: 480
    )

    XCTAssertEqual(text, "Distance 1.0 mi. Time 8:00. Pace 8:00 min/mi.")
  }

  func testOmitsPaceAtZeroDistanceInsteadOfDividingByZero() {
    let text = AnnouncementSpeechBuilder.build(
      state: metricState(),
      distanceMeters: 0,
      elapsedSeconds: 60
    )

    XCTAssertEqual(text, "Distance 0.0 km. Time 1:00. Pace .")
  }

  func testLeavesUnrelatedLocaleTextUntouched() {
    let state = metricState(messageTemplate: "Distância {distance}. Tempo {duration}. Ritmo {pace}.")

    let text = AnnouncementSpeechBuilder.build(
      state: state,
      distanceMeters: 2000,
      elapsedSeconds: 600
    )

    XCTAssertEqual(text, "Distância 2.0 km. Tempo 10:00. Ritmo 5:00 min/km.")
  }
}
