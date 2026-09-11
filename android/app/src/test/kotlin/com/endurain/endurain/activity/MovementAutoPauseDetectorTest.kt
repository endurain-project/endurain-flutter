package com.endurain.endurain.activity

import org.junit.Assert.assertEquals
import org.junit.Test

/**
 * JVM unit tests for [MovementAutoPauseDetector].
 *
 * Mirrors the Dart test suite for
 * `lib/features/activity/services/movement_auto_pause_detector.dart`. A
 * regression here would either fail to auto-pause a stopped recording or
 * (worse) auto-resume when it should not, so every branch of the reliable-
 * movement heuristic and the pause/resume hysteresis is locked down.
 */
class MovementAutoPauseDetectorTest {

    private val baseMillis = 1_700_000_000_000L

    private fun sample(
        second: Int,
        lat: Double = 38.7,
        lon: Double = -9.1,
        speed: Double? = null,
        accuracy: Double? = 5.0,
    ): MovementSample {
        return MovementSample(
            timestampMillis = baseMillis + second * 1_000L,
            latitude = lat,
            longitude = lon,
            speedMetersPerSecond = speed,
            horizontalAccuracyMeters = accuracy,
        )
    }

    // ── onActivePoint: auto-pause ──────────────────────────────────────────

    @Test
    fun disabledConfigNeverAutoPauses() {
        val detector = MovementAutoPauseDetector(
            MovementAutoPauseConfig(enabled = false, pauseDelayMillis = 1_000L),
        )
        detector.reset(baseMillis)

        for (second in 0..10) {
            val transition = detector.onActivePoint(sample(second, speed = 0.0))
            assertEquals(MovementAutoPauseTransition.NONE, transition)
        }
    }

    @Test
    fun autoPausesAfterStillnessPersistsForTheConfiguredDelay() {
        val detector = MovementAutoPauseDetector(
            MovementAutoPauseConfig(enabled = true, pauseDelayMillis = 5_000L),
        )
        detector.reset(baseMillis)

        assertEquals(
            MovementAutoPauseTransition.NONE,
            detector.onActivePoint(sample(1, speed = 0.0)),
        )
        assertEquals(
            MovementAutoPauseTransition.NONE,
            detector.onActivePoint(sample(4, speed = 0.0)),
        )
        assertEquals(
            MovementAutoPauseTransition.AUTO_PAUSE,
            detector.onActivePoint(sample(5, speed = 0.0)),
        )
    }

    @Test
    fun reportedSpeedAboveThresholdResetsTheStillnessTimer() {
        val detector = MovementAutoPauseDetector(
            MovementAutoPauseConfig(enabled = true, pauseDelayMillis = 5_000L),
        )
        detector.reset(baseMillis)

        detector.onActivePoint(sample(4, speed = 0.0))
        // A moving sample just before the delay would have elapsed resets the
        // clock, so five more seconds of stillness are required.
        detector.onActivePoint(sample(4, speed = 2.0))
        assertEquals(
            MovementAutoPauseTransition.NONE,
            detector.onActivePoint(sample(8, speed = 0.0)),
        )
        assertEquals(
            MovementAutoPauseTransition.AUTO_PAUSE,
            detector.onActivePoint(sample(9, speed = 0.0)),
        )
    }

    @Test
    fun unreliableAccuracyIsNeverCountedAsMovement() {
        val detector = MovementAutoPauseDetector(
            MovementAutoPauseConfig(
                enabled = true,
                pauseDelayMillis = 5_000L,
                maxAccuracyMeters = 30.0,
            ),
        )
        detector.reset(baseMillis)

        // A fast-looking but inaccurate fix must not reset the stillness timer.
        detector.onActivePoint(sample(1, speed = 10.0, accuracy = 500.0))
        assertEquals(
            MovementAutoPauseTransition.AUTO_PAUSE,
            detector.onActivePoint(sample(5, speed = 0.0)),
        )
    }

