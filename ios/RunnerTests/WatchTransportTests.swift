import Foundation
import XCTest

@testable import Runner

final class HandoffFileStoreTests: XCTestCase {
    private var directory: URL!
    private var store: HandoffFileStore!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        store = HandoffFileStore(directory: directory)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    func testMissingDirectoryIsAnEmptyStore() throws {
        XCTAssertTrue(try store.entries().isEmpty)
        XCTAssertTrue(store.isEmpty)
    }

    func testSavesAndListsBySessionId() throws {
        try store.save(Data("a".utf8), sessionId: "session-a")
        try store.save(Data("b".utf8), sessionId: "session/b")

        let ids = try store.entries().map { $0.sessionId }
        XCTAssertEqual(Set(ids), ["session-a", "session/b"])
        XCTAssertEqual(store.data(for: "session/b"), Data("b".utf8))
        XCTAssertTrue(try store.entries().allSatisfy { $0.deliveredAt == nil })
    }

    func testSavingTheSameSessionAgainKeepsOneCopy() throws {
        try store.save(Data("first".utf8), sessionId: "s")
        store.markDelivered("s")
        try store.save(Data("second".utf8), sessionId: "s")

        let entries = try store.entries()
        XCTAssertEqual(entries.count, 1)
        XCTAssertNil(entries[0].deliveredAt)
        XCTAssertEqual(store.data(for: "s"), Data("second".utf8))
    }

    func testFileNamesAreInjective() throws {
        // Ids that a lossy encoding (dropping or replacing characters) would
        // merge into one file.
        let ids = ["a_b", "a/b", "a b", "a.b", "a:b", "ä"]
        for id in ids {
            try store.save(Data(id.utf8), sessionId: id)
        }
        XCTAssertEqual(Set(try store.entries().map { $0.sessionId }), Set(ids))
        for id in ids {
            XCTAssertEqual(store.data(for: id), Data(id.utf8))
        }
    }

    func testRejectsUnusableSessionIds() {
        XCTAssertThrowsError(try store.save(Data(), sessionId: ""))
        let tooLong = String(repeating: "x", count: HandoffFileStore.maxSessionIdBytes + 1)
        XCTAssertThrowsError(try store.save(Data(), sessionId: tooLong))
    }

    func testMarkDeliveredKeepsTheEntry() throws {
        try store.save(Data("a".utf8), sessionId: "s")
        let deliveredAt = Date(timeIntervalSince1970: 1_800_000_000)
        store.markDelivered("s", at: deliveredAt)

        let entry = try XCTUnwrap(store.entry(for: "s"))
        XCTAssertEqual(
            try XCTUnwrap(entry.deliveredAt).timeIntervalSince1970,
            deliveredAt.timeIntervalSince1970,
            accuracy: 1
        )
        XCTAssertEqual(store.data(for: "s"), Data("a".utf8))
    }

    func testRemoveDropsPendingAndDeliveredCopies() throws {
        try store.save(Data("a".utf8), sessionId: "pending")
        try store.save(Data("b".utf8), sessionId: "delivered")
        store.markDelivered("delivered")

        store.remove("pending")
        store.remove("delivered")

        XCTAssertTrue(store.isEmpty)
    }

    func testPruneDropsOnlyOldDeliveredEntries() throws {
        let now = Date()
        try store.save(Data(), sessionId: "old")
        try store.save(Data(), sessionId: "recent")
        try store.save(Data(), sessionId: "pending")
        store.markDelivered("old", at: now.addingTimeInterval(-40 * 24 * 3600))
        store.markDelivered("recent", at: now.addingTimeInterval(-3600))

        store.pruneDelivered(olderThan: now.addingTimeInterval(-30 * 24 * 3600))

        XCTAssertEqual(Set(try store.entries().map { $0.sessionId }), ["recent", "pending"])
    }

    func testIgnoresForeignFiles() throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data().write(to: directory.appendingPathComponent("notes.txt"))
        try Data().write(to: directory.appendingPathComponent("zz.json"))
        try store.save(Data(), sessionId: "s")

        XCTAssertEqual(try store.entries().map { $0.sessionId }, ["s"])
    }
}

final class WatchRecordingTests: XCTestCase {
    private let start = Date(timeIntervalSince1970: 1_800_000_000)

