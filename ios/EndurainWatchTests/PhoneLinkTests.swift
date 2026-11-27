import XCTest

@testable import EndurainWatch

/// The watch's outbox policy: what is resent, when, and that nothing is lost.
/// The store's own behaviour is covered by `HandoffFileStoreTests` in
/// RunnerTests; these pin the schedule the watch app configures it with.
@MainActor
final class PhoneLinkTests: XCTestCase {
    private var directory: URL!
    private var outbox: HandoffFileStore!

    override func setUp() async throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("PhoneLinkTests-\(UUID().uuidString)", isDirectory: true)
        outbox = HandoffFileStore(directory: directory)
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: directory)
    }

    private func due(after seconds: TimeInterval, from now: Date) -> Bool {
        return !outbox.entriesToTransfer(
            at: now.addingTimeInterval(seconds),
            baseDelay: PhoneLink.redeliveryDelay,
            maxDelay: PhoneLink.maxRedeliveryDelay
        ).isEmpty
    }

    func testTheScheduleIsTenMinutesDoublingUpToADay() {
        XCTAssertEqual(PhoneLink.redeliveryDelay, 600)
        XCTAssertEqual(PhoneLink.maxRedeliveryDelay, 86_400)
        XCTAssertEqual(PhoneLink.retryDelay, 60)
        func delay(_ attempts: Int) -> TimeInterval {
            return HandoffFileStore.redeliveryDelay(
                afterAttempts: attempts,
                baseDelay: PhoneLink.redeliveryDelay,
                maxDelay: PhoneLink.maxRedeliveryDelay
            )
        }
        XCTAssertEqual(delay(1), 600)
        XCTAssertEqual(delay(2), 1_200)
        XCTAssertEqual(delay(3), 2_400)
        XCTAssertEqual(delay(20), 86_400)
    }

    func testAFreshWorkoutIsDueAndADeliveredOneWaitsForItsBackoff() throws {
        let now = Date()
        try outbox.save(Data("w".utf8), sessionId: "s")
        XCTAssertTrue(due(after: 0, from: now))

        outbox.markDelivered("s", at: now)
        XCTAssertFalse(due(after: 599, from: now))
        XCTAssertTrue(due(after: 600, from: now))

        outbox.markDelivered("s", at: now)
        XCTAssertFalse(due(after: 1_199, from: now))
        XCTAssertTrue(due(after: 1_200, from: now))
    }

    func testAnUnconfirmedWorkoutIsNeverDropped() throws {
        try outbox.save(Data("w".utf8), sessionId: "s")
        for _ in 0..<30 {
            outbox.markDelivered("s")
        }
        XCTAssertEqual(outbox.data(for: "s"), Data("w".utf8))
    }

    func testEnqueueKeepsTheWorkoutAndCountsItAsWaiting() async throws {
        let link = PhoneLink(outbox: outbox)
        try link.enqueue(Data("w".utf8), sessionId: "queued")

        XCTAssertEqual(outbox.data(for: "queued"), Data("w".utf8))
        // The count is published from a task hopped to the main actor.
        try await Task.sleep(for: .milliseconds(200))
        XCTAssertEqual(link.waitingCount, 1)
    }

    func testEnqueueRejectsAnUnusableSessionId() {
        let link = PhoneLink(outbox: outbox)
        XCTAssertThrowsError(try link.enqueue(Data("w".utf8), sessionId: ""))
        XCTAssertEqual(link.waitingCount, 0)
    }

    func testAnAcknowledgementDropsTheWorkout() throws {
        let link = PhoneLink(outbox: outbox)
        try outbox.save(Data("w".utf8), sessionId: "done")

        link.session(
            .default,
            didReceiveUserInfo: WatchProtocol.acknowledgement(sessionId: "done")
        )

        XCTAssertNil(outbox.data(for: "done"))
    }

    func testTheDefaultStorageDirectoriesAreNamedAsTheyAlwaysWere() {
        XCTAssertEqual(PhoneLink.defaultOutboxDirectory().lastPathComponent, "watch_outbox")
        XCTAssertEqual(
            WorkoutManager.defaultRecordingDirectory().lastPathComponent,
            "watch_recording"
        )
    }
}
