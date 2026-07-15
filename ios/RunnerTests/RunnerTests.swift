import XCTest

@testable import Runner

/// Unit tests for the native activity-recorder serialization models.
///
/// These models are the durability contract between the iOS background
/// recorder and the Dart side: points and sessions are persisted as JSON and
/// later drained/recovered. A regression here would silently corrupt or drop a
/// user's recorded activity, so the round-trip and validation behavior is
/// locked down here. The JSON keys must stay compatible with the Dart models
/// in `lib/features/activity/models/` and the Android mirror.
final class ActiveRecordingModelsTests: XCTestCase {

  // MARK: - ActiveActivitySessionData

  func testSessionRoundTripsThroughMapPreservingEveryField() {
    let session = ActiveActivitySessionData(
      localSessionId: "activity_123",
      activityType: "run",
      status: ActiveActivitySessionData.statusPaused,
      startedAt: "2026-07-15T10:00:00.000Z",
      connectionOrigin: "https://example.test",
      connectionProfileId: "42",
      resumedAt: "2026-07-15T10:05:00.000Z",
      pausedAt: "2026-07-15T10:10:00.000Z",
      endedAt: "2026-07-15T10:20:00.000Z",
      elapsedDurationSeconds: 600,
      currentSegmentIndex: 3
    )

    let decoded = ActiveActivitySessionData.fromJson(session.toMap())

    XCTAssertEqual(decoded?.localSessionId, "activity_123")
    XCTAssertEqual(decoded?.activityType, "run")
    XCTAssertEqual(decoded?.status, ActiveActivitySessionData.statusPaused)
    XCTAssertEqual(decoded?.startedAt, "2026-07-15T10:00:00.000Z")
    XCTAssertEqual(decoded?.connectionOrigin, "https://example.test")
    XCTAssertEqual(decoded?.connectionProfileId, "42")
    XCTAssertEqual(decoded?.resumedAt, "2026-07-15T10:05:00.000Z")
    XCTAssertEqual(decoded?.pausedAt, "2026-07-15T10:10:00.000Z")
    XCTAssertEqual(decoded?.endedAt, "2026-07-15T10:20:00.000Z")
    XCTAssertEqual(decoded?.elapsedDurationSeconds, 600)
    XCTAssertEqual(decoded?.currentSegmentIndex, 3)
    XCTAssertEqual(
      decoded?.schemaVersion, ActiveActivitySessionData.schemaVersionValue)
  }

  func testSessionOmitsNilOptionalFieldsFromMap() {
    let session = ActiveActivitySessionData(
      localSessionId: "activity_1",
      activityType: "ride",
      status: ActiveActivitySessionData.statusRecording,
      startedAt: "2026-07-15T10:00:00.000Z"
    )

    let map = session.toMap()

    XCTAssertNil(map["connectionOrigin"])
    XCTAssertNil(map["connectionProfileId"])
    XCTAssertNil(map["resumedAt"])
    XCTAssertNil(map["pausedAt"])
    XCTAssertNil(map["endedAt"])
    XCTAssertEqual(
      map["schemaVersion"] as? Int, ActiveActivitySessionData.schemaVersionValue)
  }

  func testSessionToJsonStringIsParseableBack() {
    let session = ActiveActivitySessionData(
      localSessionId: "activity_1",
      activityType: "walk",
      status: ActiveActivitySessionData.statusRecording,
      startedAt: "2026-07-15T10:00:00.000Z"
    )

    guard
      let json = session.toJsonString(),
      let data = json.data(using: .utf8),
      let object = try? JSONSerialization.jsonObject(with: data)
        as? [String: Any]
    else {
      return XCTFail("session did not serialize to a JSON object")
    }

    XCTAssertEqual(
      ActiveActivitySessionData.fromJson(object)?.localSessionId, "activity_1")
  }

  func testSessionFromJsonReturnsNilWhenLocalSessionIdMissing() {
    let json: [String: Any] = [
      "activityType": "run",
      "status": ActiveActivitySessionData.statusRecording,
      "startedAt": "2026-07-15T10:00:00.000Z",
    ]

    XCTAssertNil(ActiveActivitySessionData.fromJson(json))
  }

