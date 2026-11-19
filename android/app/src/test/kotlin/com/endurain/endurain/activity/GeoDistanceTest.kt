package com.endurain.endurain.activity

import org.junit.Assert.assertEquals
import org.junit.Test
import kotlin.math.abs

/**
 * JVM unit tests for [GeoDistance.haversineMeters] against known reference
 * distances, so a formula regression (e.g. a wrong radians conversion) is
 * caught immediately.
 */
class GeoDistanceTest {

    @Test
    fun sameCoordinateIsZeroDistance() {
        val distance = GeoDistance.haversineMeters(38.7169, -9.1399, 38.7169, -9.1399)

        assertEquals(0.0, distance, 0.01)
    }

    @Test
    fun oneDegreeOfLatitudeIsApproximatelyOneHundredElevenKilometers() {
        val distance = GeoDistance.haversineMeters(0.0, 0.0, 1.0, 0.0)

        assertTrueWithinTolerance(111195.0, distance, 500.0)
    }

    @Test
    fun matchesAKnownReferenceDistance() {
        // Lisbon (38.7169, -9.1399) to Porto (41.1579, -8.6291): ~275 km.
        val distance = GeoDistance.haversineMeters(38.7169, -9.1399, 41.1579, -8.6291)

        assertTrueWithinTolerance(275_000.0, distance, 5_000.0)
    }

    private fun assertTrueWithinTolerance(expected: Double, actual: Double, tolerance: Double) {
        if (abs(expected - actual) > tolerance) {
            throw AssertionError("Expected ~$expected within $tolerance but was $actual")
        }
    }
}
