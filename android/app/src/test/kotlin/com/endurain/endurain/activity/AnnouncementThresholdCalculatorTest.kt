package com.endurain.endurain.activity

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
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
        val crossings = AnnouncementThresholdCalculator.crossedThresholds(
            intervalValue = 1000.0,
            previousCumulative = 200.0,
            newCumulative = 900.0,
            lastAnnouncedIndex = 0,
        )

        assertTrue(crossings.isEmpty())
    }

    @Test
    fun crossesTheFirstThresholdWithInterpolationFraction() {
        val crossings = AnnouncementThresholdCalculator.crossedThresholds(
            intervalValue = 1000.0,
            previousCumulative = 900.0,
            newCumulative = 1100.0,
            lastAnnouncedIndex = 0,
        )

        assertEquals(1, crossings.size)
        assertEquals(1, crossings[0].thresholdIndex)
        assertEquals(1000.0, crossings[0].thresholdValue, 0.0001)
        // The threshold falls 100/200 = 0.5 of the way between the samples.
        assertEquals(0.5, crossings[0].interpolationFraction, 0.0001)
    }

    @Test
    fun exactHitOnTheThresholdUsesFractionOne() {
        val crossings = AnnouncementThresholdCalculator.crossedThresholds(
            intervalValue = 1000.0,
            previousCumulative = 500.0,
            newCumulative = 1000.0,
            lastAnnouncedIndex = 0,
        )

        assertEquals(1, crossings.size)
        assertEquals(1.0, crossings[0].interpolationFraction, 0.0001)
    }

    @Test
    fun aGpsGapCanCrossSeveralThresholdsAtOnce() {
        val crossings = AnnouncementThresholdCalculator.crossedThresholds(
            intervalValue = 1000.0,
            previousCumulative = 500.0,
            newCumulative = 3200.0,
            lastAnnouncedIndex = 0,
        )

        assertEquals(listOf(1, 2, 3), crossings.map { it.thresholdIndex })
        // Each threshold's fraction is proportional to where it falls in the
        // 2700-unit span (500 -> 3200).
        assertEquals(
            listOf(500.0 / 2700.0, 1500.0 / 2700.0, 2500.0 / 2700.0),
            crossings.map { it.interpolationFraction },
        )
    }

    @Test
    fun neverReAnnouncesAThresholdAlreadyCovered() {
        val crossings = AnnouncementThresholdCalculator.crossedThresholds(
            intervalValue = 1000.0,
            previousCumulative = 1500.0,
            newCumulative = 1800.0,
            lastAnnouncedIndex = 1,
        )

        assertTrue(crossings.isEmpty())
    }

    @Test
    fun continuesFromTheLastAnnouncedIndexNotFromZero() {
        val crossings = AnnouncementThresholdCalculator.crossedThresholds(
            intervalValue = 1000.0,
            previousCumulative = 4500.0,
            newCumulative = 5100.0,
            lastAnnouncedIndex = 4,
        )

        assertEquals(listOf(5), crossings.map { it.thresholdIndex })
    }

    @Test
    fun nonPositiveIntervalNeverCrosses() {
        val crossings = AnnouncementThresholdCalculator.crossedThresholds(
            intervalValue = 0.0,
            previousCumulative = 0.0,
            newCumulative = 5000.0,
            lastAnnouncedIndex = 0,
        )

        assertTrue(crossings.isEmpty())
    }

    @Test
    fun noMovementNeverCrosses() {
        val crossings = AnnouncementThresholdCalculator.crossedThresholds(
            intervalValue = 1000.0,
            previousCumulative = 500.0,
            newCumulative = 500.0,
            lastAnnouncedIndex = 0,
        )

        assertTrue(crossings.isEmpty())
    }

    @Test
    fun capsCrossingsPerUpdateForAPathologicalJump() {
        val crossings = AnnouncementThresholdCalculator.crossedThresholds(
            intervalValue = 1.0,
            previousCumulative = 0.0,
            newCumulative = 1000.0,
            lastAnnouncedIndex = 0,
            maxCrossingsPerUpdate = 5,
        )

        assertEquals(5, crossings.size)
        assertEquals(listOf(1, 2, 3, 4, 5), crossings.map { it.thresholdIndex })
    }
}