    func testElapsedSecondsExcludePauses() {
        var recording = WatchRecording(sessionId: "s", activityType: .run, startedAt: start)
        XCTAssertEqual(recording.elapsedSeconds(at: start.addingTimeInterval(60)), 60)

        recording.pause(at: start.addingTimeInterval(60))
        XCTAssertTrue(recording.isPaused)
        XCTAssertEqual(recording.elapsedSeconds(at: start.addingTimeInterval(600)), 60)

        recording.resume(at: start.addingTimeInterval(120))
        XCTAssertEqual(recording.segmentIndex, 1)
        XCTAssertEqual(recording.elapsedSeconds(at: start.addingTimeInterval(150)), 90)
    }

    func testRepeatedPauseOrResumeIsIgnored() {
        var recording = WatchRecording(sessionId: "s", activityType: .ride, startedAt: start)
        recording.resume(at: start.addingTimeInterval(10))
        XCTAssertEqual(recording.segmentIndex, 0)

        recording.pause(at: start.addingTimeInterval(30))
        recording.pause(at: start.addingTimeInterval(50))
        XCTAssertEqual(recording.elapsedSeconds(at: start.addingTimeInterval(100)), 30)
    }

    func testPointRoundTripsThroughJson() throws {
        let point = WatchRecordedPoint(
            timestamp: start,
            latitude: 38.7,
            longitude: -9.1,
            segmentIndex: 2,
            elevationMeters: 12.5,
            horizontalAccuracyMeters: 4,
            verticalAccuracyMeters: 3,
            headingDegrees: 90,
            speedMetersPerSecond: 3.2,
            speedAccuracyMetersPerSecond: 0.5,
            heartRateBpm: 151
        )
        let data = try JSONSerialization.data(withJSONObject: point.jsonObject())
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual(json["t"] as? String, "2027-01-15T08:00:00.000Z")
        XCTAssertEqual(WatchRecordedPoint(json: json), point)
    }

    func testPointRejectsOutOfRangeCoordinates() {
        XCTAssertNil(WatchRecordedPoint(json: ["t": "2027-01-15T08:00:00.000Z", "lat": 91, "lon": 0]))
        XCTAssertNil(WatchRecordedPoint(json: ["t": "2027-01-15T08:00:00.000Z", "lat": 0, "lon": 181]))
        XCTAssertNil(WatchRecordedPoint(json: ["lat": 0, "lon": 0]))
    }
}

final class WatchRecordingStoreTests: XCTestCase {
    private var directory: URL!
    private var store: WatchRecordingStore!
    private let start = Date(timeIntervalSince1970: 1_800_000_000)

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        store = WatchRecordingStore(directory: directory)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    func testNothingToLoadWithoutARecording() {
        XCTAssertNil(store.load())
    }

    func testRestoresTheRecordingAndItsPoints() throws {
        var recording = WatchRecording(sessionId: "s", activityType: .hike, startedAt: start)
        try store.begin(recording)
        try store.append([point(at: 1), point(at: 2)])
        recording.pause(at: start.addingTimeInterval(5))
        try store.update(recording)
        try store.append([point(at: 3)])

        let loaded = try XCTUnwrap(store.load())
        XCTAssertEqual(loaded.recording, recording)
        XCTAssertEqual(loaded.points.map { $0.timestamp }, [1, 2, 3].map { start.addingTimeInterval($0) })
    }

    func testSkipsALineCutShortByACrash() throws {
        try store.begin(WatchRecording(sessionId: "s", activityType: .run, startedAt: start))
        try store.append([point(at: 1)])
        let handle = try FileHandle(forWritingTo: directory.appendingPathComponent("points.jsonl"))
        try handle.seekToEnd()
        try handle.write(contentsOf: Data("{\"t\":\"2027-01-15T08:0".utf8))
        try handle.close()

        XCTAssertEqual(try XCTUnwrap(store.load()).points.count, 1)
    }

    func testBeginDiscardsThePreviousRecording() throws {
        try store.begin(WatchRecording(sessionId: "old", activityType: .run, startedAt: start))
        try store.append([point(at: 1)])
        try store.begin(WatchRecording(sessionId: "new", activityType: .walk, startedAt: start))

        let loaded = try XCTUnwrap(store.load())
        XCTAssertEqual(loaded.recording.sessionId, "new")
        XCTAssertTrue(loaded.points.isEmpty)
    }

