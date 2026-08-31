package com.endurain.endurain.activity

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * JVM unit tests for [AnnouncementScheduler]: the sequencing that ties the
 * durable [AnnouncementStateData] to [AnnouncementThresholdCalculator] and
 * [AnnouncementSpeechBuilder] for GPS and elapsed-time callbacks. These tests
 * exercise the exact "durable, no duplicates, interpolated" contract the
 * announcement feature depends on:
 * - a threshold is announced exactly once, even across two separate
 *   `onFix` calls (the durable progress carries forward);
 * - a segment break (pause/resume or a GPS gap) never counts as distance
 *   covered;
 * - distance- and time-based intervals both work.
 */
class AnnouncementSchedulerTest {

    private fun baseState(
        intervalUnit: String = AnnouncementStateData.UNIT_DISTANCE,
        distanceIntervalMeters: Double = 1000.0,
        timeIntervalSeconds: Int = 300,
    ) = AnnouncementStateData(
        enabled = true,
        duckOtherAudio = true,
        intervalUnit = intervalUnit,
        distanceIntervalMeters = distanceIntervalMeters,
        timeIntervalSeconds = timeIntervalSeconds,
        useImperialUnits = false,
        languageTag = "en-US",
        distanceUnitTemplate = "{value} km",
        paceUnitTemplate = "{value} min/km",
        messageTemplate = "Distance {distance}. Time {duration}. Pace {pace}.",
    )

    @Test
    fun disabledStateNeverAnnouncesOrAccumulates() {
        val result = AnnouncementScheduler.onFix(
            state = baseState().copy(enabled = false, lastLatitude = 0.0, lastLongitude = 0.0),
            latitude = 0.01,
            longitude = 0.0,
            elapsedSeconds = 100,
            isNewSegment = false,
        )

        assertTrue(result.announcements.isEmpty())
        assertEquals(0.0, result.state.cumulativeDistanceMeters, 0.0)
    }

    @Test
    fun firstFixOnlySeedsWithoutAnnouncing() {
        val result = AnnouncementScheduler.onFix(
            state = baseState(),
            latitude = 38.7169,
            longitude = -9.1399,
            elapsedSeconds = 0,
            isNewSegment = false,
        )

        assertTrue(result.announcements.isEmpty())
        assertEquals(38.7169, result.state.lastLatitude!!, 0.0)
        assertEquals(0.0, result.state.cumulativeDistanceMeters, 0.0)
    }

    @Test
    fun aNewSegmentReseedsWithoutCountingTheGapAsDistance() {
        val seeded = baseState().copy(
            lastLatitude = 0.0,
            lastLongitude = 0.0,
            lastElapsedSeconds = 10,
            cumulativeDistanceMeters = 500.0,
        )

        val result = AnnouncementScheduler.onFix(
            state = seeded,
            // Far away, as if the recording paused here and resumed elsewhere.
            latitude = 10.0,
            longitude = 10.0,
            elapsedSeconds = 400,
            isNewSegment = true,
        )

        assertTrue(result.announcements.isEmpty())
        // Distance accumulated before the break is preserved; the gap itself
        // adds nothing.
        assertEquals(500.0, result.state.cumulativeDistanceMeters, 0.0)
        assertEquals(10.0, result.state.lastLatitude!!, 0.0)
    }

    @Test
    fun announcesOnceWhenCrossingADistanceThreshold() {
        // 0.009 degrees of longitude at the equator is ~1001m — just over 1km.
        val result = AnnouncementScheduler.onFix(
            state = baseState().copy(lastLatitude = 0.0, lastLongitude = 0.0, lastElapsedSeconds = 0),
            latitude = 0.0,
            longitude = 0.009,
            elapsedSeconds = 300,
            isNewSegment = false,
        )

        assertEquals(1, result.announcements.size)
        assertEquals(1, result.state.lastAnnouncedDistanceIndex)
        assertTrue(result.announcements.single().contains("1.0 km"))
    }

