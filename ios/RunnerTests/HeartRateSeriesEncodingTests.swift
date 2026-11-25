import XCTest

@testable import Runner

/// Unit tests for the wire format of `HeartRateSeriesChannel`: filtering to the
/// requested window, sorting, and flattening into `[startMs, endMs, bpm]`.
final class HeartRateSeriesEncodingTests: XCTestCase {

  private let base = Date(timeIntervalSince1970: 1_800_000_000)

  private func reading(_ startOffset: TimeInterval, _ endOffset: TimeInterval, _ bpm: Double)
    -> HeartRateSeriesReading
  {
    HeartRateSeriesReading(
      start: base.addingTimeInterval(startOffset),
      end: base.addingTimeInterval(endOffset),
      bpm: bpm
    )
  }

  func testEmptyReadingsEncodeToAnEmptyList() {
    XCTAssertEqual(
      HeartRateSeriesEncoding.encode([], windowStart: base, windowEnd: base),
      []
    )
  }

  func testFlattensReadingsIntoMillisecondTriplesSortedByStart() {
    let encoded = HeartRateSeriesEncoding.encode(
      [reading(10, 10, 150), reading(5, 8, 148)],
      windowStart: base,
      windowEnd: base.addingTimeInterval(60)
    )

    let baseMs = base.timeIntervalSince1970 * 1000
    XCTAssertEqual(encoded, [
      baseMs + 5_000, baseMs + 8_000, 148,
      baseMs + 10_000, baseMs + 10_000, 150,
    ])
  }

  func testDropsReadingsOutsideTheWindowButKeepsOnesThatOverlapIt() {
    let encoded = HeartRateSeriesEncoding.encode(
      [
        reading(-20, -10, 90),  // entirely before the window
        reading(-5, 2, 100),  // overlaps the window start
        reading(30, 30, 140),  // inside
        reading(58, 65, 160),  // overlaps the window end
        reading(70, 70, 170),  // entirely after the window
      ],
      windowStart: base,
      windowEnd: base.addingTimeInterval(60)
    )

    XCTAssertEqual(stride(from: 2, to: encoded.count, by: 3).map { encoded[$0] }, [100, 140, 160])
  }
}
