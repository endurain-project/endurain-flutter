import Foundation

/// Great-circle distance helper used by the on-device announcement scheduler.
///
/// Pure math, no CoreLocation dependency, so it is covered by plain XCTest
/// unit tests. Mirrors the formula used by the Android `GeoDistance` object
/// and the Dart `geo_distance.dart` helper.
enum GeoDistance {
    private static let earthRadiusMeters = 6_371_000.0

    /// Distance in meters between two WGS84 coordinates (haversine formula).
    static func haversineMeters(
        lat1: Double,
        lon1: Double,
        lat2: Double,
        lon2: Double
    ) -> Double {
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180
        let radLat1 = lat1 * .pi / 180
        let radLat2 = lat2 * .pi / 180

        let sinHalfLat = sin(dLat / 2)
        let sinHalfLon = sin(dLon / 2)
        let a = sinHalfLat * sinHalfLat
            + cos(radLat1) * cos(radLat2) * sinHalfLon * sinHalfLon
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return earthRadiusMeters * c
    }
}
