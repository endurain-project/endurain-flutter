package com.endurain.endurain.activity

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

/**
 * JVM unit tests for [AnnouncementThresholdCalculator], the pure threshold
 * crossing/interpolation math the on-device announcement scheduler depends
 * on. A regression here means an activity either announces the same distance
 * twice or silently skips one, so every edge case (exact hits, GPS gaps that
 * skip multiple thresholds, no movement) is locked down without needing a
 * device.
 */
class AnnouncementThresholdCalculatorTest {

    @Test
    fun noCrossingWhenBelowTheFirstThreshold() {
        val crossing = AnnouncementThresholdCalculator.latestCrossing(
            intervalValue = 1000.0,
            previousCumulative = 200.0,
            newCumulative = 900.0,
            lastAnnouncedIndex = 0,
        )

        assertNull(crossing)
    }

    @Test
    fun crossesTheFirstThresholdWithInterpolationFraction() {
        val crossing = AnnouncementThresholdCalculator.latestCrossing(
            intervalValue = 1000.0,
            previousCumulative = 900.0,
            newCumulative = 1100.0,
            lastAnnouncedIndex = 0,
        )

        assertEquals(1, crossing?.thresholdIndex)
        assertEquals(1000.0, crossing!!.thresholdValue, 0.0001)
        // The threshold falls 100/200 = 0.5 of the way between the samples.
        assertEquals(0.5, crossing.interpolationFraction, 0.0001)
    }

    @Test
    fun exactHitOnTheThresholdUsesFractionOne() {
        val crossing = AnnouncementThresholdCalculator.latestCrossing(
            intervalValue = 1000.0,
            previousCumulative = 500.0,
            newCumulative = 1000.0,
            lastAnnouncedIndex = 0,
        )

        assertEquals(1.0, crossing!!.interpolationFraction, 0.0001)
    }

    @Test
    fun aGpsGapReturnsOnlyTheLatestCrossing() {
        val crossing = AnnouncementThresholdCalculator.latestCrossing(
            intervalValue = 1000.0,
            previousCumulative = 500.0,
            newCumulative = 3200.0,
            lastAnnouncedIndex = 0,
        )

        assertEquals(3, crossing?.thresholdIndex)
        assertEquals(2500.0 / 2700.0, crossing!!.interpolationFraction, 0.0001)
    }

    @Test
    fun neverReAnnouncesAThresholdAlreadyCovered() {
        val crossing = AnnouncementThresholdCalculator.latestCrossing(
            intervalValue = 1000.0,
            previousCumulative = 1500.0,
            newCumulative = 1800.0,
            lastAnnouncedIndex = 1,
        )

        assertNull(crossing)
    }

    @Test
    fun continuesFromTheLastAnnouncedIndexNotFromZero() {
        val crossing = AnnouncementThresholdCalculator.latestCrossing(
            intervalValue = 1000.0,
            previousCumulative = 4500.0,
            newCumulative = 5100.0,
            lastAnnouncedIndex = 4,
        )

        assertEquals(5, crossing?.thresholdIndex)
    }

    @Test
    fun nonPositiveIntervalNeverCrosses() {
        val crossing = AnnouncementThresholdCalculator.latestCrossing(
            intervalValue = 0.0,
            previousCumulative = 0.0,
            newCumulative = 5000.0,
            lastAnnouncedIndex = 0,
        )

        assertNull(crossing)
    }

    @Test
    fun noMovementNeverCrosses() {
        val crossing = AnnouncementThresholdCalculator.latestCrossing(
            intervalValue = 1000.0,
            previousCumulative = 500.0,
            newCumulative = 500.0,
            lastAnnouncedIndex = 0,
        )

        assertNull(crossing)
    }

    @Test
    fun pathologicalJumpReturnsOnlyTheLatestCrossing() {
        val crossing = AnnouncementThresholdCalculator.latestCrossing(
            intervalValue = 1.0,
            previousCumulative = 0.0,
            newCumulative = 1000.0,
            lastAnnouncedIndex = 0,
        )

        assertEquals(1000, crossing?.thresholdIndex)
        assertEquals(1.0, crossing!!.interpolationFraction, 0.0001)
    }
}
