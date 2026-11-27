import XCTest

@testable import EndurainWatch

final class WorkoutFormatTests: XCTestCase {
    func testDurationUnderAnHourShowsMinutesAndSeconds() {
        XCTAssertEqual(WorkoutFormat.duration(0), "00:00")
        XCTAssertEqual(WorkoutFormat.duration(65), "01:05")
        XCTAssertEqual(WorkoutFormat.duration(3_599), "59:59")
    }

    func testDurationOfAnHourOrMoreShowsHours() {
        XCTAssertEqual(WorkoutFormat.duration(3_600), "1:00:00")
        XCTAssertEqual(WorkoutFormat.duration(3_725), "1:02:05")
    }

    func testDurationNeverShowsANegativeTime() {
        XCTAssertEqual(WorkoutFormat.duration(-30), "00:00")
    }

    func testDurationDropsFractionsOfASecond() {
        XCTAssertEqual(WorkoutFormat.duration(59.9), "00:59")
    }
}
