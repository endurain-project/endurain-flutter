package com.endurain.endurain.wear

import com.endurain.endurain.watchlink.WatchActivityType
import com.endurain.endurain.watchlink.WatchHandoffBuilder
import com.endurain.endurain.watchlink.WatchProtocol
import com.endurain.endurain.watchlink.WatchRecordedPoint
import com.endurain.endurain.watchlink.WatchRecording
import com.endurain.endurain.watchlink.WatchRecordingStore
import org.json.JSONObject
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import java.io.File
import java.nio.file.Files

private const val START = 1_800_000_000_000L

class WatchRecordingTest {
    @Test
    fun elapsedExcludesPauses() {
        var recording = WatchRecording("s", WatchActivityType.RUN, START)
        assertEquals(60_000, recording.elapsedMillis(START + 60_000))

        recording = recording.paused(START + 60_000)
        assertTrue(recording.isPaused)
        assertEquals(60_000, recording.elapsedMillis(START + 600_000))

        recording = recording.resumed(START + 120_000)
        assertEquals(1, recording.segmentIndex)
        assertEquals(90_000, recording.elapsedMillis(START + 150_000))
    }

    @Test
    fun repeatedPauseOrResumeIsIgnored() {
        var recording = WatchRecording("s", WatchActivityType.RIDE, START).resumed(START + 10_000)
        assertEquals(0, recording.segmentIndex)

        recording = recording.paused(START + 30_000).paused(START + 50_000)
        assertEquals(30_000, recording.elapsedMillis(START + 100_000))
    }

    @Test
    fun recordingRoundTripsThroughJson() {
        val recording = WatchRecording("s", WatchActivityType.HIKE, START).paused(START + 5_000)
        assertEquals(recording, WatchRecording.fromJson(JSONObject(recording.toJson().toString())))
    }

    @Test
    fun pointRoundTripsThroughJson() {
        val point =
            WatchRecordedPoint(
                timestampMillis = START,
                latitude = 38.7,
                longitude = -9.1,
                segmentIndex = 2,
                elevationMeters = 12.5,
                horizontalAccuracyMeters = 4.0,
                verticalAccuracyMeters = 3.0,
                headingDegrees = 90.0,
                speedMetersPerSecond = 3.2,
                heartRateBpm = 151,
            )
        val json = JSONObject(point.toJson().toString())

        assertEquals("2027-01-15T08:00:00.000Z", json.getString("t"))
        assertEquals(point, WatchRecordedPoint.fromJson(json))
    }

    @Test
    fun pointRejectsOutOfRangeCoordinates() {
        assertNull(WatchRecordedPoint.fromJson(JSONObject("""{"t":"2027-01-15T08:00:00.000Z","lat":91,"lon":0}""")))
        assertNull(WatchRecordedPoint.fromJson(JSONObject("""{"t":"2027-01-15T08:00:00.000Z","lat":0,"lon":181}""")))
        assertNull(WatchRecordedPoint.fromJson(JSONObject("""{"lat":0,"lon":0}""")))
    }

    @Test
    fun recordingKeepsItsLastDistanceThroughJson() {
        val recording = WatchRecording("s", WatchActivityType.RUN, 1_000, lastDistanceMeters = 12.5)
        assertEquals(12.5, WatchRecording.fromJson(recording.toJson())?.lastDistanceMeters)
        assertNull(WatchRecording.fromJson(recording.copy(lastDistanceMeters = null).toJson())?.lastDistanceMeters)
    }
}

class WatchRecordingStoreTest {
    private lateinit var directory: File
    private lateinit var store: WatchRecordingStore

    @Before
    fun setUp() {
        directory = File(Files.createTempDirectory("recording").toFile(), "store")
        store = WatchRecordingStore(directory)
    }

    @After
    fun tearDown() {
        directory.parentFile?.deleteRecursively()
    }

    @Test
    fun nothingToLoadWithoutARecording() {
        assertNull(store.load())
    }

    @Test
    fun hasRecordingFollowsBeginAndClear() {
        assertFalse(store.hasRecording())

        store.begin(WatchRecording("s", WatchActivityType.RUN, START))
        assertTrue(store.hasRecording())

        store.clear()
        assertFalse(store.hasRecording())
    }

