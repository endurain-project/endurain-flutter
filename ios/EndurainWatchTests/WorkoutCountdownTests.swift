import XCTest

@testable import EndurainWatch

@MainActor
final class WorkoutCountdownTests: XCTestCase {
    func testOptionsStartWithNoCountdown() {
        XCTAssertEqual(WorkoutCountdown.options, [0, 3, 5, 10])
        XCTAssertEqual(WorkoutCountdown.options.first, 0)
    }

    func testEveryCountdownLongerThanTheCuesHasASilentLeadIn() {
        XCTAssertEqual(WorkoutCountdown.cueSeconds, 3)
        XCTAssertTrue(WorkoutCountdown.options.contains(WorkoutCountdown.cueSeconds))
        XCTAssertTrue(WorkoutCountdown.options.allSatisfy { $0 >= 0 })
    }

    func testReturnsAtOnceWhenTheEndHasPassed() async {
        let started = Date()
        await WorkoutCountdown.run(until: started.addingTimeInterval(-5))
        XCTAssertLessThan(Date().timeIntervalSince(started), 0.5)
    }

    func testWaitsUntilTheEnd() async {
        let started = Date()
        await WorkoutCountdown.run(until: started.addingTimeInterval(0.5))
        XCTAssertGreaterThanOrEqual(Date().timeIntervalSince(started), 0.45)
    }

    func testReturnsEarlyWhenCancelled() async {
        let started = Date()
        let task = Task { @MainActor in
            await WorkoutCountdown.run(until: started.addingTimeInterval(30))
        }
        try? await Task.sleep(for: .milliseconds(300))
        task.cancel()
        await task.value
        XCTAssertLessThan(Date().timeIntervalSince(started), 5)
    }
}
