package com.endurain.endurain.activity

import java.io.File
import java.util.Date
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder

/**
 * JVM unit tests for [ActivePointsLog], the durable append-only points log that
 * backs crash-recovery and draining for the Android background recorder.
 *
 * A regression here silently drops or corrupts a user's in-progress activity,
 * so the drain offset, malformed-line tolerance, and orphaned-session
 * reconstruction are locked down. Semantics must stay compatible with the Dart
 * `FileActiveActivityStore` so either recorder can recover the other's state.
 */
class ActivePointsLogTest {

    @get:Rule
    val tempFolder = TemporaryFolder()

    private fun newLog(): Pair<ActivePointsLog, File> {
        val file = File(tempFolder.newFolder("active"), "points.jsonl")
        return ActivePointsLog(file) to file
    }

    private fun point(
        second: Int,
        segment: Int = 0,
        lat: Double = 38.7,
        lon: Double = -9.1,
    ): RecordedActivityPointData {
        return RecordedActivityPointData(
            timestamp = IsoTime.format(Date(BASE_EPOCH_MILLIS + second * 1000L)),
            latitude = lat,
            longitude = lon,
            segmentIndex = segment,
        )
    }

    @Test
    fun readIsEmptyBeforeAnythingIsWritten() {
        val (log, _) = newLog()

        assertTrue(log.read().isEmpty())
        assertEquals(0, log.count())
        assertNull(log.last())
        assertNull(log.orphanedSession())
    }

    @Test
    fun appendThenReadReturnsEveryPointInOrder() {
        val (log, _) = newLog()

        log.append(listOf(point(0, segment = 0), point(30, segment = 1)))
        log.append(listOf(point(60, segment = 2)))

        assertEquals(listOf(0, 1, 2), log.read().map { it.segmentIndex })
        assertEquals(3, log.count())
    }

    @Test
    fun appendIsANoOpForAnEmptyBatch() {
        val (log, file) = newLog()

        log.append(emptyList())

        assertEquals(0, log.count())
        // No batch means no file is created; recovery must treat this as empty.
        assertTrue(!file.exists())
    }

    @Test
    fun readSkipsValidPointsBeforeTheOffset() {
        val (log, _) = newLog()
        log.append(
            listOf(
                point(0, segment = 0),
                point(30, segment = 1),
                point(60, segment = 2),
                point(90, segment = 3),
            ),
        )

        // Draining after acknowledging the first two points must return only
        // the remaining, still-pending points.
        assertEquals(
            listOf(2, 3),
            log.read(sinceOffset = 2).map { it.segmentIndex },
        )
    }

    @Test
    fun malformedLinesAreSkippedWithoutConsumingTheOffset() {
        val (log, file) = newLog()
        log.append(listOf(point(0, segment = 0)))
        // A corrupt entry between two valid points must not shift the drain
        // offset, or a real pending point would be silently dropped.
        file.appendText("not-json\n")
        file.appendText("{\"missing\":\"coords\"}\n")
        log.append(listOf(point(30, segment = 5)))

        assertEquals(2, log.count())
        assertEquals(listOf(0, 5), log.read().map { it.segmentIndex })
        assertEquals(
            listOf(5),
            log.read(sinceOffset = 1).map { it.segmentIndex },
        )
    }

    @Test
    fun lastReturnsTheMostRecentValidPointIgnoringTrailingGarbage() {
        val (log, file) = newLog()
        log.append(listOf(point(0, segment = 0), point(30, segment = 4)))
        file.appendText("garbage\n")

        assertEquals(4, log.last()?.segmentIndex)
    }

    @Test
    fun orphanedSessionReconstructsAFailedSessionSpanningTheRecordedPoints() {
        val (log, _) = newLog()
        log.append(listOf(point(0, segment = 0), point(120, segment = 2)))

        val session = log.orphanedSession()

        assertNotNull(session)
        assertEquals(ActiveActivitySessionData.STATUS_FAILED, session!!.status)
        assertEquals("other", session.activityType)
        assertEquals(120, session.elapsedDurationSeconds)
        assertEquals(2, session.currentSegmentIndex)
        assertTrue(session.localSessionId.startsWith("recovered_"))
    }

    @Test
    fun orphanedSessionIsNullWhenOnlyMalformedLinesExist() {
        val (log, file) = newLog()
        file.appendText("nope\n\n{\"broken\":true}\n")

        assertNull(log.orphanedSession())
        assertEquals(0, log.count())
    }

    private companion object {
        // Fixed, deterministic epoch (2023-11-14T22:13:20Z) so timestamp math
        // in the tests never depends on the wall clock.
        const val BASE_EPOCH_MILLIS = 1_700_000_000_000L
    }
}
