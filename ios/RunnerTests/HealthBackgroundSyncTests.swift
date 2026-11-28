import HealthKit
import XCTest

@testable import Runner

/// Unit tests for the pure parts of automatic health import on iOS: the
/// changes token's wire form and how HealthKit deliveries group into runs.
@MainActor
final class HealthBackgroundSyncTests: XCTestCase {

  // MARK: - HealthWorkoutChangesToken

  func testTokenKeepsBothAnchorsThroughTheWire() throws {
    let token = HealthWorkoutChangesToken(
      workouts: try HealthWorkoutChangesToken.archive(HKQueryAnchor(fromValue: 42)),
      routes: try HealthWorkoutChangesToken.archive(HKQueryAnchor(fromValue: 7))
    )

    let decoded = try XCTUnwrap(HealthWorkoutChangesToken.decode(try token.encoded()))

    XCTAssertEqual(decoded, token)
    XCTAssertEqual(
      try HealthWorkoutChangesToken.anchor(from: decoded.workouts),
      HKQueryAnchor(fromValue: 42)
    )
  }

  func testTokenWithoutAnchorsReadsFromTheStart() throws {
    let decoded = try XCTUnwrap(
      HealthWorkoutChangesToken.decode(try HealthWorkoutChangesToken().encoded())
    )

    XCTAssertNil(try HealthWorkoutChangesToken.anchor(from: decoded.workouts))
    XCTAssertNil(try HealthWorkoutChangesToken.anchor(from: decoded.routes))
  }

  func testUnreadableTokensAreRejected() throws {
    XCTAssertNil(HealthWorkoutChangesToken.decode("not base64!"))
    XCTAssertNil(HealthWorkoutChangesToken.decode(Data("{}x".utf8).base64EncodedString()))
    let notAnAnchor = HealthWorkoutChangesToken(workouts: Data("anchor".utf8), routes: nil)
    XCTAssertNil(HealthWorkoutChangesToken.decode(try notAnAnchor.encoded()))
  }

  // MARK: - HealthBackgroundRuns

  func testTheFirstDeliveryStartsARun() {
    var runs = HealthBackgroundRuns()
    var completed = 0

    XCTAssertTrue(runs.request { completed += 1 })
    let (completions, startFollowUp) = runs.finish()
    completions.forEach { $0() }

    XCTAssertEqual(completed, 1)
    XCTAssertFalse(startFollowUp)
    XCTAssertFalse(runs.isRunning)
  }

  func testDeliveriesDuringARunWaitForOneFollowUpRun() {
    var runs = HealthBackgroundRuns()
    var completed: [String] = []
    _ = runs.request { completed.append("first") }

    XCTAssertFalse(runs.request { completed.append("second") })
    XCTAssertFalse(runs.request { completed.append("third") })
    let first = runs.finish()
    first.completions.forEach { $0() }

    XCTAssertEqual(completed, ["first"])
    XCTAssertTrue(first.startFollowUp)
    XCTAssertTrue(runs.isRunning)

    let followUp = runs.finish()
    followUp.completions.forEach { $0() }

    XCTAssertEqual(completed, ["first", "second", "third"])
    XCTAssertFalse(followUp.startFollowUp)
    XCTAssertFalse(runs.isRunning)
  }
}
