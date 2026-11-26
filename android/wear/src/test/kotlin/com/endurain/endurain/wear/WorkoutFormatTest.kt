package com.endurain.endurain.wear

import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File
import java.util.Locale

class WorkoutFormatTest {
    @Test
    fun durationUsesMinutesThenHours() {
        assertEquals("00:00", WorkoutFormat.duration(0))
        assertEquals("00:59", WorkoutFormat.duration(59_999))
        assertEquals("01:05", WorkoutFormat.duration(65_000))
        assertEquals("1:01:01", WorkoutFormat.duration(3_661_000))
    }

    @Test
    fun durationClampsNegativeValues() {
        assertEquals("00:00", WorkoutFormat.duration(-5_000))
    }

    @Test
    fun distanceIsKilometresOutsideImperialRegions() {
        val distance = WorkoutFormat.distance(1500.0, Locale.GERMANY)
        assertFalse(distance.imperial)
        assertEquals("1,50", distance.value)
    }

    @Test
    fun distanceIsMilesInImperialRegions() {
        val distance = WorkoutFormat.distance(1609.344, Locale.US)
        assertTrue(distance.imperial)
        assertEquals("1.00", distance.value)
    }

    @Test
    fun missingDistanceIsZero() {
        assertEquals("0.00", WorkoutFormat.distance(null, Locale.forLanguageTag("en-AU")).value)
    }

    @Test
    fun imperialRegionsMatchTheSharedFixture() {
        val regions = JSONObject(findFixture().readText()).getJSONArray("regions")
        val fixture = (0 until regions.length()).map { regions.getString(it) }.toSet()
        assertEquals(fixture, WorkoutFormat.IMPERIAL_REGIONS)
    }

    /** Gradle's working directory is android/wear; walk up to the repo root. */
    private fun findFixture(): File {
        var dir: File? = File(System.getProperty("user.dir")!!).absoluteFile
        while (dir != null) {
            val candidate = File(dir, "test/fixtures/imperial_regions.json")
            if (candidate.isFile) return candidate
            dir = dir.parentFile
        }
        throw AssertionError("imperial_regions.json not found")
    }
}
