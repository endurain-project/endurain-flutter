import XCTest

@testable import Runner

/// Unit tests for `GeoDistance.haversineMeters` against known reference
/// distances, so a formula regression (e.g. a wrong radians conversion) is
/// caught immediately. Mirrors the Android `GeoDistanceTest`.
final class GeoDistanceTests: XCTestCase {

  func testSameCoordinateIsZeroDistance() {
    let distance = GeoDistance.haversineMeters(lat1: 38.7169, lon1: -9.1399, lat2: 38.7169, lon2: -9.1399)

    XCTAssertEqual(distance, 0, accuracy: 0.01)
  }

  func testOneDegreeOfLatitudeIsApproximatelyOneHundredElevenKilometers() {
    let distance = GeoDistance.haversineMeters(lat1: 0, lon1: 0, lat2: 1, lon2: 0)

    XCTAssertEqual(distance, 111_195, accuracy: 500)
  }

  func testMatchesAKnownReferenceDistance() {
    // Lisbon (38.7169, -9.1399) to Porto (41.1579, -8.6291): ~275 km.
    let distance = GeoDistance.haversineMeters(lat1: 38.7169, lon1: -9.1399, lat2: 41.1579, lon2: -8.6291)

    XCTAssertEqual(distance, 275_000, accuracy: 5_000)
  }
}
