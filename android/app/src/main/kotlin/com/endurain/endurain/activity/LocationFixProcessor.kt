package com.endurain.endurain.activity

import android.location.Location
import java.util.Date

/**
 * A platform-independent snapshot of one location fix. Optional readings are
 * `null` when the provider did not report them.
 */
internal data class LocationFix(
    val timeMillis: Long,
    val latitude: Double,
    val longitude: Double,
    val altitudeMeters: Double? = null,
    val accuracyMeters: Float? = null,
    val speedMetersPerSecond: Float? = null,
    val bearingDegrees: Double? = null,
    val verticalAccuracyMeters: Double? = null,
    val bearingAccuracyDegrees: Double? = null,
    val speedAccuracyMetersPerSecond: Double? = null,
) {
    fun toMovementSample() = MovementSample(
        timestampMillis = timeMillis,
        latitude = latitude,
        longitude = longitude,
        speedMetersPerSecond = speedMetersPerSecond?.toDouble(),
        horizontalAccuracyMeters = accuracyMeters?.toDouble(),
    )

    fun toPoint(
        segmentIndex: Int,
        heartRateBpm: Int? = null,
        powerWatts: Int? = null,
        cadenceRpm: Int? = null,
    ) = RecordedActivityPointData(
        timestamp = IsoTime.format(Date(timeMillis)),
        latitude = latitude,
        longitude = longitude,
        segmentIndex = segmentIndex,
        elevationMeters = altitudeMeters,
        horizontalAccuracyMeters = accuracyMeters?.toDouble(),
        verticalAccuracyMeters = verticalAccuracyMeters,
        headingDegrees = bearingDegrees,
        headingAccuracyDegrees = bearingAccuracyDegrees,
        speedMetersPerSecond = speedMetersPerSecond?.toDouble(),
        speedAccuracyMetersPerSecond = speedAccuracyMetersPerSecond,
        heartRateBpm = heartRateBpm,
        powerWatts = powerWatts,
        cadenceRpm = cadenceRpm,
    )

    companion object {
        /**
         * Copies [location], stamping it with the device clock when the
         * provider reported no time.
         */
        fun from(location: Location, nowMillis: Long = System.currentTimeMillis()) = LocationFix(
            timeMillis = if (location.time > 0) location.time else nowMillis,
            latitude = location.latitude,
            longitude = location.longitude,
            altitudeMeters = if (location.hasAltitude()) location.altitude else null,
            accuracyMeters = if (location.hasAccuracy()) location.accuracy else null,
            speedMetersPerSecond = if (location.hasSpeed()) location.speed else null,
            bearingDegrees = if (location.hasBearing()) location.bearing.toDouble() else null,
            verticalAccuracyMeters = if (location.hasVerticalAccuracy()) {
                location.verticalAccuracyMeters.toDouble()
            } else {
                null
            },
            bearingAccuracyDegrees = if (location.hasBearingAccuracy()) {
                location.bearingAccuracyDegrees.toDouble()
            } else {
                null
            },
            speedAccuracyMetersPerSecond = if (location.hasSpeedAccuracy()) {
                location.speedAccuracyMetersPerSecond.toDouble()
            } else {
                null
            },
        )
    }
}

/**
 * Decides whether a fix enters the track and which segment it belongs to.
 *
 * Mirrors the iOS LocationFixPolicy: fixes with a poor horizontal accuracy
 * (e.g. network triangulation "ghost" points) or an impossible speed are
 * dropped, and a pause resume or a long time gap starts a new segment so no
 * false line is bridged. Holds the small amount of state this needs
 * ([lastPointEpochMillis], [resumedFromPause]); not thread-safe, it is used
 * only on the recorder thread.
 */
internal class LocationFixProcessor(
    private val maxAccuracyMeters: Float = MAX_ACCURACY_METERS,
    private val maxSpeedMetersPerSecond: Float = MAX_SPEED_METERS_PER_SECOND,
    private val maxTimeGapMillis: Long = MAX_TIME_GAP_MILLIS,
) {
    /** Timestamp of the last accepted point, or `null` before the first one. */
    var lastPointEpochMillis: Long? = null

    /** Whether the next accepted fix follows a pause and so opens a new segment. */
    var resumedFromPause = false

    /** What happened to a fix. */
    sealed interface Outcome {
        /** The fix failed a quality gate and must not be stored. */
        data object Rejected : Outcome

        /** The fix is stored in [segmentIndex]; [isNewSegment] marks a break. */
        data class Accepted(val segmentIndex: Int, val isNewSegment: Boolean) : Outcome
    }

    /**
     * Gates [fix] and assigns its segment given the session's
     * [currentSegmentIndex]. An accepted fix becomes the new
     * [lastPointEpochMillis]; the caller persists a changed segment index.
     */
    fun process(fix: LocationFix, currentSegmentIndex: Int): Outcome {
        val accuracy = fix.accuracyMeters
        if (accuracy != null && accuracy > maxAccuracyMeters) {
            return Outcome.Rejected
        }
        val nowMillis = fix.timeMillis
        val previous = lastPointEpochMillis
        val speed = fix.speedMetersPerSecond
        if (previous != null && nowMillis > previous && speed != null &&
            speed > maxSpeedMetersPerSecond
        ) {
            return Outcome.Rejected
        }
        var segmentIndex = currentSegmentIndex
        var isNewSegment = false
        if (resumedFromPause) {
            if (previous != null) {
                segmentIndex += 1
                isNewSegment = true
            }
            resumedFromPause = false
        } else if (previous != null && nowMillis - previous > maxTimeGapMillis) {
            segmentIndex += 1
            isNewSegment = true
        }
        lastPointEpochMillis = nowMillis
        return Outcome.Accepted(segmentIndex, isNewSegment)
    }

    companion object {
        // Mirror the iOS LocationFixPolicy constants.
        const val MAX_TIME_GAP_MILLIS = 30_000L
        const val MAX_ACCURACY_METERS = 100f
        const val MAX_SPEED_METERS_PER_SECOND = 90f
    }
}
