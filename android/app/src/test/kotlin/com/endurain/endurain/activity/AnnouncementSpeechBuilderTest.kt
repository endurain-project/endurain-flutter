package com.endurain.endurain.activity

import org.junit.Assert.assertEquals
import org.junit.Test

/**
 * JVM unit tests for [AnnouncementSpeechBuilder], the pure text formatting
 * that turns a threshold crossing into the exact sentence [AudioAnnouncer]
 * speaks. Locked down because a template/placeholder mismatch here would
 * silently speak garbage (a literal `{value}`) instead of failing loudly.
 */
class AnnouncementSpeechBuilderTest {

    private fun metricState(
        messageTemplate: String = "Distance {distance}. Time {duration}. Pace {pace}.",
    ) = AnnouncementStateData(
        enabled = true,
        duckOtherAudio = true,
        intervalUnit = AnnouncementStateData.UNIT_DISTANCE,
        distanceIntervalMeters = 1000.0,
        timeIntervalSeconds = 300,
        useImperialUnits = false,
        languageTag = "en-US",
        distanceUnitTemplate = "{value} km",
        paceUnitTemplate = "{value} min/km",
        messageTemplate = messageTemplate,
    )

    @Test
    fun buildsTheMetricSentenceAtOneKilometer() {
        val text = AnnouncementSpeechBuilder.build(
            metricState(),
            distanceMeters = 1000.0,
            elapsedSeconds = 330, // 5:30
        )

        assertEquals("Distance 1.0 km. Time 5:30. Pace 5:30 min/km.", text)
    }

    @Test
    fun formatsElapsedTimeWithHoursOnceAnHourHasPassed() {
        val text = AnnouncementSpeechBuilder.build(
            metricState(),
            distanceMeters = 10000.0,
            elapsedSeconds = 3661, // 1:01:01
        )

        assertEquals(true, text.contains("1:01:01"))
    }

    @Test
    fun convertsToMilesWhenImperial() {
        val state = metricState().copy(
            useImperialUnits = true,
            distanceUnitTemplate = "{value} mi",
            paceUnitTemplate = "{value} min/mi",
        )

        val text = AnnouncementSpeechBuilder.build(
            state,
            distanceMeters = 1609.344,
            elapsedSeconds = 480,
        )

        assertEquals("Distance 1.0 mi. Time 8:00. Pace 8:00 min/mi.", text)
    }

    @Test
    fun omitsPaceAtZeroDistanceInsteadOfDividingByZero() {
        val text = AnnouncementSpeechBuilder.build(
            metricState(),
            distanceMeters = 0.0,
            elapsedSeconds = 60,
        )

        assertEquals("Distance 0.0 km. Time 1:00. Pace .", text)
    }

    @Test
    fun leavesUnrelatedLocaleTextUntouched() {
        val state = metricState(
            messageTemplate = "Distância {distance}. Tempo {duration}. Ritmo {pace}.",
        ).copy(distanceUnitTemplate = "{value} km", paceUnitTemplate = "{value} min/km")

        val text = AnnouncementSpeechBuilder.build(
            state,
            distanceMeters = 2000.0,
            elapsedSeconds = 600,
        )

        assertEquals("Distância 2.0 km. Tempo 10:00. Ritmo 5:00 min/km.", text)
    }
}
