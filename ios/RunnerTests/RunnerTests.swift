import CoreLocation
import XCTest

@testable import Runner

@MainActor
final class ActivityRecordingRecoveryTests: XCTestCase {
  private func makeStore() -> ActiveActivityStore {
    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    addTeardownBlock { try? FileManager.default.removeItem(at: directory) }
    return ActiveActivityStore(activeDirectory: directory)
  }

  private func session(_ status: String = ActiveActivitySessionData.statusRecording)
    -> ActiveActivitySessionData {
    ActiveActivitySessionData(
      localSessionId: "existing_session",
      activityType: "ride",
      status: status,
      startedAt: IsoTime.format(Date().addingTimeInterval(-60)),
      connectionOrigin: "https://example.test",
      connectionProfileId: "profile_1"
    )
  }

  private func location(_ timestamp: Date, latitude: Double) -> CLLocation {
    CLLocation(
      coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: -8),
      altitude: 100,
      horizontalAccuracy: 5,
      verticalAccuracy: 5,
      timestamp: timestamp
    )
  }

  func testLiveRecoveryDoesNotStopOrRestartLocationUpdates() throws {
    let store = makeStore()
    let original = session()
    XCTAssertTrue(store.saveSession(original))
    let manager = RecoveryLocationManager()
    let recorder = CoreLocationActivityRecorder(store: store, manager: manager)
    defer { recorder.stopCollection() }
    XCTAssertTrue(recorder.startCollection())
    let firstTime = Date()
    recorder.locationManager(manager, didUpdateLocations: [location(firstTime, latitude: 41.1)])

    let recovered = try XCTUnwrap(recorder.recoverActiveSession())
    let again = try XCTUnwrap(recorder.recoverActiveSession())

    XCTAssertEqual(recovered.localSessionId, original.localSessionId)
    XCTAssertEqual(recovered.connectionProfileId, original.connectionProfileId)
    XCTAssertEqual(recovered.status, ActiveActivitySessionData.statusRecording)
    XCTAssertEqual(recovered.startedAt, original.startedAt)
    XCTAssertNil(recovered.resumedAt)
    XCTAssertEqual(again.resumedAt, recovered.resumedAt)
    XCTAssertEqual(manager.startCount, 1)
    XCTAssertEqual(manager.stopCount, 0)
    recorder.locationManager(
      manager,
      didUpdateLocations: [location(firstTime.addingTimeInterval(1), latitude: 41.2)]
    )
    let points = try store.readPoints()
    XCTAssertEqual(points.count, 2)
    XCTAssertEqual(points.map { $0.segmentIndex }, [0, 0])
  }

  func testRestartUsesTheSameSessionAndOpensANewSegment() throws {
    let store = makeStore()
    let original = session()
    XCTAssertTrue(store.saveSession(original))
    let firstManager = RecoveryLocationManager()
    let first = CoreLocationActivityRecorder(store: store, manager: firstManager)
    XCTAssertTrue(first.startCollection())
    let firstTime = Date().addingTimeInterval(-1)
    first.locationManager(firstManager, didUpdateLocations: [location(firstTime, latitude: 41.1)])
    first.stopCollection()

    let manager = RecoveryLocationManager()
    let recorder = CoreLocationActivityRecorder(store: store, manager: manager)
    defer { recorder.stopCollection() }
    let recovered = try XCTUnwrap(recorder.recoverActiveSession())
    XCTAssertEqual(recovered.localSessionId, original.localSessionId)
    XCTAssertEqual(recovered.connectionProfileId, original.connectionProfileId)
    XCTAssertEqual(recovered.status, ActiveActivitySessionData.statusRecording)
    XCTAssertNotNil(recovered.resumedAt)
    XCTAssertEqual(manager.startCount, 1)
    recorder.locationManager(manager, didUpdateLocations: [location(Date(), latitude: 41.2)])
    XCTAssertEqual(try store.readPoints().map { $0.segmentIndex }, [0, 1])
  }

  func testPausedAndFailedSessionsStayStoppedWithoutDroppingPoints() throws {
    for status in [ActiveActivitySessionData.statusPaused, ActiveActivitySessionData.statusFailed] {
      let store = makeStore()
      XCTAssertTrue(store.saveSession(session(status)))
      try store.appendPoints([
        RecordedActivityPointData(
          timestamp: IsoTime.nowUtc(), latitude: 41.1, longitude: -8, segmentIndex: 0
        )
      ])
      let manager = RecoveryLocationManager()
      let recorder = CoreLocationActivityRecorder(store: store, manager: manager)
      let recovered = try XCTUnwrap(recorder.recoverActiveSession())
      XCTAssertEqual(recovered.status, ActiveActivitySessionData.statusPaused)
      XCTAssertEqual(recovered.localSessionId, "existing_session")
      XCTAssertEqual(manager.startCount, 0)
      XCTAssertEqual(store.pointCount(), 1)
    }
  }

  func testRecoveryBeforeFirstFixKeepsRecording() throws {
    let store = makeStore()
    XCTAssertTrue(store.saveSession(session()))
    let manager = RecoveryLocationManager()
    let recorder = CoreLocationActivityRecorder(store: store, manager: manager)
    defer { recorder.stopCollection() }

    XCTAssertEqual(recorder.recoverActiveSession()?.status, ActiveActivitySessionData.statusRecording)
    XCTAssertEqual(store.loadSession()?.localSessionId, "existing_session")
    XCTAssertEqual(manager.startCount, 1)
    XCTAssertEqual(store.pointCount(), 0)
  }

  func testDeniedPermissionKeepsTheSessionPausedAndRecoverable() throws {
    let store = makeStore()
    XCTAssertTrue(store.saveSession(session()))
    let manager = RecoveryLocationManager()
    manager.permission = .denied
    let recorder = CoreLocationActivityRecorder(store: store, manager: manager)

    XCTAssertEqual(recorder.recoverActiveSession()?.status, ActiveActivitySessionData.statusPaused)
    XCTAssertEqual(store.loadSession()?.localSessionId, "existing_session")
    XCTAssertEqual(manager.startCount, 0)
  }

  func testFailedRecoveryWriteDoesNotStartCollectionOrErasePoints() throws {
    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    addTeardownBlock { try? FileManager.default.removeItem(at: directory) }
    let store = ActiveActivityStore(activeDirectory: directory)
    XCTAssertTrue(store.saveSession(session()))
    try store.appendPoints([
      RecordedActivityPointData(
        timestamp: IsoTime.nowUtc(), latitude: 41.1, longitude: -8, segmentIndex: 0
      )
    ])
    let sessionFile = directory.appendingPathComponent("session.json")
    try FileManager.default.removeItem(at: sessionFile)
    try FileManager.default.createDirectory(at: sessionFile, withIntermediateDirectories: false)
    let manager = RecoveryLocationManager()
    let recorder = CoreLocationActivityRecorder(store: store, manager: manager)
    XCTAssertEqual(recorder.recoverActiveSession()?.status, ActiveActivitySessionData.statusFailed)
    XCTAssertEqual(manager.startCount, 0)
    XCTAssertEqual(store.pointCount(), 1)
  }
}