    func testClearRemovesEverything() throws {
        try store.begin(WatchRecording(sessionId: "s", activityType: .run, startedAt: start))
        store.clear()
        XCTAssertNil(store.load())
    }

    private func point(at seconds: TimeInterval) -> WatchRecordedPoint {
        return WatchRecordedPoint(
            timestamp: start.addingTimeInterval(seconds),
            latitude: 38.7,
            longitude: -9.1,
            segmentIndex: 0
        )
    }
}

final class WatchHandoffBuilderTests: XCTestCase {
    private let start = Date(timeIntervalSince1970: 1_800_000_000)

    func testBuildsTheEnvelopeDartReads() throws {
        var recording = WatchRecording(sessionId: "B7E2", activityType: .ride, startedAt: start)
        recording.pause(at: start.addingTimeInterval(30))
        recording.resume(at: start.addingTimeInterval(60))
        let points = [
            WatchRecordedPoint(timestamp: start.addingTimeInterval(70), latitude: 1, longitude: 2, segmentIndex: 1),
            WatchRecordedPoint(timestamp: start.addingTimeInterval(10), latitude: 3, longitude: 4, segmentIndex: 0),
        ]

        let data = try WatchHandoffBuilder.data(
            recording: recording,
            points: points,
            endedAt: start.addingTimeInterval(90),
            elapsedSeconds: 59.6,
            healthWorkoutId: "HK-UUID"
        )
        let envelope = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual(envelope["version"] as? Int, 1)
        XCTAssertEqual(envelope["source"] as? String, "appleWatch")
        XCTAssertEqual(envelope["healthWorkoutId"] as? String, "HK-UUID")
        let session = try XCTUnwrap(envelope["session"] as? [String: Any])
        XCTAssertEqual(session["schemaVersion"] as? Int, 3)
        XCTAssertEqual(session["localSessionId"] as? String, "B7E2")
        XCTAssertEqual(session["activityType"] as? String, "ride")
        XCTAssertEqual(session["status"] as? String, "completed")
        XCTAssertEqual(session["startedAt"] as? String, "2027-01-15T08:00:00.000Z")
        XCTAssertEqual(session["endedAt"] as? String, "2027-01-15T08:01:30.000Z")
        XCTAssertEqual(session["elapsedDurationSeconds"] as? Int, 60)
        XCTAssertEqual(session["currentSegmentIndex"] as? Int, 1)
        let encodedPoints = try XCTUnwrap(envelope["points"] as? [[String: Any]])
        XCTAssertEqual(encodedPoints.map { $0["seg"] as? Int }, [0, 1], "points are sorted by time")
    }

    func testOmitsAMissingHealthWorkoutId() {
        let envelope = WatchHandoffBuilder.envelope(
            recording: WatchRecording(sessionId: "s", activityType: .run, startedAt: start),
            points: [],
            endedAt: start,
            elapsedSeconds: 0,
            healthWorkoutId: ""
        )
        XCTAssertNil(envelope["healthWorkoutId"])
    }

    func testAnInterruptedRecordingEndsAtItsLastPoint() {
        let recording = WatchRecording(sessionId: "s", activityType: .run, startedAt: start)
        XCTAssertEqual(WatchHandoffBuilder.endOfInterruptedRecording(recording, points: []), start)
        let points = [30, 90, 60].map {
            WatchRecordedPoint(timestamp: start.addingTimeInterval($0), latitude: 0, longitude: 0, segmentIndex: 0)
        }
        XCTAssertEqual(
            WatchHandoffBuilder.endOfInterruptedRecording(recording, points: points),
            start.addingTimeInterval(90)
        )
    }
}

final class WatchProtocolTests: XCTestCase {
    func testAcknowledgementRoundTrips() {
        let ack = WatchProtocol.acknowledgement(sessionId: "s1")
        XCTAssertEqual(WatchProtocol.acknowledgedSessionId(in: ack), "s1")
        XCTAssertNil(WatchProtocol.acknowledgedSessionId(in: WatchProtocol.handoffMetadata(sessionId: "s1")))
        XCTAssertNil(WatchProtocol.acknowledgedSessionId(in: ["kind": "ack", "sessionId": ""]))
    }

