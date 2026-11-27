import CoreLocation
import Flutter
import XCTest

@testable import Runner

@MainActor
final class ActiveSensorRecordingTests: XCTestCase {
  private var directory: URL!
  private var store: ActiveActivityStore!
  private let sessionId = "sensor_session"

  // The async overrides run on the main actor, like this class.
  override func setUp() async throws {
    directory = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    store = ActiveActivityStore(activeDirectory: directory)
    XCTAssertTrue(store.saveSession(ActiveActivitySessionData(
      localSessionId: sessionId,
      activityType: "ride",
      status: ActiveActivitySessionData.statusRecording,
      startedAt: "2026-09-11T10:00:00.000Z"
    )))
  }

  override func tearDown() async throws {
    if FileManager.default.fileExists(atPath: directory.path) {
      try FileManager.default.removeItem(at: directory)
    }
  }

  func testSamplesSurviveAReplacementStoreInstance() throws {
    let samples = [
      RecordedSensorSampleData(kind: "heartRate", timestamp: "2026-09-11T10:00:01.000Z", value: 142),
      RecordedSensorSampleData(kind: "power", timestamp: "2026-09-11T10:00:01.000Z", value: 230),
      RecordedSensorSampleData(kind: "cadence", timestamp: "2026-09-11T10:00:01.000Z", value: 88),
    ]
    for sample in samples {
      try store.appendSensorSample(sample, localSessionId: sessionId)
    }
    let recovered = ActiveActivityStore(activeDirectory: directory)
    XCTAssertEqual(try recovered.readSensorSamples(localSessionId: sessionId), samples)
  }

  func testRejectsSamplesAndReadsForAnotherSession() throws {
    let sample = RecordedSensorSampleData(kind: "heartRate", timestamp: IsoTime.nowUtc(), value: 142)
    XCTAssertThrowsError(try store.appendSensorSample(sample, localSessionId: "other"))
    XCTAssertThrowsError(try store.readSensorSamples(localSessionId: "other"))
    XCTAssertEqual(try store.readSensorSamples(localSessionId: sessionId), [])
  }

  func testPausedSessionRetainsSamplesButRejectsNewWrites() throws {
    let sample = RecordedSensorSampleData(kind: "power", timestamp: IsoTime.nowUtc(), value: 0)
    try store.appendSensorSample(sample, localSessionId: sessionId)
    let session = try XCTUnwrap(store.loadSession())
    XCTAssertTrue(store.saveSession(session.copyWith(status: ActiveActivitySessionData.statusPaused)))
    XCTAssertThrowsError(try store.appendSensorSample(sample, localSessionId: sessionId))
    XCTAssertEqual(try store.readSensorSamples(localSessionId: sessionId), [sample])
  }

  func testAppendAfterTruncatedTailPreservesTheNextSample() throws {
    let sample = RecordedSensorSampleData(kind: "cadence", timestamp: IsoTime.nowUtc(), value: 88)
    try Data("{\"kind\":".utf8).write(to: directory.appendingPathComponent("sensors.jsonl"))
    try store.appendSensorSample(sample, localSessionId: sessionId)
    XCTAssertEqual(try store.readSensorSamples(localSessionId: sessionId), [sample])
  }

  func testDiscardRemovesSamplesAndRejectsLateWrites() throws {
    let sample = RecordedSensorSampleData(kind: "heartRate", timestamp: IsoTime.nowUtc(), value: 142)
    try store.appendSensorSample(sample, localSessionId: sessionId)
    store.clear()
    XCTAssertThrowsError(try store.appendSensorSample(sample, localSessionId: sessionId))
    XCTAssertFalse(FileManager.default.fileExists(atPath: directory.path))
  }

