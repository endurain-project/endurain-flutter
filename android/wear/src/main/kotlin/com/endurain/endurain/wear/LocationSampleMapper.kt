package com.endurain.endurain.wear

import com.endurain.endurain.watchlink.WatchRecordedPoint

/**
 * Turns a Health Services location sample into a recorded point.
 *
 * Kept free of Health Services types so it can be unit-tested.
 */
object LocationSampleMapper {
    /** GPS fixes less accurate than this are not recorded. */
    const val MAX_HORIZONTAL_ERROR_METERS = 50.0

    /** A heart rate reading older than this is not attached to a point. */
    const val HEART_RATE_FRESHNESS_MILLIS = 10_000L

    fun point(
        timestampMillis: Long,
        latitude: Double,
        longitude: Double,
        altitude: Double?,
        bearing: Double?,
        horizontalErrorMeters: Double?,
        verticalErrorMeters: Double?,
        segmentIndex: Int,
        lastHeartRate: Pair<Int, Long>?,
    ): WatchRecordedPoint? {
        if (!latitude.isFinite() || !longitude.isFinite()) return null
        if (latitude !in -90.0..90.0 || longitude !in -180.0..180.0) return null
        val horizontal = horizontalErrorMeters?.takeIf { it.isFinite() && it >= 0 }
        if (horizontal != null && horizontal > MAX_HORIZONTAL_ERROR_METERS) return null
        val elevation = altitude?.takeIf { it.isFinite() }
        val heartRate =
            lastHeartRate
                ?.takeIf { (_, at) -> kotlin.math.abs(timestampMillis - at) <= HEART_RATE_FRESHNESS_MILLIS }
                ?.first
        return WatchRecordedPoint(
            timestampMillis = timestampMillis,
            latitude = latitude,
            longitude = longitude,
            segmentIndex = segmentIndex,
            elevationMeters = elevation,
            horizontalAccuracyMeters = horizontal,
            verticalAccuracyMeters =
                verticalErrorMeters?.takeIf { elevation != null && it.isFinite() && it >= 0 },
            headingDegrees = bearing?.takeIf { it.isFinite() && it >= 0 },
            heartRateBpm = heartRate,
        )
    }
}
