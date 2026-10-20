package com.endurain.endurain.activity

import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Test
import java.io.File

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

    @Test
    fun speedlessJitterWithinAccuracyRadiusIsNotMovement() {
        val detector = MovementAutoPauseDetector(
            MovementAutoPauseConfig(enabled = true, pauseDelayMillis = 5_000L),
        )
        detector.reset(baseMillis)

        // ~0.00003 degrees of latitude is ~3 meters: a derived ~3 m/s, but well
        // inside the combined 5 m + 5 m accuracy radius, so it is GPS jitter.
        detector.onActivePoint(sample(0, lat = 38.7, speed = null))
        detector.onActivePoint(sample(1, lat = 38.70003, speed = null))
        detector.onActivePoint(sample(2, lat = 38.7, speed = null))
        assertEquals(
            MovementAutoPauseTransition.AUTO_PAUSE,
            detector.onActivePoint(sample(5, lat = 38.70003, speed = null)),
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

    // ── Shared vectors ──────────────────────────────────────────────────────

    /**
     * Runs the vectors in test/fixtures/movement_auto_pause_vectors.json, which
     * the Dart and Swift detector tests also run, keeping the three
     * implementations in sync.
     */
    @Test
    fun sharedVectorsMatchExpectedTransitions() {
        val cases = JSONObject(findVectorsFile().readText()).getJSONArray("cases")
        for (i in 0 until cases.length()) {
            val spec = cases.getJSONObject(i)
            val name = spec.getString("name")
            val config = spec.getJSONObject("config")
            val detector = MovementAutoPauseDetector(
                MovementAutoPauseConfig(
                    enabled = config.getBoolean("enabled"),
                    pauseDelayMillis = config.getLong("pauseDelaySeconds") * 1_000L,
                    consecutiveMovingSamplesToResume =
                        config.optInt("consecutiveMovingSamplesToResume", 3),
                ),
            )
            detector.reset(baseMillis)
            val steps = spec.getJSONArray("steps")
            for (j in 0 until steps.length()) {
                val step = steps.getJSONObject(j)
                val sample = sample(
                    step.getInt("t"),
                    lat = step.optDouble("lat", 38.7),
                    lon = step.optDouble("lon", -9.1),
                    speed = if (step.has("speed")) step.getDouble("speed") else null,
                    accuracy = step.optDouble("accuracy", 5.0),
                )
                val actual = if (step.getString("mode") == "paused") {
                    detector.onAutoPausedPoint(sample)
                } else {
                    detector.onActivePoint(sample)
                }
                val expected = when (step.getString("expect")) {
                    "autoPause" -> MovementAutoPauseTransition.AUTO_PAUSE
                    "autoResume" -> MovementAutoPauseTransition.AUTO_RESUME
                    else -> MovementAutoPauseTransition.NONE
                }
                assertEquals("$name: step at t=${step.getInt("t")}", expected, actual)
            }
        }
    }

    /** Gradle's working directory is android/app; walk up to the repo root. */
    private fun findVectorsFile(): File {
        var dir: File? = File(System.getProperty("user.dir")!!).absoluteFile
        while (dir != null) {
            val candidate = File(dir, "test/fixtures/movement_auto_pause_vectors.json")
            if (candidate.isFile) {
                return candidate
            }
            dir = dir.parentFile
        }
        throw AssertionError("movement_auto_pause_vectors.json not found")
    }
}
