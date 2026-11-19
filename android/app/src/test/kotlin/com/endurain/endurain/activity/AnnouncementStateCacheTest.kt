package com.endurain.endurain.activity

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class AnnouncementStateCacheTest {
    private fun state(distanceMeters: Double = 0.0) = AnnouncementStateData(
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
        messageTemplate = "{distance} {duration} {lapMetric} {overallMetric}",
        cumulativeDistanceMeters = distanceMeters,
    )

    @Test
    fun unchangedStateDoesNotNeedPersistence() {
        val cache = AnnouncementStateCache(checkpointIntervalMillis = 60_000)
        cache.restore(state(), uptimeMillis = 1_000)

        assertNull(cache.stateToPersist(uptimeMillis = 61_000))
    }

    @Test
    fun changedStateWaitsForCheckpointInterval() {
        val cache = AnnouncementStateCache(checkpointIntervalMillis = 60_000)
        val updated = state(distanceMeters = 25.0)
        cache.restore(state(), uptimeMillis = 1_000)
        cache.update(updated)

        assertNull(cache.stateToPersist(uptimeMillis = 60_999))
        assertEquals(updated, cache.stateToPersist(uptimeMillis = 61_000))
    }

    @Test
    fun forcedCheckpointIsAvailableImmediately() {
        val cache = AnnouncementStateCache(checkpointIntervalMillis = 60_000)
        val updated = state(distanceMeters = 25.0)
        cache.restore(state(), uptimeMillis = 1_000)
        cache.update(updated)

        assertEquals(
            updated,
            cache.stateToPersist(uptimeMillis = 1_001, force = true),
        )
    }

    @Test
    fun persistedStateIsNotReturnedAgain() {
        val cache = AnnouncementStateCache(checkpointIntervalMillis = 60_000)
        cache.restore(state(), uptimeMillis = 1_000)
        cache.update(state(distanceMeters = 25.0))
        cache.markPersisted(uptimeMillis = 1_001)

        assertNull(cache.stateToPersist(uptimeMillis = 61_001, force = true))
    }
}