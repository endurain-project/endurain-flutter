package com.endurain.endurain.wear

import com.endurain.endurain.watchlink.WatchActivityType
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Test
import java.util.Locale

class LocationSampleMapperTest {
    private fun map(
        latitude: Double = 38.7,
        longitude: Double = -9.1,
        altitude: Double? = 12.0,
        bearing: Double? = 90.0,
        horizontal: Double? = 5.0,
        vertical: Double? = 3.0,
        heartRate: Pair<Int, Long>? = null,
    ) = LocationSampleMapper.point(
        timestampMillis = 100_000,
        latitude = latitude,
        longitude = longitude,
        altitude = altitude,
        bearing = bearing,
        horizontalErrorMeters = horizontal,
        verticalErrorMeters = vertical,
        segmentIndex = 2,
        lastHeartRate = heartRate,
    )

    @Test
    fun mapsAFullSample() {
        val point = map(heartRate = 150 to 95_000)!!
        assertEquals(38.7, point.latitude, 0.0)
        assertEquals(2, point.segmentIndex)
        assertEquals(12.0, point.elevationMeters!!, 0.0)
        assertEquals(5.0, point.horizontalAccuracyMeters!!, 0.0)
        assertEquals(3.0, point.verticalAccuracyMeters!!, 0.0)
        assertEquals(90.0, point.headingDegrees!!, 0.0)
        assertEquals(150, point.heartRateBpm)
    }

    @Test
    fun dropsInaccurateOrInvalidFixes() {
        assertNull(map(horizontal = 80.0))
        assertNull(map(latitude = Double.NaN))
        assertNull(map(longitude = 200.0))
        assertNotNull(map(horizontal = null))
    }

    @Test
    fun dropsUnavailableValues() {
        val point = map(altitude = Double.NaN, bearing = Double.NaN, vertical = 3.0)!!
        assertNull(point.elevationMeters)
        assertNull(point.verticalAccuracyMeters)
        assertNull(point.headingDegrees)
    }

    @Test
    fun attachesOnlyAFreshHeartRate() {
        assertNull(map(heartRate = 150 to 80_000)!!.heartRateBpm)
        assertEquals(150, map(heartRate = 150 to 108_000)!!.heartRateBpm)
    }

    @Test
    fun mapsActivityTypesToExercises() {
        WatchActivityType.entries.forEach { assertNotNull(HealthServicesExerciseGateway.exerciseType(it)) }
    }

    @Test
    fun formatsDurationAndDistance() {
        assertEquals("01:05", WorkoutFormat.duration(65_000))
        assertEquals("1:01:05", WorkoutFormat.duration(3_665_000))
        assertEquals(
            WorkoutFormat.Distance("1,50", imperial = false),
            WorkoutFormat.distance(1500.0, Locale.Builder().setLanguage("pt").setRegion("PT").build()),
        )
        assertEquals(WorkoutFormat.Distance("1.00", imperial = true), WorkoutFormat.distance(1609.344, Locale.US))
    }
}