  func testSessionFromJsonReturnsNilWhenStartedAtMissing() {
    let json: [String: Any] = [
      "localSessionId": "activity_1",
      "activityType": "run",
    ]

    XCTAssertNil(ActiveActivitySessionData.fromJson(json))
  }

  func testSessionFromJsonDefaultsStatusToFailedWhenAbsent() {
    let json: [String: Any] = [
      "localSessionId": "activity_1",
      "startedAt": "2026-07-15T10:00:00.000Z",
    ]

    XCTAssertEqual(
      ActiveActivitySessionData.fromJson(json)?.status,
      ActiveActivitySessionData.statusFailed)
  }

  func testSessionIsActiveOnlyWhileRecordingOrPaused() {
    func session(_ status: String) -> ActiveActivitySessionData {
      ActiveActivitySessionData(
        localSessionId: "activity_1",
        activityType: "run",
        status: status,
        startedAt: "2026-07-15T10:00:00.000Z"
      )
    }

    XCTAssertTrue(session(ActiveActivitySessionData.statusRecording).isActive)
    XCTAssertTrue(session(ActiveActivitySessionData.statusPaused).isActive)
    XCTAssertFalse(session(ActiveActivitySessionData.statusStopping).isActive)
    XCTAssertFalse(session(ActiveActivitySessionData.statusCompleted).isActive)
    XCTAssertFalse(session(ActiveActivitySessionData.statusFailed).isActive)
  }

  func testCopyWithOverridesOnlyProvidedFields() {
    let base = ActiveActivitySessionData(
      localSessionId: "activity_1",
      activityType: "run",
      status: ActiveActivitySessionData.statusRecording,
      startedAt: "2026-07-15T10:00:00.000Z",
      elapsedDurationSeconds: 10
    )

    let updated = base.copyWith(
      status: ActiveActivitySessionData.statusPaused,
      elapsedDurationSeconds: 20
    )

    XCTAssertEqual(updated.status, ActiveActivitySessionData.statusPaused)
    XCTAssertEqual(updated.elapsedDurationSeconds, 20)
    XCTAssertEqual(updated.localSessionId, "activity_1")
    XCTAssertEqual(updated.activityType, "run")
    XCTAssertEqual(updated.startedAt, "2026-07-15T10:00:00.000Z")
  }

  // MARK: - RecordedActivityPointData

  func testPointRoundTripsThroughMapPreservingEveryField() {
    let point = RecordedActivityPointData(
      timestamp: "2026-07-15T10:00:01.000Z",
      latitude: 38.7223,
      longitude: -9.1393,
      segmentIndex: 2,
      elevationMeters: 100.5,
      horizontalAccuracyMeters: 4,
      verticalAccuracyMeters: 6,
      headingDegrees: 180,
      headingAccuracyDegrees: 5,
      speedMetersPerSecond: 3.2,
      speedAccuracyMetersPerSecond: 0.5
    )

    let decoded = RecordedActivityPointData.fromJson(point.toMap())

    XCTAssertEqual(decoded?.timestamp, "2026-07-15T10:00:01.000Z")
    XCTAssertEqual(decoded?.latitude, 38.7223)
    XCTAssertEqual(decoded?.longitude, -9.1393)
    XCTAssertEqual(decoded?.segmentIndex, 2)
    XCTAssertEqual(decoded?.elevationMeters, 100.5)
    XCTAssertEqual(decoded?.horizontalAccuracyMeters, 4)
    XCTAssertEqual(decoded?.speedMetersPerSecond, 3.2)
    XCTAssertEqual(decoded?.speedAccuracyMetersPerSecond, 0.5)
  }

