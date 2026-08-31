package com.endurain.endurain.activity

import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * JVM unit tests for [AnnouncementStateData] serialization: the durability
 * contract between scheduler callbacks (and across a foreground service
 * restart), so a regression here would silently reset the
 * "already announced" bookkeeping and cause duplicate announcements.
 */
class AnnouncementModelsTest {

    private fun sampleState() = AnnouncementStateData(
        enabled = true,
        duckOtherAudio = false,
        intervalUnit = AnnouncementStateData.UNIT_TIME,
        distanceIntervalMeters = 2500.0,
        timeIntervalSeconds = 600,
        useImperialUnits = true,
        languageTag = "fr-FR",
        distanceUnitTemplate = "{value} mi",
        paceUnitTemplate = "{value} min/mi",
        messageTemplate = "Distance {distance}. Time {duration}. Pace {pace}.",
        cumulativeDistanceMeters = 4321.5,
        lastAnnouncedDistanceIndex = 4,
        lastAnnouncedTimeIndex = 2,
        lastLatitude = 38.7169,
        lastLongitude = -9.1399,
        lastElapsedSeconds = 1234,
    )

    @Test
    fun roundTripsThroughJsonPreservingEveryField() {
        val state = sampleState()

        val decoded = AnnouncementStateData.fromJson(state.toJson())

        assertEquals(state, decoded)
    }

    @Test
    fun isTimeBasedReflectsTheIntervalUnit() {
        assertTrue(sampleState().isTimeBased)
        assertEquals(false, sampleState().copy(intervalUnit = "distance").isTimeBased)
    }

    @Test
    fun fromJsonReturnsNullWithoutALanguageTag() {
        val json = sampleState().toJson()
        json.remove("languageTag")

        assertNull(AnnouncementStateData.fromJson(json))
    }

    @Test
    fun fromJsonToleratesAMissingOptionalLastPoint() {
        val json = sampleState().toJson()
        json.remove("lastLatitude")
        json.remove("lastLongitude")

        val decoded = AnnouncementStateData.fromJson(json)

        assertEquals(null, decoded?.lastLatitude)
        assertEquals(null, decoded?.lastLongitude)
    }

    @Test
    fun fromStartArgumentsParsesTheDartChannelPayload() {
        val args = mapOf<String, Any?>(
            "enabled" to true,
            "duckOtherAudio" to false,
            "intervalUnit" to "distance",
            "distanceIntervalMeters" to 1000.0,
            "timeIntervalSeconds" to 300,
            "useImperialUnits" to false,
            "languageTag" to "en-US",
            "distanceUnitTemplate" to "{value} km",
            "paceUnitTemplate" to "{value} min/km",
            "messageTemplate" to "Distance {distance}. Time {duration}. Pace {pace}.",
        )

        val state = AnnouncementStateData.fromStartArguments(args)

        assertEquals(true, state?.enabled)
        assertEquals(false, state?.duckOtherAudio)
        assertEquals("en-US", state?.languageTag)
        // Progress fields always start clean for a brand-new recording.
        assertEquals(0.0, state?.cumulativeDistanceMeters ?: -1.0, 0.0)
        assertEquals(0, state?.lastAnnouncedDistanceIndex)
    }

    @Test
    fun fromStartArgumentsReturnsNullWithoutArguments() {
        assertNull(AnnouncementStateData.fromStartArguments(null))
    }

    @Test
    fun fromStartArgumentsReturnsNullWithoutALanguageTag() {
        assertNull(AnnouncementStateData.fromStartArguments(mapOf("enabled" to true)))
    }

    @Test
    fun toJsonOmitsAbsentOptionalLastPoint() {
        val json = sampleState().copy(lastLatitude = null, lastLongitude = null).toJson()

        assertEquals(false, json.has("lastLatitude"))
        assertEquals(false, json.has("lastLongitude"))
    }

    @Test
    fun handlesIntegerJsonNumbersForDoubleFields() {
        // org.json may hand back an Int for a whole-number value; the parser
        // must not throw a ClassCastException on that.
        val json = JSONObject()
            .put("enabled", true)
            .put("duckOtherAudio", true)
            .put("intervalUnit", "distance")
            .put("distanceIntervalMeters", 1000)
            .put("timeIntervalSeconds", 300)
            .put("useImperialUnits", false)
            .put("languageTag", "en-US")
            .put("distanceUnitTemplate", "{value} km")
            .put("paceUnitTemplate", "{value} min/km")
            .put("messageTemplate", "{distance} {duration} {pace}")
            .put("cumulativeDistanceMeters", 500)

        val decoded = AnnouncementStateData.fromJson(json)

        assertEquals(1000.0, decoded?.distanceIntervalMeters ?: -1.0, 0.0001)
        assertEquals(500.0, decoded?.cumulativeDistanceMeters ?: -1.0, 0.0001)
    }
}
