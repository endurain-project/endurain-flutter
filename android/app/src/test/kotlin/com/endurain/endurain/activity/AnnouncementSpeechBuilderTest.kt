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
        messageTemplate: String =
            "Distance {distance}. Time {duration}. Lap {lapMetric}. Overall {overallMetric}.",
    ) = AnnouncementStateData(
        enabled = true,
        duckOtherAudio = true,
        intervalUnit = AnnouncementStateData.UNIT_DISTANCE,
        distanceIntervalMeters = 1000.0,
        timeIntervalSeconds = 300,
        useImperialUnits = false,
        metric = AnnouncementStateData.METRIC_PACE,
        languageTag = "en-US",
        distanceUnitTemplate = "{value} km",
        metricUnitTemplate = "{value} min/km",
        metricLabel = "Pace",
        messageTemplate = messageTemplate,
    )

    @Test
    fun buildsTheMetricSentenceAtOneKilometer() {
        val text = AnnouncementSpeechBuilder.build(
            metricState(),
            distanceMeters = 1000.0,
            elapsedSeconds = 330, // 5:30
        )

        assertEquals(
            "Distance 1.0 km. Time 5:30. Lap Pace 5:30 min/km. " +
                "Overall Pace 5:30 min/km.",
            text,
        )
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
            metricUnitTemplate = "{value} min/mi",
        )

        val text = AnnouncementSpeechBuilder.build(
            state,
            distanceMeters = 1609.344,
            elapsedSeconds = 480,
        )

        assertEquals(
            "Distance 1.0 mi. Time 8:00. Lap Pace 8:00 min/mi. " +
                "Overall Pace 8:00 min/mi.",
            text,
        )
    }

    @Test
    fun omitsPaceAtZeroDistanceInsteadOfDividingByZero() {
        val text = AnnouncementSpeechBuilder.build(
            metricState(),
            distanceMeters = 0.0,
            elapsedSeconds = 60,
        )

        assertEquals(
            "Distance 0.0 km. Time 1:00. Lap Pace. Overall Pace.",
            text,
        )
    }

    @Test
    fun leavesUnrelatedLocaleTextUntouched() {
        val state = metricState(
            messageTemplate =
                "Distância {distance}. Tempo {duration}. " +
                    "Volta {lapMetric}. Total {overallMetric}.",
        ).copy(
            distanceUnitTemplate = "{value} km",
            metricUnitTemplate = "{value} min/km",
            metricLabel = "Ritmo",
        )

        val text = AnnouncementSpeechBuilder.build(
            state,
            distanceMeters = 2000.0,
            elapsedSeconds = 600,
        )

        assertEquals(
            "Distância 2.0 km. Tempo 10:00. Volta Ritmo 5:00 min/km. " +
                "Total Ritmo 5:00 min/km.",
            text,
        )
    }

    @Test
    fun distinguishesLapPaceFromOverallPace() {
        val state = metricState().copy(
            lastAnnouncementDistanceMeters = 1000.0,
            lastAnnouncementElapsedSeconds = 330,
        )

        val text = AnnouncementSpeechBuilder.build(
            state,
            distanceMeters = 2000.0,
            elapsedSeconds = 630,
        )

        assertEquals(true, text.contains("Lap Pace 5:00 min/km"))
        assertEquals(true, text.contains("Overall Pace 5:15 min/km"))
    }

    @Test
    fun ridesUseLapAndOverallSpeed() {
        val state = metricState().copy(
            metric = AnnouncementStateData.METRIC_SPEED,
            metricUnitTemplate = "{value} km/h",
            metricLabel = "Speed",
            lastAnnouncementDistanceMeters = 5000.0,
            lastAnnouncementElapsedSeconds = 1000,
        )

        val text = AnnouncementSpeechBuilder.build(
            state,
            distanceMeters = 10000.0,
            elapsedSeconds = 1800,
        )

        assertEquals(true, text.contains("Lap Speed 22.5 km/h"))
        assertEquals(true, text.contains("Overall Speed 20.0 km/h"))
    }

    @Test
    fun usesTheLocaleDecimalSeparatorSoEnginesDoNotReadItAsGrouping() {
        val state = metricState(
            messageTemplate = "Distanz {distance}. Zeit {duration}. " +
                "Runde {lapMetric}. Gesamt {overallMetric}.",
        ).copy(
            languageTag = "de-DE",
            metric = AnnouncementStateData.METRIC_SPEED,
            metricUnitTemplate = "{value} km/h",
            metricLabel = "Geschwindigkeit",
        )

        val text = AnnouncementSpeechBuilder.build(
            state,
            distanceMeters = 1500.0,
            elapsedSeconds = 300,
        )

        assertEquals(
            "Distanz 1,5 km. Zeit 5:00. Runde Geschwindigkeit 18,0 km/h. " +
                "Gesamt Geschwindigkeit 18,0 km/h.",
            text,
        )
    }

    @Test
    fun fallsBackToAPointWhenTheLanguageTagIsUnusable() {
        val text = AnnouncementSpeechBuilder.build(
            metricState().copy(languageTag = ""),
            distanceMeters = 1500.0,
            elapsedSeconds = 300,
        )

        assertEquals(true, text.contains("1.5 km"))
    }

    @Test
    fun previewStatesTheConfiguredDistanceMilestone() {
        val text = AnnouncementSpeechBuilder.buildPreview(
            metricState().copy(distanceIntervalMeters = 2000.0),
        )

        // 2 km at the 3 m/s sample speed is 11:07, so 5:34 per km.
        assertEquals(
            "Distance 2.0 km. Time 11:07. Lap Pace 5:34 min/km. " +
                "Overall Pace 5:34 min/km.",
            text,
        )
    }

    @Test
    fun previewStatesTheConfiguredTimeMilestone() {
        val text = AnnouncementSpeechBuilder.buildPreview(
            metricState().copy(
                intervalUnit = AnnouncementStateData.UNIT_TIME,
                timeIntervalSeconds = 600,
            ),
        )

        assertEquals(true, text.contains("Time 10:00"))
        assertEquals(true, text.contains("Distance 1.8 km"))
    }
}
