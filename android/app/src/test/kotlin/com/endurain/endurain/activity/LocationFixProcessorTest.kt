package com.endurain.endurain.activity

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class LocationFixProcessorTest {
    private val processor = LocationFixProcessor()

    private fun fix(
        timeMillis: Long,
        accuracy: Float? = 5f,
        speed: Float? = 2f,
    ) = LocationFix(
        timeMillis = timeMillis,
        latitude = 41.0,
        longitude = -8.0,
        accuracyMeters = accuracy,
        speedMetersPerSecond = speed,
    )

    private fun LocationFixProcessor.Outcome.accepted() =
        this as LocationFixProcessor.Outcome.Accepted

    @Test
    fun acceptsTheFirstFixInTheCurrentSegmentAndRemembersItsTime() {
        val outcome = processor.process(fix(1_000), currentSegmentIndex = 3)

        assertEquals(LocationFixProcessor.Outcome.Accepted(3, isNewSegment = false), outcome)
        assertEquals(1_000L, processor.lastPointEpochMillis)
    }

    @Test
    fun dropsFixesLessAccurateThanTheGateButKeepsTheBoundaryAndUnknownAccuracy() {
        assertEquals(
            LocationFixProcessor.Outcome.Rejected,
            processor.process(fix(1_000, accuracy = 100.5f), 0),
        )
        assertNull(processor.lastPointEpochMillis)

        assertTrue(processor.process(fix(2_000, accuracy = 100f), 0) is
            LocationFixProcessor.Outcome.Accepted)
        assertTrue(processor.process(fix(3_000, accuracy = null), 0) is
            LocationFixProcessor.Outcome.Accepted)
    }

    @Test
    fun dropsImpossibleSpeedOnlyOnceAPreviousPointExistsAndTimeAdvanced() {
        // No previous point: nothing to compare against, so it is kept.
        assertTrue(processor.process(fix(1_000, speed = 120f), 0) is
            LocationFixProcessor.Outcome.Accepted)
        // Time moved forward at an impossible speed: dropped, state untouched.
        assertEquals(
            LocationFixProcessor.Outcome.Rejected,
            processor.process(fix(2_000, speed = 90.5f), 0),
        )
        assertEquals(1_000L, processor.lastPointEpochMillis)
        // Same timestamp: the speed gate does not apply.
        assertTrue(processor.process(fix(1_000, speed = 120f), 0) is
            LocationFixProcessor.Outcome.Accepted)
        assertTrue(processor.process(fix(3_000, speed = 90f), 0) is
            LocationFixProcessor.Outcome.Accepted)
    }

    @Test
    fun aLongTimeGapOpensANewSegment() {
        processor.process(fix(1_000), 0)

        val kept = processor.process(fix(31_000), 0).accepted()
        val gap = processor.process(fix(61_001), 0).accepted()

        assertEquals(LocationFixProcessor.Outcome.Accepted(0, false), kept)
        assertEquals(LocationFixProcessor.Outcome.Accepted(1, true), gap)
    }

    @Test
    fun aResumeOpensANewSegmentOnlyWhenThereIsAPreviousPoint() {
        processor.resumedFromPause = true
        val first = processor.process(fix(1_000), 0).accepted()
        assertEquals(0, first.segmentIndex)
        assertEquals(false, processor.resumedFromPause)

        processor.resumedFromPause = true
        val second = processor.process(fix(2_000), 0).accepted()
        assertEquals(LocationFixProcessor.Outcome.Accepted(1, true), second)
    }

    @Test
    fun aDroppedFixKeepsThePendingResumeForTheNextAcceptedOne() {
        processor.process(fix(1_000), 0)
        processor.resumedFromPause = true

        processor.process(fix(2_000, accuracy = 500f), 0)
        assertTrue(processor.resumedFromPause)

        assertEquals(
            LocationFixProcessor.Outcome.Accepted(1, true),
            processor.process(fix(3_000), 0),
        )
    }

    @Test
    fun convertsAFixToAStoredPoint() {
        val point = LocationFix(
            timeMillis = 1_700_000_000_000L,
            latitude = 41.5,
            longitude = -8.5,
            altitudeMeters = 12.0,
            accuracyMeters = 4f,
            speedMetersPerSecond = 3f,
            bearingDegrees = 90.0,
            verticalAccuracyMeters = 2.0,
            bearingAccuracyDegrees = 5.0,
            speedAccuracyMetersPerSecond = 0.5,
        ).toPoint(segmentIndex = 2, heartRateBpm = 150, powerWatts = 200, cadenceRpm = 80)

        assertEquals(IsoTime.format(java.util.Date(1_700_000_000_000L)), point.timestamp)
        assertEquals(2, point.segmentIndex)
        assertEquals(12.0, point.elevationMeters!!, 0.0)
        assertEquals(4.0, point.horizontalAccuracyMeters!!, 0.0)
        assertEquals(3.0, point.speedMetersPerSecond!!, 0.0)
        assertEquals(150, point.heartRateBpm)
        assertEquals(200, point.powerWatts)
        assertEquals(80, point.cadenceRpm)
        assertNull(fix(1_000, accuracy = null, speed = null).toPoint(0).horizontalAccuracyMeters)
    }
}