  func testChannelRoundTripsSamplesAndReportsWriteFailures() throws {
    let channel = ActivityRecorderChannel(store: store)
    let sample = RecordedSensorSampleData(kind: "heartRate", timestamp: IsoTime.nowUtc(), value: 142)
    let append = FlutterMethodCall(methodName: ActivityRecorderChannel.methodAppendSensorSample, arguments: [
      "version": ActivityRecorderChannel.payloadVersion,
      "localSessionId": sessionId,
      "sample": sample.toMap(),
    ])
    var appendReply: Any?
    channel.handle(append) { appendReply = $0 }
    XCTAssertNil(appendReply)
    var drained: Any?
    channel.handle(FlutterMethodCall(
      methodName: ActivityRecorderChannel.methodDrainSensorSamples,
      arguments: ["localSessionId": sessionId]
    )) { drained = $0 }
    let payloads = try XCTUnwrap(drained as? [[String: Any]])
    XCTAssertEqual(payloads.compactMap(RecordedSensorSampleData.fromJson), [sample])
    let sensorFile = directory.appendingPathComponent("sensors.jsonl")
    try FileManager.default.removeItem(at: sensorFile)
    try FileManager.default.createDirectory(at: sensorFile, withIntermediateDirectories: false)
    channel.handle(append) { appendReply = $0 }
    XCTAssertEqual((appendReply as? FlutterError)?.code, ActivityRecorderChannel.errorStoreWrite)
    XCTAssertEqual(store.loadSession()?.status, ActiveActivitySessionData.statusFailed)
  }

  func testSampleValidationRejectsMalformedValues() {
    let sample = RecordedSensorSampleData(kind: "power", timestamp: IsoTime.nowUtc(), value: 0)
    XCTAssertEqual(RecordedSensorSampleData.fromJson(sample.toMap()), sample)
    for invalid: Any in [-1, true, 1.5, "142"] {
      var payload = sample.toMap()
      payload["value"] = invalid
      XCTAssertNil(RecordedSensorSampleData.fromJson(payload))
    }
    for (key, invalid) in [("schemaVersion", 2 as Any), ("kind", "unknown"), ("t", "invalid")] {
      var payload = sample.toMap()
      payload[key] = invalid
      XCTAssertNil(RecordedSensorSampleData.fromJson(payload))
    }
  }
}

@MainActor
final class ActivityRecorderChannelPersistenceTests: XCTestCase {
  private enum WriteFailure: Error {
    case simulated
  }

  func testStartDoesNotAcknowledgeFailedPersistence() throws {
    try assertFailedWrite(method: ActivityRecorderChannel.methodStart)
  }

  func testPauseDoesNotAcknowledgeFailedPersistence() throws {
    try assertFailedWrite(
      method: ActivityRecorderChannel.methodPause,
      initialStatus: ActiveActivitySessionData.statusRecording
    )
  }

  func testResumeDoesNotStartCollectionAfterFailedPersistence() throws {
    try assertFailedWrite(
      method: ActivityRecorderChannel.methodResume,
      initialStatus: ActiveActivitySessionData.statusPaused
    )
  }

  func testStopDoesNotAcknowledgeFailedPersistence() throws {
    try assertFailedWrite(
      method: ActivityRecorderChannel.methodStop,
      initialStatus: ActiveActivitySessionData.statusRecording
    )
  }

  func testDiscardRetainsTheRecordingAndReportsDeletionFailure() throws {
    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    addTeardownBlock { try? FileManager.default.removeItem(at: directory) }
    var failDeletion = true
    let store = ActiveActivityStore(
      activeDirectory: directory,
      directoryRemover: { url in
        if failDeletion {
          throw WriteFailure.simulated
        }
        try FileManager.default.removeItem(at: url)
      }
    )
    XCTAssertTrue(store.saveSession(ActiveActivitySessionData(
      localSessionId: "retained_session",
      activityType: "run",
      status: ActiveActivitySessionData.statusRecording,
      startedAt: IsoTime.nowUtc()
    )))
    let sample = RecordedSensorSampleData(kind: "heartRate", timestamp: IsoTime.nowUtc(), value: 142)
    try store.appendSensorSample(sample, localSessionId: "retained_session")
    let channel = ActivityRecorderChannel(store: store)
    defer { _ = channel.onCancel(withArguments: nil) }
    var events: [String] = []
    _ = channel.onListen(withArguments: nil) { payload in
      if let event = payload as? [String: Any], let type = event["type"] as? String {
        events.append(type)
      }
    }
    let discard = FlutterMethodCall(methodName: ActivityRecorderChannel.methodDiscard, arguments: nil)
    var reply: Any?
    channel.handle(discard) { reply = $0 }
    XCTAssertEqual((reply as? FlutterError)?.code, ActivityRecorderChannel.errorStoreWrite)
    XCTAssertEqual(events, [ActivityRecorderCoordinator.eventFailed])
    XCTAssertEqual(try store.readSensorSamples(localSessionId: "retained_session"), [sample])
    failDeletion = false
    channel.handle(discard) { reply = $0 }
    XCTAssertNil(reply)
    XCTAssertFalse(store.hasRecoverableData())
    XCTAssertEqual(events.last, ActivityRecorderCoordinator.eventRecoverableStateChanged)
  }