    @Test
    fun restoresTheRecordingAndItsPoints() {
        var recording = WatchRecording("s", WatchActivityType.HIKE, START)
        store.begin(recording)
        store.append(listOf(point(1), point(2)))
        recording = recording.paused(START + 5_000)
        store.update(recording)
        store.append(listOf(point(3)))

        val (loaded, points) = store.load()!!
        assertEquals(recording, loaded)
        assertEquals(listOf(1, 2, 3).map { START + it * 1000L }, points.map { it.timestampMillis })
    }

    @Test
    fun skipsALineCutShortByACrash() {
        store.begin(WatchRecording("s", WatchActivityType.RUN, START))
        store.append(listOf(point(1)))
        File(directory, "points.jsonl").appendText("""{"t":"2027-01-15T08:0""")

        assertEquals(1, store.load()!!.second.size)
    }

    @Test
    fun loadClearsARecordingThatCannotBeParsed() {
        store.begin(WatchRecording("s", WatchActivityType.RUN, START))
        store.append(listOf(point(1)))
        File(directory, "recording.json").writeText("{not json")

        assertTrue(store.hasRecording())
        assertNull(store.load())
        assertFalse(store.hasRecording())
        assertFalse(directory.exists())
    }

    @Test
    fun loadClearsARecordingMissingRequiredFields() {
        store.begin(WatchRecording("s", WatchActivityType.RUN, START))
        File(directory, "recording.json").writeText("""{"sessionId":"s"}""")

        assertNull(store.load())
        assertFalse(store.hasRecording())
    }

    @Test
    fun beginDiscardsThePreviousRecording() {
        store.begin(WatchRecording("old", WatchActivityType.RUN, START))
        store.append(listOf(point(1)))
        store.begin(WatchRecording("new", WatchActivityType.WALK, START))

        val (loaded, points) = store.load()!!
        assertEquals("new", loaded.sessionId)
        assertTrue(points.isEmpty())
    }

    private fun point(seconds: Int) = WatchRecordedPoint(START + seconds * 1000L, 38.7, -9.1, 0)
}

class WatchHandoffBuilderTest {
    @Test
    fun buildsTheEnvelopeDartReads() {
        val recording =
            WatchRecording("B7E2", WatchActivityType.RIDE, START)
                .paused(START + 30_000)
                .resumed(START + 60_000)
        val points =
            listOf(
                WatchRecordedPoint(START + 70_000, 1.0, 2.0, 1),
                WatchRecordedPoint(START + 10_000, 3.0, 4.0, 0),
            )

        val envelope =
            JSONObject(
                WatchHandoffBuilder
                    .bytes(recording, points, endedAtMillis = START + 90_000, elapsedMillis = 59_600)
                    .toString(Charsets.UTF_8),
            )

        assertEquals(1, envelope.getInt("version"))
        assertEquals("wearOs", envelope.getString("source"))
        assertFalse(envelope.has("healthWorkoutId"))
        val session = envelope.getJSONObject("session")
        assertEquals(3, session.getInt("schemaVersion"))
        assertEquals("B7E2", session.getString("localSessionId"))
        assertEquals("ride", session.getString("activityType"))
        assertEquals("completed", session.getString("status"))
        assertEquals("2027-01-15T08:00:00.000Z", session.getString("startedAt"))
        assertEquals("2027-01-15T08:01:30.000Z", session.getString("endedAt"))
        assertEquals(60, session.getInt("elapsedDurationSeconds"))
        assertEquals(1, session.getInt("currentSegmentIndex"))
        val encoded = envelope.getJSONArray("points")
        assertEquals(listOf(0, 1), (0 until encoded.length()).map { encoded.getJSONObject(it).getInt("seg") })
    }

    @Test
    fun anInterruptedRecordingEndsAtItsLastPoint() {
        val recording = WatchRecording("s", WatchActivityType.RUN, START)
        assertEquals(START, WatchHandoffBuilder.endOfInterruptedRecording(recording, emptyList()))
        val points = listOf(30, 90, 60).map { WatchRecordedPoint(START + it * 1000L, 0.0, 0.0, 0) }
        assertEquals(START + 90_000, WatchHandoffBuilder.endOfInterruptedRecording(recording, points))
    }
}