    @Test
    fun neverAnnouncesTheSameThresholdTwiceAcrossCalls() {
        var state = baseState()
        val first = AnnouncementScheduler.onFix(
            state = state,
            latitude = 0.0,
            longitude = 0.0,
            elapsedSeconds = 0,
            isNewSegment = false,
        )
        state = first.state

        val second = AnnouncementScheduler.onFix(
            state = state,
            latitude = 0.0,
            longitude = 0.009, // crosses the 1km threshold
            elapsedSeconds = 300,
            isNewSegment = false,
        )
        state = second.state
        assertEquals(1, second.announcements.size)

        // A further fix that does not cross a new threshold announces nothing,
        // even though cumulative distance is still past the first threshold.
        val third = AnnouncementScheduler.onFix(
            state = state,
            latitude = 0.0,
            longitude = 0.0091,
            elapsedSeconds = 305,
            isNewSegment = false,
        )

        assertTrue(third.announcements.isEmpty())
    }

    @Test
    fun timeBasedIntervalAnnouncesOnElapsedSecondsNotDistance() {
        val result = AnnouncementScheduler.onFix(
            state = baseState(
                intervalUnit = AnnouncementStateData.UNIT_TIME,
                timeIntervalSeconds = 300,
            ).copy(lastLatitude = 0.0, lastLongitude = 0.0, lastElapsedSeconds = 250),
            latitude = 0.0001,
            longitude = 0.0001,
            elapsedSeconds = 320,
            isNewSegment = false,
        )

        assertEquals(1, result.announcements.size)
        assertEquals(1, result.state.lastAnnouncedTimeIndex)
        // Distance-based bookkeeping is untouched by a time-based interval.
        assertEquals(0, result.state.lastAnnouncedDistanceIndex)
    }

    @Test
    fun timeBasedIntervalAdvancesWithoutALocationFix() {
        val state = baseState(
            intervalUnit = AnnouncementStateData.UNIT_TIME,
            timeIntervalSeconds = 300,
        ).copy(
            cumulativeDistanceMeters = 750.0,
            lastElapsedSeconds = 250,
        )

        val result = AnnouncementScheduler.onElapsedTime(
            state = state,
            elapsedSeconds = 300,
        )

        assertEquals(1, result.announcements.size)
        assertEquals(1, result.state.lastAnnouncedTimeIndex)
        assertEquals(300, result.state.lastElapsedSeconds)
        assertEquals(750.0, result.state.cumulativeDistanceMeters, 0.0)
        assertTrue(result.announcements.single().contains("5:00"))
    }

    @Test
    fun locationFixDoesNotRepeatATimerAnnouncement() {
        val state = baseState(
            intervalUnit = AnnouncementStateData.UNIT_TIME,
            timeIntervalSeconds = 300,
        ).copy(
            cumulativeDistanceMeters = 750.0,
            lastLatitude = 0.0,
            lastLongitude = 0.0,
            lastElapsedSeconds = 250,
        )
        val timerResult = AnnouncementScheduler.onElapsedTime(state, 300)

        val locationResult = AnnouncementScheduler.onFix(
            state = timerResult.state,
            latitude = 0.0,
            longitude = 0.0001,
            elapsedSeconds = 320,
            isNewSegment = false,
        )

        assertEquals(1, timerResult.announcements.size)
        assertTrue(locationResult.announcements.isEmpty())
        assertEquals(1, locationResult.state.lastAnnouncedTimeIndex)
    }

    @Test
    fun delayedTimerCatchesThresholdAfterElapsedStateAdvanced() {
        val state = baseState(
            intervalUnit = AnnouncementStateData.UNIT_TIME,
            timeIntervalSeconds = 300,
        ).copy(
            lastElapsedSeconds = 320,
            lastAnnouncedTimeIndex = 0,
        )

        val result = AnnouncementScheduler.onElapsedTime(
            state = state,
            elapsedSeconds = 320,
        )

        assertEquals(1, result.announcements.size)
        assertEquals(1, result.state.lastAnnouncedTimeIndex)
    }
}