    func testLinkStatusMapping() {
        func status(
            supported: Bool = true,
            activated: Bool = true,
            paired: Bool = true,
            installed: Bool = true,
            reachable: Bool = true
        ) -> String {
            return WatchLinkState.status(
                isSupported: supported,
                isActivated: activated,
                isPaired: paired,
                isWatchAppInstalled: installed,
                isReachable: reachable
            )
        }
        XCTAssertEqual(status(supported: false), "unsupported")
        XCTAssertEqual(status(activated: false), "unavailable")
        XCTAssertEqual(status(paired: false), "unpaired")
        XCTAssertEqual(status(installed: false), "appNotInstalled")
        XCTAssertEqual(status(reachable: false), "disconnected")
        XCTAssertEqual(status(), "connected")
    }
}

final class WatchConnectivityBridgeTests: XCTestCase {
    private var directory: URL!
    private var defaults: UserDefaults!
    private var suiteName: String!
    private var bridge: WatchConnectivityBridge!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        suiteName = "watch-bridge-\(UUID().uuidString)"
        defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        bridge = WatchConnectivityBridge(
            inbox: HandoffFileStore(directory: directory.appendingPathComponent("inbox")),
            defaults: defaults
        )
    }

    override func tearDownWithError() throws {
        defaults.removePersistentDomain(forName: suiteName)
        try? FileManager.default.removeItem(at: directory)
    }

    func testStoresAReceivedFileUnderTheMetadataSessionId() throws {
        let file = try write(envelope(sessionId: "from-body"))

        XCTAssertTrue(bridge.storeReceivedHandoff(
            fileURL: file,
            metadata: WatchProtocol.handoffMetadata(sessionId: "from-metadata")
        ))
        XCTAssertEqual(try bridge.inbox.entries().map { $0.sessionId }, ["from-metadata"])
    }

    func testFallsBackToTheSessionIdInTheEnvelope() throws {
        let file = try write(envelope(sessionId: "from-body"))

        XCTAssertTrue(bridge.storeReceivedHandoff(fileURL: file, metadata: nil))
        XCTAssertEqual(try bridge.inbox.entries().map { $0.sessionId }, ["from-body"])
    }

    func testDropsAFileWithoutASessionId() throws {
        let file = try write(Data("not json".utf8))

        XCTAssertFalse(bridge.storeReceivedHandoff(fileURL: file, metadata: [:]))
        XCTAssertTrue(bridge.inbox.isEmpty)
    }

    func testAcknowledgeRemovesTheSessionAndQueuesTheAcknowledgement() throws {
        try bridge.inbox.save(envelope(sessionId: "s"), sessionId: "s")

        bridge.acknowledge(sessionId: "s")
        bridge.acknowledge(sessionId: "s")

        XCTAssertTrue(bridge.inbox.isEmpty)
        // The simulator has no paired watch, so the acknowledgement stays
        // queued (once) for when one is.
        XCTAssertEqual(bridge.pendingAcknowledgements(), ["s"])
    }

    func testReadInboxReturnsReadableEnvelopesOnly() throws {
        try bridge.inbox.save(envelope(sessionId: "good"), sessionId: "good")
        try bridge.inbox.save(Data("{broken".utf8), sessionId: "broken")

        let handoffs = try WatchTransportChannel.readInbox(bridge.inbox).get()

        XCTAssertEqual(handoffs.count, 1)
        let session = try XCTUnwrap(handoffs.first?["session"] as? [String: Any])
        XCTAssertEqual(session["localSessionId"] as? String, "good")
        // The unreadable one stays for a later app version.
        XCTAssertEqual(try bridge.inbox.entries().count, 2)
    }

    private func envelope(sessionId: String) -> Data {
        let recording = WatchRecording(
            sessionId: sessionId,
            activityType: .run,
            startedAt: Date(timeIntervalSince1970: 1_800_000_000)
        )
        return try! WatchHandoffBuilder.data(
            recording: recording,
            points: [],
            endedAt: recording.startedAt,
            elapsedSeconds: 0,
            healthWorkoutId: nil
        )
    }

    private func write(_ data: Data) throws -> URL {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent(UUID().uuidString)
        try data.write(to: url)
        return url
    }
}
