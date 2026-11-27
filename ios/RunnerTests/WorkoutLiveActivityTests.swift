import Flutter
import XCTest

@testable import Runner

@MainActor
final class WorkoutLiveActivityTests: XCTestCase {
  private let metrics = WorkoutActivityAttributes.Metrics(
    title: "Run",
    distanceLabel: "Distance",
    distanceValue: "5.20 km",
    speedLabel: "Pace",
    speedValue: "5:12 /km",
    pausedLabel: "Paused"
  )

  private func session(
    status: String,
    resumedAt: String? = nil,
    pausedAt: String? = nil,
    elapsedDurationSeconds: Int = 0
  ) -> ActiveActivitySessionData {
    ActiveActivitySessionData(
      localSessionId: "live_session",
      activityType: "run",
      status: status,
      startedAt: "2026-11-27T10:00:00.000Z",
      resumedAt: resumedAt,
      pausedAt: pausedAt,
      elapsedDurationSeconds: elapsedDurationSeconds
    )
  }

  private func date(_ iso: String) throws -> Date {
    let millis = try XCTUnwrap(IsoTime.toEpochMillis(iso))
    return Date(timeIntervalSince1970: Double(millis) / 1000)
  }

  func testRecordingCountsFromTheStartLessNoTimeBeforeTheFirstPause() throws {
    let state = WorkoutLiveActivity.contentState(
      for: session(status: ActiveActivitySessionData.statusRecording),
      metrics: metrics,
      nowMillis: 0
    )

    XCTAssertEqual(state.timerStart, try date("2026-11-27T10:00:00.000Z"))
    XCTAssertNil(state.pausedAt)
    XCTAssertFalse(state.isPaused)
    XCTAssertEqual(state.metrics, metrics)
  }

  func testResumedRecordingCountsOnFromTheTimeRecordedBeforeThePause() throws {
    let state = WorkoutLiveActivity.contentState(
      for: session(
        status: ActiveActivitySessionData.statusRecording,
        resumedAt: "2026-11-27T10:30:00.000Z",
        elapsedDurationSeconds: 600
      ),
      metrics: metrics,
      nowMillis: 0
    )

    // 10 minutes recorded before resuming at 10:30 reads as starting at 10:20.
    XCTAssertEqual(state.timerStart, try date("2026-11-27T10:20:00.000Z"))
    XCTAssertNil(state.pausedAt)
  }

  func testPausedRecordingStopsTheCounterAtTheRecordedTime() throws {
    let state = WorkoutLiveActivity.contentState(
      for: session(
        status: ActiveActivitySessionData.statusPaused,
        pausedAt: "2026-11-27T10:15:00.000Z",
        elapsedDurationSeconds: 900
      ),
      metrics: metrics,
      nowMillis: 0
    )

    let pausedAt = try date("2026-11-27T10:15:00.000Z")
    XCTAssertEqual(state.pausedAt, pausedAt)
    XCTAssertEqual(try XCTUnwrap(state.pausedAt).timeIntervalSince(state.timerStart), 900)
    XCTAssertTrue(state.isPaused)
  }

  func testPausedWithoutAPauseTimeStopsTheCounterNow() {
    let nowMillis: Int64 = 1_800_000_000_000
    let state = WorkoutLiveActivity.contentState(
      for: session(status: ActiveActivitySessionData.statusFailed, elapsedDurationSeconds: 60),
      metrics: metrics,
      nowMillis: nowMillis
    )

    XCTAssertEqual(state.pausedAt, Date(timeIntervalSince1970: 1_800_000_000))
    XCTAssertEqual(state.timerStart, Date(timeIntervalSince1970: 1_800_000_000 - 60))
  }

  func testMetricsReadEveryChannelArgumentAndRejectAMissingOne() {
    let arguments: [String: Any] = [
      "title": "Run",
      "distanceLabel": "Distance",
      "distanceValue": "5.20 km",
      "speedLabel": "Pace",
      "speedValue": "5:12 /km",
      "pausedLabel": "Paused",
    ]
    XCTAssertEqual(WorkoutActivityAttributes.Metrics(channelArguments: arguments), metrics)
    for key in arguments.keys {
      var incomplete = arguments
      incomplete.removeValue(forKey: key)
      XCTAssertNil(WorkoutActivityAttributes.Metrics(channelArguments: incomplete), key)
    }
  }

  func testChannelRejectsInvalidLiveActivityArguments() {
    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    addTeardownBlock { try? FileManager.default.removeItem(at: directory) }
    let channel = ActivityRecorderChannel(store: ActiveActivityStore(activeDirectory: directory))
    var reply: Any?

    channel.handle(FlutterMethodCall(
      methodName: ActivityRecorderChannel.methodUpdateLiveActivity,
      arguments: ["version": ActivityRecorderChannel.payloadVersion, "title": "Run"]
    )) { reply = $0 }

    XCTAssertEqual((reply as? FlutterError)?.code, ActivityRecorderChannel.errorArgs)
  }

  func testStoreReportsSavesAndClears() throws {
    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    addTeardownBlock { try? FileManager.default.removeItem(at: directory) }
    let store = ActiveActivityStore(activeDirectory: directory)
    var changes: [String?] = []
    store.onSessionChange = { changes.append($0?.status) }

    XCTAssertTrue(store.saveSession(session(status: ActiveActivitySessionData.statusRecording)))
    XCTAssertTrue(store.clear())

    XCTAssertEqual(changes, [ActiveActivitySessionData.statusRecording, nil])
  }
}