    @Test
    fun displacementDerivedSpeedIsUsedWhenReportedSpeedIsAbsent() {
        val detector = MovementAutoPauseDetector(
            MovementAutoPauseConfig(
                enabled = true,
                pauseDelayMillis = 5_000L,
                movingSpeedThresholdMetersPerSecond = 0.6,
            ),
        )
        detector.reset(baseMillis)

        // ~0.0009 degrees of latitude is roughly 100 meters; moving that far in
        // one second is far above the 0.6 m/s threshold, so the timer resets.
        detector.onActivePoint(sample(0, lat = 38.7, speed = null))
        assertEquals(
            MovementAutoPauseTransition.NONE,
            detector.onActivePoint(sample(1, lat = 38.7009, speed = null)),
        )
        // Two stationary (displacement ~0) fixes after that should reach the
        // configured delay and auto-pause.
        detector.onActivePoint(sample(2, lat = 38.7009, speed = null))
        assertEquals(
            MovementAutoPauseTransition.AUTO_PAUSE,
            detector.onActivePoint(sample(6, lat = 38.7009, speed = null)),
        )
    }

    // ── onAutoPausedPoint: auto-resume ──────────────────────────────────────

    @Test
    fun autoResumesOnlyAfterEnoughConsecutiveMovingSamples() {
        val detector = MovementAutoPauseDetector(
            MovementAutoPauseConfig(
                enabled = true,
                consecutiveMovingSamplesToResume = 3,
            ),
        )
        detector.reset(baseMillis)

        assertEquals(
            MovementAutoPauseTransition.NONE,
            detector.onAutoPausedPoint(sample(1, speed = 2.0)),
        )
        assertEquals(
            MovementAutoPauseTransition.NONE,
            detector.onAutoPausedPoint(sample(2, speed = 2.0)),
        )
        assertEquals(
            MovementAutoPauseTransition.AUTO_RESUME,
            detector.onAutoPausedPoint(sample(3, speed = 2.0)),
        )
    }

    @Test
    fun aSingleStillSampleResetsTheConsecutiveMovingCounter() {
        val detector = MovementAutoPauseDetector(
            MovementAutoPauseConfig(
                enabled = true,
                consecutiveMovingSamplesToResume = 3,
            ),
        )
        detector.reset(baseMillis)

        detector.onAutoPausedPoint(sample(1, speed = 2.0))
        detector.onAutoPausedPoint(sample(2, speed = 2.0))
        // Movement noise briefly drops out; hysteresis must not resume yet.
        detector.onAutoPausedPoint(sample(3, speed = 0.0))
        assertEquals(
            MovementAutoPauseTransition.NONE,
            detector.onAutoPausedPoint(sample(4, speed = 2.0)),
        )
        assertEquals(
            MovementAutoPauseTransition.NONE,
            detector.onAutoPausedPoint(sample(5, speed = 2.0)),
        )
        assertEquals(
            MovementAutoPauseTransition.AUTO_RESUME,
            detector.onAutoPausedPoint(sample(6, speed = 2.0)),
        )
    }

    @Test
    fun resetClearsStillnessAndConsecutiveMovementHistory() {
        val detector = MovementAutoPauseDetector(
            MovementAutoPauseConfig(enabled = true, pauseDelayMillis = 1_000L),
        )
        detector.reset(baseMillis)
        detector.onActivePoint(sample(5, speed = 0.0))

        // A manual pause/resume resets tracking; the next active point must
        // not immediately auto-pause using stale history.
        detector.reset(baseMillis + 100_000L)
        assertEquals(
            MovementAutoPauseTransition.NONE,
            detector.onActivePoint(sample(100, speed = 0.0)),
        )
    }

    // ── haversineMeters ──────────────────────────────────────────────────────

    @Test
    fun haversineMetersIsZeroForIdenticalCoordinates() {
        assertEquals(
            0.0,
            MovementAutoPauseDetector.haversineMeters(38.7, -9.1, 38.7, -9.1),
            0.0001,
        )
    }

    @Test
    fun haversineMetersApproximatesKnownShortDistance() {
        // One arc-minute of latitude is ~1852 meters (a nautical mile).
        val meters = MovementAutoPauseDetector.haversineMeters(0.0, 0.0, 1.0 / 60.0, 0.0)
        assertEquals(1852.0, meters, 5.0)
    }
}
