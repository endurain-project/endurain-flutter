package com.endurain.endurain.activity

import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.sin
import kotlin.math.sqrt

/**
 * Configuration for [MovementAutoPauseDetector].
 *
 * Mirrors the Dart `MovementAutoPauseConfig`
 * (lib/features/activity/services/movement_auto_pause_detector.dart); keep the
 * two implementations in sync. Dart owns the canonical algorithm doc.
 */
data class MovementAutoPauseConfig(
    val enabled: Boolean = false,
    val pauseDelayMillis: Long = 5_000L,
    val movingSpeedThresholdMetersPerSecond: Double = 0.6,
    val maxAccuracyMeters: Double = 30.0,
    val consecutiveMovingSamplesToResume: Int = 3,
)

/** The result of feeding a sample into [MovementAutoPauseDetector]. */
enum class MovementAutoPauseTransition {
    /** No pause/resume boundary was crossed. */
    NONE,

    /** Stillness has persisted long enough; the caller should auto-pause. */
    AUTO_PAUSE,

    /** Enough consecutive movement was observed while auto-paused; the caller
     * should auto-resume (starting a new track segment). */
    AUTO_RESUME,
}

/**
 * A single location sample as seen by the detector.
 *
 * Deliberately independent of `android.location.Location` so this class (and
 * [MovementAutoPauseDetector]) stay plain JVM units, testable without
 * Robolectric or any Android framework stub.
 */
data class MovementSample(
    val timestampMillis: Long,
    val latitude: Double,
    val longitude: Double,
    val speedMetersPerSecond: Double? = null,
    val horizontalAccuracyMeters: Double? = null,
)

/**
 * Detects when an active recording should auto-pause due to inactivity, and
 * when it should auto-resume once movement is observed again.
 *
 * Mirrors `MovementAutoPauseDetector` in
 * lib/features/activity/services/movement_auto_pause_detector.dart (the Dart
 * geolocator fallback recorder implements the same algorithm); keep the two
 * implementations in sync.
 *
 * The detector combines two signals to decide whether a sample counts as
 * "moving": the fix's own reported speed (when its horizontal accuracy is
 * good), or otherwise the displacement-derived speed between this fix and the
 * last reliable fix (only when both fixes have good accuracy). A fix with poor
 * accuracy and no usable previous fix is never treated as movement, so noisy
 * fixes cannot mask genuine stillness.
 */
class MovementAutoPauseDetector(private val config: MovementAutoPauseConfig) {

    private var lastReliableSample: MovementSample? = null
    private var lastMovementAtMillis: Long? = null
    private var consecutiveMovingSamples = 0

    /**
     * Resets all tracked history. Call this whenever the recording (re)starts
     * or transitions between manual and auto pause/resume, so stale movement
     * history from before the reset can never trigger a spurious transition
     * afterward.
     */
    fun reset(movementAtMillis: Long? = null) {
        lastReliableSample = null
        lastMovementAtMillis = movementAtMillis
        consecutiveMovingSamples = 0
    }

    /**
     * Feeds [sample] while the recording is actively collecting (not paused).
     * Returns [MovementAutoPauseTransition.AUTO_PAUSE] once stillness has
     * persisted for at least [MovementAutoPauseConfig.pauseDelayMillis].
     * No-ops (always returns `NONE`) when auto-pause is disabled.
     */
    fun onActivePoint(sample: MovementSample): MovementAutoPauseTransition {
        if (!config.enabled) {
            return MovementAutoPauseTransition.NONE
        }
        val isMoving = isReliableMovement(sample)
        rememberIfReliable(sample)
        if (isMoving) {
            lastMovementAtMillis = sample.timestampMillis
            return MovementAutoPauseTransition.NONE
        }
        val since = lastMovementAtMillis ?: sample.timestampMillis.also {
            lastMovementAtMillis = it
        }
        val stillForMillis = sample.timestampMillis - since
        return if (stillForMillis >= config.pauseDelayMillis) {
            MovementAutoPauseTransition.AUTO_PAUSE
        } else {
            MovementAutoPauseTransition.NONE
        }
    }

    /**
     * Feeds [sample] while the recording is auto-paused (monitoring continues
     * so movement can be detected without user interaction). Returns
     * [MovementAutoPauseTransition.AUTO_RESUME] once
     * [MovementAutoPauseConfig.consecutiveMovingSamplesToResume] consecutive
     * reliable samples show movement.
     */
    fun onAutoPausedPoint(sample: MovementSample): MovementAutoPauseTransition {
        val isMoving = isReliableMovement(sample)
        rememberIfReliable(sample)
        consecutiveMovingSamples = if (isMoving) consecutiveMovingSamples + 1 else 0
        return if (consecutiveMovingSamples >= config.consecutiveMovingSamplesToResume) {
            consecutiveMovingSamples = 0
            lastMovementAtMillis = sample.timestampMillis
            MovementAutoPauseTransition.AUTO_RESUME
        } else {
            MovementAutoPauseTransition.NONE
        }
    }

    private fun rememberIfReliable(sample: MovementSample) {
        if (hasReliableAccuracy(sample)) {
            lastReliableSample = sample
        }
    }

    private fun hasReliableAccuracy(sample: MovementSample): Boolean {
        val accuracy = sample.horizontalAccuracyMeters ?: return true
        return accuracy <= config.maxAccuracyMeters
    }

    private fun isReliableMovement(sample: MovementSample): Boolean {
        if (!hasReliableAccuracy(sample)) {
            return false
        }
        val reportedSpeed = sample.speedMetersPerSecond
        if (reportedSpeed != null) {
            return reportedSpeed >= config.movingSpeedThresholdMetersPerSecond
        }
        val previous = lastReliableSample ?: return false
        val seconds = (sample.timestampMillis - previous.timestampMillis) / 1000.0
        if (seconds <= 0) {
            return false
        }
        val meters = haversineMeters(
            previous.latitude,
            previous.longitude,
            sample.latitude,
            sample.longitude,
        )
        return (meters / seconds) >= config.movingSpeedThresholdMetersPerSecond
    }

    companion object {
        private const val EARTH_RADIUS_METERS = 6_371_000.0

        /**
         * Great-circle distance in meters between two coordinates.
         *
         * Kept dependency-free (no `android.location.Location.distanceBetween`)
         * so this class is a plain JVM unit, testable without Robolectric.
         * Precision is more than sufficient for the short displacements this
         * detector evaluates.
         */
        fun haversineMeters(lat1: Double, lon1: Double, lat2: Double, lon2: Double): Double {
            val dLat = Math.toRadians(lat2 - lat1)
            val dLon = Math.toRadians(lon2 - lon1)
            val sinHalfLat = sin(dLat / 2)
            val sinHalfLon = sin(dLon / 2)
            val a = sinHalfLat * sinHalfLat +
                cos(Math.toRadians(lat1)) * cos(Math.toRadians(lat2)) * sinHalfLon * sinHalfLon
            val c = 2 * atan2(sqrt(a), sqrt(1 - a))
            return EARTH_RADIUS_METERS * c
        }
    }
}