private final class RecoveryLocationManager: CLLocationManager {
  var permission = CLAuthorizationStatus.authorizedAlways
  var startCount = 0
  var stopCount = 0
  private var backgroundUpdates = false
  private var backgroundIndicator = false

  override var authorizationStatus: CLAuthorizationStatus { permission }
  override var allowsBackgroundLocationUpdates: Bool {
    get { backgroundUpdates }
    set { backgroundUpdates = newValue }
  }
  override var showsBackgroundLocationIndicator: Bool {
    get { backgroundIndicator }
    set { backgroundIndicator = newValue }
  }
  override func startUpdatingLocation() { startCount += 1 }
  override func stopUpdatingLocation() { stopCount += 1 }
  override func startMonitoringSignificantLocationChanges() {}
  override func stopMonitoringSignificantLocationChanges() {}
  override func requestAlwaysAuthorization() {}
}

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

  func testSessionTimingKeepsPausedElapsedTimeFrozen() {
    let session = ActiveActivitySessionData(
      localSessionId: "activity_1",
      activityType: "run",
      status: ActiveActivitySessionData.statusPaused,
      startedAt: "2026-07-15T10:00:00.000Z",
      resumedAt: "2026-07-15T10:05:00.000Z",
      elapsedDurationSeconds: 300
    )

    let elapsedSeconds = SessionTiming.elapsedSeconds(
      session,
      referenceMillis: IsoTime.toEpochMillis("2026-07-15T11:00:00.000Z")!
    )

    XCTAssertEqual(elapsedSeconds, 300)
  }

  func testSessionTimingAddsOnlyTheCurrentResumedSegment() {
    let session = ActiveActivitySessionData(
      localSessionId: "activity_1",
      activityType: "run",
      status: ActiveActivitySessionData.statusRecording,
      startedAt: "2026-07-15T10:00:00.000Z",
      resumedAt: "2026-07-15T10:10:00.000Z",
      elapsedDurationSeconds: 300
    )

    let elapsedSeconds = SessionTiming.elapsedSeconds(
      session,
      referenceMillis: IsoTime.toEpochMillis("2026-07-15T10:12:00.000Z")!
    )

    XCTAssertEqual(elapsedSeconds, 420)
  }

  func testInterruptedRecoveryKeepsIdentityAndExcludesUnrecordedTime() {
    let session = ActiveActivitySessionData(
      localSessionId: "activity_1",
      activityType: "run",
      status: ActiveActivitySessionData.statusRecording,
      startedAt: "2026-07-15T10:00:00.000Z",
      connectionOrigin: "https://example.test",
      connectionProfileId: "profile_1",
      resumedAt: "2026-07-15T10:10:00.000Z",
      elapsedDurationSeconds: 300,
      currentSegmentIndex: 3
    )
    let nowMillis = IsoTime.toEpochMillis("2026-07-15T10:20:00.000Z")!
    let recovered = SessionTiming.afterInterruption(
      session,
      lastPointMillis: IsoTime.toEpochMillis("2026-07-15T10:12:00.000Z"),
      nowMillis: nowMillis
    )

    XCTAssertEqual(recovered.localSessionId, session.localSessionId)
    XCTAssertEqual(recovered.connectionOrigin, session.connectionOrigin)
    XCTAssertEqual(recovered.connectionProfileId, session.connectionProfileId)
    XCTAssertEqual(recovered.currentSegmentIndex, 3)
    XCTAssertEqual(recovered.resumedAt, "2026-07-15T10:20:00.000Z")
    XCTAssertEqual(recovered.elapsedDurationSeconds, 420)
    XCTAssertEqual(SessionTiming.elapsedSeconds(recovered, referenceMillis: nowMillis + 10_000), 430)
  }

  func testInterruptedRecoveryWithoutPointsDoesNotInventElapsedTime() {
    let session = ActiveActivitySessionData(
      localSessionId: "activity_1",
      activityType: "run",
      status: ActiveActivitySessionData.statusRecording,
      startedAt: "2026-07-15T10:00:00.000Z"
    )
    let recovered = SessionTiming.afterInterruption(
      session,
      lastPointMillis: nil,
      nowMillis: IsoTime.toEpochMillis("2026-07-15T11:00:00.000Z")!
    )

    XCTAssertEqual(recovered.elapsedDurationSeconds, 0)
    XCTAssertEqual(recovered.status, ActiveActivitySessionData.statusRecording)
  }

  func testRecoveryDoesNotResumePausedFailedOrCompletedSessions() {
    let nowMillis = IsoTime.toEpochMillis("2026-07-15T11:00:00.000Z")!
    for status in [
      ActiveActivitySessionData.statusPaused,
      ActiveActivitySessionData.statusFailed,
      ActiveActivitySessionData.statusCompleted,
    ] {
      let session = ActiveActivitySessionData(
        localSessionId: "activity_1",
        activityType: "run",
        status: status,
        startedAt: "2026-07-15T10:00:00.000Z",
        elapsedDurationSeconds: 120
      )
      let recovered = SessionTiming.afterInterruption(
        session,
        lastPointMillis: nil,
        nowMillis: nowMillis
      )
      XCTAssertEqual(recovered.status, status)
      XCTAssertEqual(recovered.elapsedDurationSeconds, 120)
      XCTAssertEqual(SessionTiming.elapsedSeconds(session, referenceMillis: nowMillis), 120)
    }
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