  func testPointUsesShortKeysMatchingTheDartParser() {
    let point = RecordedActivityPointData(
      timestamp: "2026-07-15T10:00:01.000Z",
      latitude: 1,
      longitude: 2,
      segmentIndex: 0,
      elevationMeters: 3
    )

    let map = point.toMap()

    XCTAssertEqual(map["t"] as? String, "2026-07-15T10:00:01.000Z")
    XCTAssertEqual(map["lat"] as? Double, 1)
    XCTAssertEqual(map["lon"] as? Double, 2)
    XCTAssertEqual(map["seg"] as? Int, 0)
    XCTAssertEqual(map["ele"] as? Double, 3)
    XCTAssertNil(map["spd"])
  }

  func testPointFromJsonReturnsNilWhenCoordinatesMissing() {
    XCTAssertNil(
      RecordedActivityPointData.fromJson(["t": "2026-07-15T10:00:01.000Z"]))
  }

  func testPointFromJsonReturnsNilForOutOfRangeCoordinates() {
    XCTAssertNil(
      RecordedActivityPointData.fromJson([
        "t": "2026-07-15T10:00:01.000Z", "lat": 91.0, "lon": 0.0,
      ]))
    XCTAssertNil(
      RecordedActivityPointData.fromJson([
        "t": "2026-07-15T10:00:01.000Z", "lat": 0.0, "lon": -181.0,
      ]))
  }

  func testTryParseLineSkipsBlankAndMalformedLines() {
    XCTAssertNil(RecordedActivityPointData.tryParseLine(""))
    XCTAssertNil(RecordedActivityPointData.tryParseLine("   "))
    XCTAssertNil(RecordedActivityPointData.tryParseLine("not json"))
    XCTAssertNil(RecordedActivityPointData.tryParseLine("{\"t\":\"x\"}"))
  }

  func testTryParseLineParsesAValidStoredLine() {
    guard
      let line = RecordedActivityPointData(
        timestamp: "2026-07-15T10:00:01.000Z",
        latitude: 10,
        longitude: 20,
        segmentIndex: 1
      ).toJsonLine()
    else {
      return XCTFail("point did not serialize to a JSON line")
    }

    let parsed = RecordedActivityPointData.tryParseLine(line)

    XCTAssertEqual(parsed?.latitude, 10)
    XCTAssertEqual(parsed?.longitude, 20)
    XCTAssertEqual(parsed?.segmentIndex, 1)
  }

  // MARK: - IsoTime

  func testIsoTimeFormatsUtcWithTrailingZ() {
    // 2026-07-15T10:00:00Z == 1_784_109_600 seconds since epoch.
    let formatted = IsoTime.format(Date(timeIntervalSince1970: 1_784_109_600))

    XCTAssertEqual(formatted, "2026-07-15T10:00:00.000Z")
  }

  func testIsoTimeParsesUtcToEpochMillisAtSecondPrecision() {
    XCTAssertEqual(
      IsoTime.toEpochMillis("2026-07-15T10:00:00.000Z"), 1_784_109_600_000)
  }

  func testIsoTimeRoundTripsAtSecondPrecision() {
    let original = "2026-07-15T10:00:00.000Z"

    guard let millis = IsoTime.toEpochMillis(original) else {
      return XCTFail("timestamp did not parse")
    }
    let formatted = IsoTime.format(
      Date(timeIntervalSince1970: Double(millis) / 1000.0))

    XCTAssertEqual(formatted, original)
  }

  func testIsoTimeReturnsNilForNilOrMalformedInput() {
    XCTAssertNil(IsoTime.toEpochMillis(nil))
    XCTAssertNil(IsoTime.toEpochMillis(""))
    XCTAssertNil(IsoTime.toEpochMillis("not-a-timestamp"))
  }

  // MARK: - JsonScalar

  func testJsonScalarParsesIntsAndDoublesLeniently() {
    XCTAssertEqual(JsonScalar.int(5), 5)
    XCTAssertEqual(JsonScalar.int(NSNumber(value: 7)), 7)
    XCTAssertEqual(JsonScalar.int(3.9), 3)
    XCTAssertNil(JsonScalar.int("x"))

    XCTAssertEqual(JsonScalar.double(2.5), 2.5)
    XCTAssertEqual(JsonScalar.double(4), 4.0)
    XCTAssertNil(JsonScalar.double("x"))
  }
}
