package com.endurain.endurain.activity

import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.sin
import kotlin.math.sqrt

/**
 * Great-circle distance helper used by the on-device announcement scheduler.
 *
 * Pure math, no Android dependencies, so it is covered by plain JVM unit
 * tests. Mirrors the formula used by the Dart `geo_distance.dart` helper.
 */
object GeoDistance {
    private const val EARTH_RADIUS_METERS = 6371000.0

    /** Distance in meters between two WGS84 coordinates (haversine formula). */
    fun haversineMeters(
        lat1: Double,
        lon1: Double,
        lat2: Double,
        lon2: Double,
    ): Double {
        val dLat = Math.toRadians(lat2 - lat1)
        val dLon = Math.toRadians(lon2 - lon1)
        val radLat1 = Math.toRadians(lat1)
        val radLat2 = Math.toRadians(lat2)

        val a = sin(dLat / 2).let { it * it } +
            cos(radLat1) * cos(radLat2) * sin(dLon / 2).let { it * it }
        val c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return EARTH_RADIUS_METERS * c
    }
}