  private func assertFailedWrite(method: String, initialStatus: String? = nil) throws {
    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    addTeardownBlock { try? FileManager.default.removeItem(at: directory) }
    var failWrites = false
    let store = ActiveActivityStore(activeDirectory: directory, sessionWriter: { data, url in
      if failWrites {
        throw WriteFailure.simulated
      }
      try data.write(to: url, options: .atomic)
    })
    let manager = RecoveryLocationManager()
    let source = FakeLiveLocationSource()
    let recorder = CoreLocationActivityRecorder(store: store, manager: manager, locationSource: source)
    let channel = ActivityRecorderChannel(store: store, recorder: recorder)
    defer {
      recorder.stopCollection()
      _ = channel.onCancel(withArguments: nil)
    }
    if let initialStatus {
      XCTAssertTrue(store.saveSession(ActiveActivitySessionData(
        localSessionId: "write_failure_session",
        activityType: "run",
        status: initialStatus,
        startedAt: IsoTime.nowUtc()
      )))
      try store.appendPoints([
        RecordedActivityPointData(
          timestamp: IsoTime.nowUtc(), latitude: 41.1, longitude: -8, segmentIndex: 0
        )
      ])
      if initialStatus == ActiveActivitySessionData.statusRecording {
        XCTAssertTrue(recorder.startCollection())
      }
    }
    let startsBeforeCommand = source.startCount
    var events: [[String: Any]] = []
    _ = channel.onListen(withArguments: nil) { payload in
      if let event = payload as? [String: Any] {
        events.append(event)
      }
    }
    failWrites = true
    var replies = 0
    var reply: Any?

    channel.handle(FlutterMethodCall(methodName: method, arguments: [
      "version": ActivityRecorderChannel.payloadVersion,
      "localSessionId": "write_failure_session",
      "activityType": "run",
    ])) { value in
      replies += 1
      reply = value
    }

    XCTAssertEqual(replies, 1)
    XCTAssertEqual((reply as? FlutterError)?.code, ActivityRecorderChannel.errorStoreWrite)
    XCTAssertEqual(source.startCount, startsBeforeCommand)
    XCTAssertEqual(store.loadSession()?.status, initialStatus)
    XCTAssertEqual(store.pointCount(), initialStatus == nil ? 0 : 1)
    XCTAssertEqual(events.compactMap { $0["type"] as? String }, [
      ActivityRecorderCoordinator.eventFailed
    ])
  }
}

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
    let source = FakeLiveLocationSource()
    let recorder = CoreLocationActivityRecorder(store: store, manager: manager, locationSource: source)
    defer { recorder.stopCollection() }
    XCTAssertTrue(recorder.startCollection())
    let firstTime = Date()
    source.deliver([location(firstTime, latitude: 41.1)])

    let recovered = try XCTUnwrap(recorder.recoverActiveSession())
    let again = try XCTUnwrap(recorder.recoverActiveSession())

    XCTAssertEqual(recovered.localSessionId, original.localSessionId)
    XCTAssertEqual(recovered.connectionProfileId, original.connectionProfileId)
    XCTAssertEqual(recovered.status, ActiveActivitySessionData.statusRecording)
    XCTAssertEqual(recovered.startedAt, original.startedAt)
    XCTAssertNil(recovered.resumedAt)
    XCTAssertEqual(again.resumedAt, recovered.resumedAt)
    XCTAssertEqual(source.startCount, 1)
    XCTAssertEqual(source.stopCount, 0)
    source.deliver([location(firstTime.addingTimeInterval(1), latitude: 41.2)]
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
    let firstSource = FakeLiveLocationSource()
    let first = CoreLocationActivityRecorder(store: store, manager: firstManager, locationSource: firstSource)
    XCTAssertTrue(first.startCollection())
    let firstTime = Date().addingTimeInterval(-1)
    firstSource.deliver([location(firstTime, latitude: 41.1)])
    first.stopCollection()

    let manager = RecoveryLocationManager()
    let source = FakeLiveLocationSource()
    let recorder = CoreLocationActivityRecorder(store: store, manager: manager, locationSource: source)
    defer { recorder.stopCollection() }
    let recovered = try XCTUnwrap(recorder.recoverActiveSession())
    XCTAssertEqual(recovered.localSessionId, original.localSessionId)
    XCTAssertEqual(recovered.connectionProfileId, original.connectionProfileId)
    XCTAssertEqual(recovered.status, ActiveActivitySessionData.statusRecording)
    XCTAssertNotNil(recovered.resumedAt)
    XCTAssertEqual(source.startCount, 1)
    source.deliver([location(Date(), latitude: 41.2)])
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
      let source = FakeLiveLocationSource()
      let recorder = CoreLocationActivityRecorder(store: store, manager: manager, locationSource: source)
      let recovered = try XCTUnwrap(recorder.recoverActiveSession())
      XCTAssertEqual(recovered.status, ActiveActivitySessionData.statusPaused)
      XCTAssertEqual(recovered.localSessionId, "existing_session")
      XCTAssertEqual(source.startCount, 0)
      XCTAssertEqual(store.pointCount(), 1)
    }
  }

  func testRecoveryBeforeFirstFixKeepsRecording() throws {
    let store = makeStore()
    XCTAssertTrue(store.saveSession(session()))
    let manager = RecoveryLocationManager()
    let source = FakeLiveLocationSource()
    let recorder = CoreLocationActivityRecorder(store: store, manager: manager, locationSource: source)
    defer { recorder.stopCollection() }

    XCTAssertEqual(recorder.recoverActiveSession()?.status, ActiveActivitySessionData.statusRecording)
    XCTAssertEqual(store.loadSession()?.localSessionId, "existing_session")
    XCTAssertEqual(source.startCount, 1)
    XCTAssertEqual(store.pointCount(), 0)
  }

  func testDeniedPermissionKeepsTheSessionPausedAndRecoverable() throws {
    let store = makeStore()
    XCTAssertTrue(store.saveSession(session()))
    let manager = RecoveryLocationManager()
    let source = FakeLiveLocationSource()
    manager.permission = .denied
    let recorder = CoreLocationActivityRecorder(store: store, manager: manager, locationSource: source)

    XCTAssertEqual(recorder.recoverActiveSession()?.status, ActiveActivitySessionData.statusPaused)
    XCTAssertEqual(store.loadSession()?.localSessionId, "existing_session")
    XCTAssertEqual(source.startCount, 0)
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
    let source = FakeLiveLocationSource()
    let recorder = CoreLocationActivityRecorder(store: store, manager: manager, locationSource: source)
    XCTAssertEqual(recorder.recoverActiveSession()?.status, ActiveActivitySessionData.statusFailed)
    XCTAssertEqual(source.startCount, 0)
    XCTAssertEqual(store.pointCount(), 1)
  }

  func testSegmentWriteFailureDoesNotAppendUncommittedPoints() throws {
    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    addTeardownBlock { try? FileManager.default.removeItem(at: directory) }
    var failWrites = false
    let store = ActiveActivityStore(activeDirectory: directory, sessionWriter: { data, url in
      if failWrites {
        throw CocoaError(.fileWriteOutOfSpace)
      }
      try data.write(to: url, options: .atomic)
    })
    XCTAssertTrue(store.saveSession(session()))
    let manager = RecoveryLocationManager()
    let source = FakeLiveLocationSource()
    let recorder = CoreLocationActivityRecorder(store: store, manager: manager, locationSource: source)
    defer { recorder.stopCollection() }
    XCTAssertTrue(recorder.startCollection())
    let firstTime = Date()
    source.deliver([location(firstTime, latitude: 41.1)])
    failWrites = true
    source.deliver([
      location(firstTime.addingTimeInterval(31), latitude: 41.2)
    ])
    XCTAssertEqual(store.pointCount(), 1)
    XCTAssertEqual(store.loadSession()?.currentSegmentIndex, 0)
    XCTAssertEqual(source.stopCount, 1)
  }

  private func millis(_ date: Date) -> Int64 {
    Int64(date.timeIntervalSince1970 * 1000)
  }

  private func fix(
    _ timestamp: Date,
    latitude: Double = 41.1,
    speed: CLLocationSpeed = 0,
    horizontalAccuracy: CLLocationAccuracy = 5
  ) -> CLLocation {
    CLLocation(
      coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: -8),
      altitude: 100,
      horizontalAccuracy: horizontalAccuracy,
      verticalAccuracy: 5,
      course: -1,
      speed: speed,
      timestamp: timestamp
    )
  }

  func testManualResumeWhileAutoPausedRestartsStillnessAndTimeAnnouncements() throws {
    let store = makeStore()
    let start = Date()
    XCTAssertTrue(store.saveSession(ActiveActivitySessionData(
      localSessionId: "auto_session",
      activityType: "run",
      status: ActiveActivitySessionData.statusRecording,
      startedAt: IsoTime.format(start),
      autoPauseEnabled: true,
      autoPauseDelaySeconds: 5
    )))
    XCTAssertTrue(store.saveAnnouncementState(try XCTUnwrap(
      AnnouncementStateData.fromStartArguments([
        "languageTag": "en-US",
        "enabled": true,
        "intervalUnit": AnnouncementStateData.unitTime,
        "timeIntervalSeconds": 300,
      ])
    )))
    let manager = RecoveryLocationManager()
    let source = FakeLiveLocationSource()
    let recorder = CoreLocationActivityRecorder(store: store, manager: manager, locationSource: source)
    defer { recorder.stopCollection() }
    XCTAssertTrue(recorder.startCollection())
    XCTAssertTrue(recorder.isTimeAnnouncementScheduled)

    source.deliver([
      fix(start.addingTimeInterval(1), speed: 3),
      fix(start.addingTimeInterval(2)),
      fix(start.addingTimeInterval(8)),
    ])
    let autoPaused = try XCTUnwrap(store.loadSession())
    XCTAssertEqual(autoPaused.status, ActiveActivitySessionData.statusPaused)
    XCTAssertTrue(autoPaused.pausedAutomatically)
    XCTAssertFalse(recorder.isTimeAnnouncementScheduled)

    // What `ActivityRecorderChannel.handleResume` persists before resuming.
    let resumeTime = start.addingTimeInterval(20)
    XCTAssertTrue(store.saveSession(autoPaused.copyWith(
      status: ActiveActivitySessionData.statusRecording,
      resumedAt: .some(IsoTime.format(resumeTime)),
      pausedAt: .some(nil),
      pausedAutomatically: false
    )))
    let pointsBeforeResume = store.pointCount()
    XCTAssertTrue(recorder.resumeCollection(nowMillis: millis(resumeTime)))
    XCTAssertTrue(recorder.isTimeAnnouncementScheduled)

    // Still for 1 s since the resume: the movement seen before the
    // auto-pause must not count, or this fix would auto-pause again.
    source.deliver([fix(start.addingTimeInterval(21))])

    XCTAssertEqual(store.loadSession()?.status, ActiveActivitySessionData.statusRecording)
    XCTAssertEqual(store.pointCount(), pointsBeforeResume + 1)
    XCTAssertEqual(try store.readPoints().last?.segmentIndex, 1)
    XCTAssertEqual(source.startCount, 1)
  }

  func testRejectsFixesWithInvalidOrPoorAccuracy() throws {
    let store = makeStore()
    XCTAssertTrue(store.saveSession(session()))
    let manager = RecoveryLocationManager()
    let source = FakeLiveLocationSource()
    let recorder = CoreLocationActivityRecorder(store: store, manager: manager, locationSource: source)
    defer { recorder.stopCollection() }
    XCTAssertTrue(recorder.startCollection())
    let now = Date()

    source.deliver([
      fix(now, horizontalAccuracy: -1),
      fix(now, horizontalAccuracy: 101),
    ])
    XCTAssertEqual(store.pointCount(), 0)

    source.deliver([fix(now, horizontalAccuracy: 100)])
    XCTAssertEqual(store.pointCount(), 1)
  }

  func testRejectsCachedFixesFromBeforeTheCollectionStarted() throws {
    let store = makeStore()
    XCTAssertTrue(store.saveSession(session()))
    let manager = RecoveryLocationManager()
    let source = FakeLiveLocationSource()
    let recorder = CoreLocationActivityRecorder(store: store, manager: manager, locationSource: source)
    defer { recorder.stopCollection() }
    XCTAssertTrue(recorder.startCollection())
    let now = Date()

    source.deliver([
      fix(now.addingTimeInterval(-30), latitude: 40.0),
      fix(now, latitude: 41.1),
    ])

    let points = try store.readPoints()
    XCTAssertEqual(points.map { $0.latitude }, [41.1])
  }

  func testFreshFixPolicy() {
    let start: Int64 = 1_000_000
    // Before the (re)start beyond the tolerance: a cached position.
    XCTAssertFalse(LocationFixPolicy.isFreshFix(
      timestampMillis: start - LocationFixPolicy.staleFixToleranceMillis - 1,
      nowMillis: start, collectionStartedAtMillis: start, isFirstFix: false
    ))
    XCTAssertTrue(LocationFixPolicy.isFreshFix(
      timestampMillis: start - LocationFixPolicy.staleFixToleranceMillis,
      nowMillis: start, collectionStartedAtMillis: start, isFirstFix: true
    ))
    // The first fix must also be recent; later ones may arrive late.
    let old = start + 1_000
    let now = old + LocationFixPolicy.maxFirstFixAgeMillis + 1
    XCTAssertFalse(LocationFixPolicy.isFreshFix(
      timestampMillis: old, nowMillis: now, collectionStartedAtMillis: start, isFirstFix: true
    ))
    XCTAssertTrue(LocationFixPolicy.isFreshFix(
      timestampMillis: old, nowMillis: now, collectionStartedAtMillis: start, isFirstFix: false
    ))
  }

  func testWhenInUseRecordsOnTheLiveUpdateStream() throws {
    let store = makeStore()
    XCTAssertTrue(store.saveSession(session()))
    let manager = RecoveryLocationManager()
    manager.permission = .authorizedWhenInUse
    let source = FakeLiveLocationSource()
    let recorder = CoreLocationActivityRecorder(store: store, manager: manager, locationSource: source)
    defer { recorder.stopCollection() }

    XCTAssertTrue(recorder.startCollection())
    XCTAssertTrue(source.isRunning)
    source.deliver([fix(Date())])
    XCTAssertEqual(store.pointCount(), 1)
  }

  func testDowngradeToWhenInUseKeepsRecording() throws {
    let store = makeStore()
    XCTAssertTrue(store.saveSession(session()))
    let manager = RecoveryLocationManager()
    let source = FakeLiveLocationSource()
    let recorder = CoreLocationActivityRecorder(store: store, manager: manager, locationSource: source)
    defer { recorder.stopCollection() }
    XCTAssertTrue(recorder.startCollection())

    manager.permission = .authorizedWhenInUse
    recorder.locationManagerDidChangeAuthorization(manager)

    XCTAssertEqual(source.stopCount, 0)
    XCTAssertEqual(store.loadSession()?.status, ActiveActivitySessionData.statusRecording)
    source.deliver([fix(Date())])
    XCTAssertEqual(store.pointCount(), 1)
  }

  func testRevokedPermissionStopsTheStreamAndFailsTheSession() throws {
    let store = makeStore()
    XCTAssertTrue(store.saveSession(session()))
    let manager = RecoveryLocationManager()
    let source = FakeLiveLocationSource()
    let recorder = CoreLocationActivityRecorder(store: store, manager: manager, locationSource: source)
    XCTAssertTrue(recorder.startCollection())

    manager.permission = .denied
    recorder.locationManagerDidChangeAuthorization(manager)

    XCTAssertFalse(source.isRunning)
    XCTAssertEqual(store.loadSession()?.status, ActiveActivitySessionData.statusFailed)
  }

  func testDistanceFilterDropsNearbyFixesOnlyWithoutAutoPause() throws {
    for autoPauseEnabled in [false, true] {
      let store = makeStore()
      XCTAssertTrue(store.saveSession(ActiveActivitySessionData(
        localSessionId: "filter_session",
        activityType: "run",
        status: ActiveActivitySessionData.statusRecording,
        startedAt: IsoTime.nowUtc(),
        autoPauseEnabled: autoPauseEnabled,
        autoPauseDelaySeconds: 60
      )))
      let source = FakeLiveLocationSource()
      let recorder = CoreLocationActivityRecorder(
        store: store, manager: RecoveryLocationManager(), locationSource: source
      )
      XCTAssertTrue(recorder.startCollection())
      let now = Date()
      // ~1 m, then ~11 m north of the first fix.
      source.deliver([
        fix(now, latitude: 41.1, speed: 3),
        fix(now.addingTimeInterval(1), latitude: 41.10001, speed: 3),
        fix(now.addingTimeInterval(2), latitude: 41.1001, speed: 3),
      ])
      XCTAssertEqual(store.pointCount(), autoPauseEnabled ? 3 : 2)
      recorder.stopCollection()
    }
  }

  func testStationaryUpdateAutoPausesWithoutFurtherFixes() async throws {
    let store = makeStore()
    XCTAssertTrue(store.saveSession(ActiveActivitySessionData(
      localSessionId: "stationary_session",
      activityType: "run",
      status: ActiveActivitySessionData.statusRecording,
      startedAt: IsoTime.nowUtc(),
      autoPauseEnabled: true,
      autoPauseDelaySeconds: 1
    )))
    let source = FakeLiveLocationSource()
    let recorder = CoreLocationActivityRecorder(
      store: store, manager: RecoveryLocationManager(), locationSource: source
    )
    defer { recorder.stopCollection() }
    XCTAssertTrue(recorder.startCollection())

    source.deliver([fix(Date())], isStationary: true)
    XCTAssertEqual(store.loadSession()?.status, ActiveActivitySessionData.statusRecording)
    try await Task.sleep(nanoseconds: 1_500_000_000)

    let paused = try XCTUnwrap(store.loadSession())
    XCTAssertEqual(paused.status, ActiveActivitySessionData.statusPaused)
    XCTAssertTrue(paused.pausedAutomatically)
    XCTAssertTrue(source.isRunning)
  }

  private func autoPausingSession(delaySeconds: Int) -> ActiveActivitySessionData {
    ActiveActivitySessionData(
      localSessionId: "stationary_session",
      activityType: "run",
      status: ActiveActivitySessionData.statusRecording,
      startedAt: IsoTime.nowUtc(),
      autoPauseEnabled: true,
      autoPauseDelaySeconds: delaySeconds
    )
  }

  func testMovingFixAfterAnOverdueStationaryPauseAutoPausesFirst() throws {
    let store = makeStore()
    XCTAssertTrue(store.saveSession(autoPausingSession(delaySeconds: 60)))
    let source = FakeLiveLocationSource()
    let recorder = CoreLocationActivityRecorder(
      store: store, manager: RecoveryLocationManager(), locationSource: source
    )
    defer { recorder.stopCollection() }
    XCTAssertTrue(recorder.startCollection())
    let start = Date()
    source.deliver([fix(start)], isStationary: true)

    // The app slept through the scheduled pause; movement wakes it later.
    source.deliver([fix(start.addingTimeInterval(120), latitude: 41.2, speed: 3)])

    let paused = try XCTUnwrap(store.loadSession())
    XCTAssertEqual(paused.status, ActiveActivitySessionData.statusPaused)
    XCTAssertTrue(paused.pausedAutomatically)
    // Back-dated to the last movement: the collection start.
    let pausedAtMillis = try XCTUnwrap(IsoTime.toEpochMillis(paused.pausedAt))
    XCTAssertLessThan(pausedAtMillis, millis(start.addingTimeInterval(60)))
    XCTAssertEqual(store.pointCount(), 1)
  }

  func testManualResumeWhileStationaryAutoPausesAgain() async throws {
    let store = makeStore()
    XCTAssertTrue(store.saveSession(autoPausingSession(delaySeconds: 1)))
    let source = FakeLiveLocationSource()
    let recorder = CoreLocationActivityRecorder(
      store: store, manager: RecoveryLocationManager(), locationSource: source
    )
    defer { recorder.stopCollection() }
    XCTAssertTrue(recorder.startCollection())
    source.deliver([fix(Date())], isStationary: true)
    try await Task.sleep(nanoseconds: 1_500_000_000)
    let autoPaused = try XCTUnwrap(store.loadSession())
    XCTAssertTrue(autoPaused.pausedAutomatically)

    // What `ActivityRecorderChannel.handleResume` does; no update follows
    // while the device stays still.
    let resumeTime = Date()
    XCTAssertTrue(store.saveSession(autoPaused.copyWith(
      status: ActiveActivitySessionData.statusRecording,
      resumedAt: .some(IsoTime.format(resumeTime)),
      pausedAt: .some(nil),
      pausedAutomatically: false
    )))
    XCTAssertTrue(recorder.resumeCollection(nowMillis: millis(resumeTime)))
    try await Task.sleep(nanoseconds: 1_500_000_000)

    let pausedAgain = try XCTUnwrap(store.loadSession())
    XCTAssertEqual(pausedAgain.status, ActiveActivitySessionData.statusPaused)
    XCTAssertTrue(pausedAgain.pausedAutomatically)
  }

  func testMovingUpdateCancelsTheStationaryAutoPause() async throws {
    let store = makeStore()
    XCTAssertTrue(store.saveSession(ActiveActivitySessionData(
      localSessionId: "stationary_session",
      activityType: "run",
      status: ActiveActivitySessionData.statusRecording,
      startedAt: IsoTime.nowUtc(),
      autoPauseEnabled: true,
      autoPauseDelaySeconds: 1
    )))
    let source = FakeLiveLocationSource()
    let recorder = CoreLocationActivityRecorder(
      store: store, manager: RecoveryLocationManager(), locationSource: source
    )
    defer { recorder.stopCollection() }
    XCTAssertTrue(recorder.startCollection())

    source.deliver([fix(Date())], isStationary: true)
    source.deliver([fix(Date(), latitude: 41.2, speed: 3)])
    try await Task.sleep(nanoseconds: 1_500_000_000)

    XCTAssertEqual(store.loadSession()?.status, ActiveActivitySessionData.statusRecording)
  }
}

