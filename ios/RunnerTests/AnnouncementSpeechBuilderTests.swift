import XCTest

@testable import Runner

/// Unit tests for `AnnouncementSpeechBuilder`, the pure text formatting that
/// turns a threshold crossing into the exact sentence `AudioAnnouncer`
/// speaks. Mirrors the Android `AnnouncementSpeechBuilderTest` exactly.
final class AnnouncementSpeechBuilderTests: XCTestCase {

  private func metricState(
    messageTemplate: String =
      "Distance {distance}. Time {duration}. Lap {lapMetric}. Overall {overallMetric}.",
    metricLabel: String = "Pace"
  ) -> AnnouncementStateData {
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
      metricLabel: metricLabel,
      messageTemplate: messageTemplate
    )
  }

  func testBuildsTheMetricSentenceAtOneKilometer() {
    let text = AnnouncementSpeechBuilder.build(
      state: metricState(),
      distanceMeters: 1000,
      elapsedSeconds: 330
    )

    XCTAssertEqual(
      text,
      "Distance 1.0 km. Time 5:30. Lap Pace 5:30 min/km. "
        + "Overall Pace 5:30 min/km."
    )
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
      metric: AnnouncementStateData.metricPace,
      languageTag: "en-US",
      distanceUnitTemplate: "{value} mi",
      metricUnitTemplate: "{value} min/mi",
      metricLabel: "Pace",
      messageTemplate:
        "Distance {distance}. Time {duration}. Lap {lapMetric}. Overall {overallMetric}."
    )

    let text = AnnouncementSpeechBuilder.build(
      state: state,
      distanceMeters: 1609.344,
      elapsedSeconds: 480
    )

    XCTAssertEqual(
      text,
      "Distance 1.0 mi. Time 8:00. Lap Pace 8:00 min/mi. "
        + "Overall Pace 8:00 min/mi."
    )
  }

  func testOmitsPaceAtZeroDistanceInsteadOfDividingByZero() {
    let text = AnnouncementSpeechBuilder.build(
      state: metricState(),
      distanceMeters: 0,
      elapsedSeconds: 60
    )

    XCTAssertEqual(text, "Distance 0.0 km. Time 1:00. Lap Pace. Overall Pace.")
  }

  func testLeavesUnrelatedLocaleTextUntouched() {
    let state = metricState(
      messageTemplate:
        "Distância {distance}. Tempo {duration}. Volta {lapMetric}. Total {overallMetric}.",
      metricLabel: "Ritmo"
    )

    let text = AnnouncementSpeechBuilder.build(
      state: state,
      distanceMeters: 2000,
      elapsedSeconds: 600
    )

    XCTAssertEqual(
      text,
      "Distância 2.0 km. Tempo 10:00. Volta Ritmo 5:00 min/km. "
        + "Total Ritmo 5:00 min/km."
    )
  }

  func testDistinguishesLapPaceFromOverallPace() {
    var state = metricState()
    state.lastAnnouncementDistanceMeters = 1000
    state.lastAnnouncementElapsedSeconds = 330

    let text = AnnouncementSpeechBuilder.build(
      state: state,
      distanceMeters: 2000,
      elapsedSeconds: 630
    )

    XCTAssertTrue(text.contains("Lap Pace 5:00 min/km"))
    XCTAssertTrue(text.contains("Overall Pace 5:15 min/km"))
  }

  func testRidesUseLapAndOverallSpeed() {
    let state = AnnouncementStateData(
      enabled: true,
      duckOtherAudio: true,
      intervalUnit: AnnouncementStateData.unitDistance,
      distanceIntervalMeters: 5000,
      timeIntervalSeconds: 300,
      useImperialUnits: false,
      metric: AnnouncementStateData.metricSpeed,
      languageTag: "en-US",
      distanceUnitTemplate: "{value} km",
      metricUnitTemplate: "{value} km/h",
      metricLabel: "Speed",
      messageTemplate:
        "Distance {distance}. Time {duration}. Lap {lapMetric}. Overall {overallMetric}.",
      lastAnnouncementDistanceMeters: 5000,
      lastAnnouncementElapsedSeconds: 1000
    )

    let text = AnnouncementSpeechBuilder.build(
      state: state,
      distanceMeters: 10_000,
      elapsedSeconds: 1800
    )

    XCTAssertTrue(text.contains("Lap Speed 22.5 km/h"))
    XCTAssertTrue(text.contains("Overall Speed 20.0 km/h"))
  }

  func testUsesTheLocaleDecimalSeparatorSoEnginesDoNotReadItAsGrouping() {
    let state = AnnouncementStateData(
      enabled: true,
      duckOtherAudio: true,
      intervalUnit: AnnouncementStateData.unitDistance,
      distanceIntervalMeters: 1000,
      timeIntervalSeconds: 300,
      useImperialUnits: false,
      metric: AnnouncementStateData.metricSpeed,
      languageTag: "de-DE",
      distanceUnitTemplate: "{value} km",
      metricUnitTemplate: "{value} km/h",
      metricLabel: "Geschwindigkeit",
      messageTemplate:
        "Distanz {distance}. Zeit {duration}. Runde {lapMetric}. Gesamt {overallMetric}."
    )

    let text = AnnouncementSpeechBuilder.build(
      state: state,
      distanceMeters: 1500,
      elapsedSeconds: 300
    )

    XCTAssertEqual(
      text,
      "Distanz 1,5 km. Zeit 5:00. Runde Geschwindigkeit 18,0 km/h. "
        + "Gesamt Geschwindigkeit 18,0 km/h."
    )
  }

  func testFallsBackToAPointWhenTheLanguageTagIsUnusable() {
    let state = AnnouncementStateData(
      enabled: true,
      duckOtherAudio: true,
      intervalUnit: AnnouncementStateData.unitDistance,
      distanceIntervalMeters: 1000,
      timeIntervalSeconds: 300,
      useImperialUnits: false,
      metric: AnnouncementStateData.metricPace,
      languageTag: "",
      distanceUnitTemplate: "{value} km",
      metricUnitTemplate: "{value} min/km",
      metricLabel: "Pace",
      messageTemplate:
        "Distance {distance}. Time {duration}. Lap {lapMetric}. Overall {overallMetric}."
    )

    let text = AnnouncementSpeechBuilder.build(
      state: state,
      distanceMeters: 1500,
      elapsedSeconds: 300
    )

    XCTAssertTrue(text.contains("1.5 km"))
  }

  func testPreviewStatesTheConfiguredDistanceMilestone() {
    let state = AnnouncementStateData(
      enabled: true,
      duckOtherAudio: true,
      intervalUnit: AnnouncementStateData.unitDistance,
      distanceIntervalMeters: 2000,
      timeIntervalSeconds: 300,
      useImperialUnits: false,
      metric: AnnouncementStateData.metricPace,
      languageTag: "en-US",
      distanceUnitTemplate: "{value} km",
      metricUnitTemplate: "{value} min/km",
      metricLabel: "Pace",
      messageTemplate:
        "Distance {distance}. Time {duration}. Lap {lapMetric}. Overall {overallMetric}."
    )

    let text = AnnouncementSpeechBuilder.buildPreview(state: state)

    // 2 km at the 3 m/s sample speed is 11:07, so 5:34 per km.
    XCTAssertEqual(
      text,
      "Distance 2.0 km. Time 11:07. Lap Pace 5:34 min/km. "
        + "Overall Pace 5:34 min/km."
    )
  }

  func testPreviewStatesTheConfiguredTimeMilestone() {
    let state = AnnouncementStateData(
      enabled: true,
      duckOtherAudio: true,
      intervalUnit: AnnouncementStateData.unitTime,
      distanceIntervalMeters: 1000,
      timeIntervalSeconds: 600,
      useImperialUnits: false,
      metric: AnnouncementStateData.metricPace,
      languageTag: "en-US",
      distanceUnitTemplate: "{value} km",
      metricUnitTemplate: "{value} min/km",
      metricLabel: "Pace",
      messageTemplate:
        "Distance {distance}. Time {duration}. Lap {lapMetric}. Overall {overallMetric}."
    )

    let text = AnnouncementSpeechBuilder.buildPreview(state: state)

    XCTAssertTrue(text.contains("Time 10:00"))
    XCTAssertTrue(text.contains("Distance 1.8 km"))
  }
}
