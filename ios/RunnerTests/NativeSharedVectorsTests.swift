import XCTest

@testable import Runner

/// Runs the cross-platform vectors in test/fixtures (geo_distance,
/// announcement_* and session_timing). The Kotlin tests in
/// NativeSharedVectorsTest.kt run the same files, so the duplicated native
/// logic cannot drift. Located relative to this source file so the fixtures
/// need no Xcode resource wiring.
final class NativeSharedVectorsTests: XCTestCase {

  private func load(_ name: String) throws -> [String: Any] {
    let url = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()  // RunnerTests
      .deletingLastPathComponent()  // ios
      .deletingLastPathComponent()  // repo root
      .appendingPathComponent("test/fixtures/\(name)")
    return try XCTUnwrap(
      JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
  }

  private func array(_ json: [String: Any], _ key: String) throws -> [[String: Any]] {
    let items = try XCTUnwrap(json[key] as? [[String: Any]])
    XCTAssertFalse(items.isEmpty)
    return items
  }

  private func double(_ value: Any?) -> Double {
    return (value as? NSNumber)?.doubleValue ?? .nan
  }

  private func int(_ value: Any?) -> Int {
    return (value as? NSNumber)?.intValue ?? Int.min
  }

  /// JSON null decodes to NSNull; treat it as absent.
  private func optionalString(_ value: Any?) -> String? {
    return value as? String
  }

  private func optionalDouble(_ value: Any?) -> Double? {
    return (value as? NSNumber)?.doubleValue
  }

  private func state(config: [String: Any], initial: [String: Any]?) -> AnnouncementStateData {
    let base = AnnouncementStateData(
      enabled: config["enabled"] as? Bool ?? false,
      duckOtherAudio: true,
      intervalUnit: config["intervalUnit"] as? String ?? "",
      distanceIntervalMeters: double(config["distanceIntervalMeters"]),
      timeIntervalSeconds: int(config["timeIntervalSeconds"]),
      useImperialUnits: config["useImperialUnits"] as? Bool ?? false,
      metric: config["metric"] as? String ?? "",
      languageTag: config["languageTag"] as? String ?? "",
      distanceUnitTemplate: config["distanceUnitTemplate"] as? String ?? "",
      metricUnitTemplate: config["metricUnitTemplate"] as? String ?? "",
      metricLabel: config["metricLabel"] as? String ?? "",
      messageTemplate: config["messageTemplate"] as? String ?? "")
    guard let initial else {
      return base
    }
    return AnnouncementStateData(
      enabled: base.enabled,
      duckOtherAudio: base.duckOtherAudio,
      intervalUnit: base.intervalUnit,
      distanceIntervalMeters: base.distanceIntervalMeters,
      timeIntervalSeconds: base.timeIntervalSeconds,
      useImperialUnits: base.useImperialUnits,
      metric: base.metric,
      languageTag: base.languageTag,
      distanceUnitTemplate: base.distanceUnitTemplate,
      metricUnitTemplate: base.metricUnitTemplate,
      metricLabel: base.metricLabel,
      messageTemplate: base.messageTemplate,
      cumulativeDistanceMeters: optionalDouble(initial["cumulativeDistanceMeters"]) ?? 0,
      lastAnnouncedDistanceIndex: optionalDouble(initial["lastAnnouncedDistanceIndex"]).map(Int.init) ?? 0,
      lastAnnouncedTimeIndex: optionalDouble(initial["lastAnnouncedTimeIndex"]).map(Int.init) ?? 0,
      lastLatitude: optionalDouble(initial["lastLatitude"]),
      lastLongitude: optionalDouble(initial["lastLongitude"]),
      lastElapsedSeconds: optionalDouble(initial["lastElapsedSeconds"]).map(Int.init) ?? 0,
      lastAnnouncementDistanceMeters: optionalDouble(initial["lastAnnouncementDistanceMeters"]) ?? 0,
      lastAnnouncementElapsedSeconds:
        optionalDouble(initial["lastAnnouncementElapsedSeconds"]).map(Int.init) ?? 0)
  }

  func testGeoDistanceVectors() throws {
    let json = try load("geo_distance_vectors.json")
    let tolerance = double(json["toleranceMeters"])
    for spec in try array(json, "cases") {
      let actual = GeoDistance.haversineMeters(
        lat1: double(spec["lat1"]), lon1: double(spec["lon1"]),
        lat2: double(spec["lat2"]), lon2: double(spec["lon2"]))
      XCTAssertEqual(
        actual, double(spec["meters"]), accuracy: tolerance, spec["name"] as? String ?? "?")
    }
  }

  func testThresholdCalculatorVectors() throws {
    let json = try load("announcement_threshold_vectors.json")
    for spec in try array(json, "cases") {
      let name = spec["name"] as? String ?? "?"
      let actual = AnnouncementThresholdCalculator.latestCrossing(
        intervalValue: double(spec["intervalValue"]),
        previousCumulative: double(spec["previousCumulative"]),
        newCumulative: double(spec["newCumulative"]),
        lastAnnouncedIndex: int(spec["lastAnnouncedIndex"]))
      guard let expect = spec["expect"] as? [String: Any] else {
        XCTAssertNil(actual, name)
        continue
      }
      let crossing = try XCTUnwrap(actual, name)
      XCTAssertEqual(crossing.thresholdIndex, int(expect["thresholdIndex"]), name)
      XCTAssertEqual(crossing.thresholdValue, double(expect["thresholdValue"]), accuracy: 1e-9, name)
      XCTAssertEqual(
        crossing.interpolationFraction, double(expect["interpolationFraction"]), accuracy: 1e-9,
        name)
    }
  }

  func testSpeechBuilderVectors() throws {
    let json = try load("announcement_speech_vectors.json")
    for spec in try array(json, "cases") {
      let name = spec["name"] as? String ?? "?"
      let config = try XCTUnwrap(spec["config"] as? [String: Any], name)
      let base = state(config: config, initial: nil)
      let actual: String
      if spec["preview"] as? Bool ?? false {
        actual = AnnouncementSpeechBuilder.buildPreview(state: base)
      } else {
        let withLap = base.copyWith(
          lastAnnouncementDistanceMeters: double(spec["lastAnnouncementDistanceMeters"]),
          lastAnnouncementElapsedSeconds: int(spec["lastAnnouncementElapsedSeconds"]))
        actual = AnnouncementSpeechBuilder.build(
          state: withLap,
          distanceMeters: double(spec["distanceMeters"]),
          elapsedSeconds: int(spec["elapsedSeconds"]))
      }
      XCTAssertEqual(actual, spec["expect"] as? String, name)
    }
  }

  func testSchedulerVectors() throws {
    let json = try load("announcement_scheduler_vectors.json")
    for spec in try array(json, "cases") {
      let name = spec["name"] as? String ?? "?"
      let config = try XCTUnwrap(spec["config"] as? [String: Any], name)
      var current = state(config: config, initial: spec["initial"] as? [String: Any])
      let steps = try XCTUnwrap(spec["steps"] as? [[String: Any]], name)
      for (index, step) in steps.enumerated() {
        let label = "\(name): step \(index)"
        let result: AnnouncementScheduler.Result
        if step["type"] as? String == "fix" {
          result = AnnouncementScheduler.onFix(
            state: current,
            latitude: double(step["latitude"]),
            longitude: double(step["longitude"]),
            elapsedSeconds: int(step["elapsedSeconds"]),
            isNewSegment: step["isNewSegment"] as? Bool ?? false)
        } else {
          result = AnnouncementScheduler.onElapsedTime(
            state: current, elapsedSeconds: int(step["elapsedSeconds"]))
        }
        current = result.state
        XCTAssertEqual(
          result.announcements, step["expectAnnouncements"] as? [String] ?? [], label)
        let expected = try XCTUnwrap(step["expectState"] as? [String: Any], label)
        XCTAssertEqual(
          current.cumulativeDistanceMeters, double(expected["cumulativeDistanceMeters"]),
          accuracy: 1e-6, label)
        XCTAssertEqual(
          current.lastAnnouncedDistanceIndex, int(expected["lastAnnouncedDistanceIndex"]), label)
        XCTAssertEqual(
          current.lastAnnouncedTimeIndex, int(expected["lastAnnouncedTimeIndex"]), label)
        XCTAssertEqual(current.lastElapsedSeconds, int(expected["lastElapsedSeconds"]), label)
        XCTAssertEqual(
          current.lastAnnouncementDistanceMeters,
          double(expected["lastAnnouncementDistanceMeters"]), accuracy: 1e-6, label)
        XCTAssertEqual(
          current.lastAnnouncementElapsedSeconds,
          int(expected["lastAnnouncementElapsedSeconds"]), label)
      }
    }
  }

  private func session(_ spec: [String: Any]) -> ActiveActivitySessionData {
    return ActiveActivitySessionData(
      localSessionId: "vector",
      activityType: "run",
      status: spec["status"] as? String ?? "",
      startedAt: spec["startedAt"] as? String ?? "",
      resumedAt: optionalString(spec["resumedAt"]),
      pausedAt: optionalString(spec["pausedAt"]),
      endedAt: optionalString(spec["endedAt"]),
      elapsedDurationSeconds: int(spec["elapsedDurationSeconds"]))
  }

  func testSessionTimingElapsedVectors() throws {
    let json = try load("session_timing_vectors.json")
    for spec in try array(json, "elapsedCases") {
      let name = spec["name"] as? String ?? "?"
      let input = try XCTUnwrap(spec["session"] as? [String: Any], name)
      let actual = SessionTiming.elapsedSeconds(
        session(input), referenceMillis: Int64(int(spec["referenceMillis"])))
      XCTAssertEqual(actual, int(spec["elapsedSeconds"]), name)
    }
  }

  func testSessionTimingInterruptionVectors() throws {
    let json = try load("session_timing_vectors.json")
    for spec in try array(json, "interruptionCases") {
      let name = spec["name"] as? String ?? "?"
      let input = try XCTUnwrap(spec["session"] as? [String: Any], name)
      let lastPoint = (spec["lastPointMillis"] as? NSNumber).map { Int64(truncating: $0) }
      let actual = SessionTiming.afterInterruption(
        session(input),
        lastPointMillis: lastPoint,
        nowMillis: Int64(int(spec["nowMillis"])))
      let expect = try XCTUnwrap(spec["expect"] as? [String: Any], name)
      XCTAssertEqual(actual.status, expect["status"] as? String, name)
      XCTAssertEqual(actual.resumedAt, optionalString(expect["resumedAt"]), name)
      XCTAssertEqual(actual.pausedAt, optionalString(expect["pausedAt"]), name)
      XCTAssertEqual(actual.endedAt, optionalString(expect["endedAt"]), name)
      XCTAssertEqual(
        actual.elapsedDurationSeconds, int(expect["elapsedDurationSeconds"]), name)
    }
  }
}