/// Grants location access without touching Core Location.
private final class RecoveryLocationManager: CLLocationManager {
  var permission = CLAuthorizationStatus.authorizedAlways

  override var authorizationStatus: CLAuthorizationStatus { permission }
  override func requestAlwaysAuthorization() {}
}

/// Live location stream the tests push fixes through.
@MainActor
private final class FakeLiveLocationSource: LiveLocationSource {
  private(set) var startCount = 0
  private(set) var stopCount = 0
  private var onUpdate: (@MainActor (LiveLocationUpdate) -> Void)?

  var isRunning: Bool { onUpdate != nil }

  func start(onUpdate: @escaping @MainActor (LiveLocationUpdate) -> Void) {
    guard self.onUpdate == nil else { return }
    startCount += 1
    self.onUpdate = onUpdate
  }

  func stop() {
    guard onUpdate != nil else { return }
    stopCount += 1
    onUpdate = nil
  }

  func deliver(_ locations: [CLLocation], isStationary: Bool = false) {
    for location in locations {
      onUpdate?(LiveLocationUpdate(location: location, isStationary: isStationary))
    }
  }
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
      currentSegmentIndex: 3,
      autoPauseEnabled: true,
      autoPauseDelaySeconds: 15,
      pausedAutomatically: true
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
    XCTAssertEqual(decoded?.autoPauseEnabled, true)
    XCTAssertEqual(decoded?.autoPauseDelaySeconds, 15)
    XCTAssertEqual(decoded?.pausedAutomatically, true)
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
    XCTAssertFalse(session(ActiveActivitySessionData.statusCompleted).isActive)
    XCTAssertFalse(session(ActiveActivitySessionData.statusFailed).isActive)
  }

  func testSessionRequiresLocationMonitoringWhileRecordingOrAutomaticallyPaused() {
    func session(
      _ status: String,
      pausedAutomatically: Bool = false
    ) -> ActiveActivitySessionData {
      ActiveActivitySessionData(
        localSessionId: "activity_1",
        activityType: "run",
        status: status,
        startedAt: "2026-07-15T10:00:00.000Z",
        pausedAutomatically: pausedAutomatically
      )
    }

    XCTAssertTrue(
      session(ActiveActivitySessionData.statusRecording).requiresLocationMonitoring)
    XCTAssertTrue(
      session(
        ActiveActivitySessionData.statusPaused,
        pausedAutomatically: true
      ).requiresLocationMonitoring)
    XCTAssertFalse(
      session(ActiveActivitySessionData.statusPaused).requiresLocationMonitoring)
    XCTAssertFalse(
      session(
        ActiveActivitySessionData.statusCompleted,
        pausedAutomatically: true
      ).requiresLocationMonitoring)
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
