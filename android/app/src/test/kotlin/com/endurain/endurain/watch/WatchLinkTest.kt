package com.endurain.endurain.watch

import android.app.Application
import android.os.Looper
import com.endurain.endurain.watchlink.HandoffFileStore
import com.endurain.endurain.watchlink.WatchActivityType
import com.endurain.endurain.watchlink.WatchHandoffBuilder
import com.endurain.endurain.watchlink.WatchProtocol
import com.endurain.endurain.watchlink.WatchRecordedPoint
import com.endurain.endurain.watchlink.WatchRecording
import com.endurain.endurain.watchlink.WatchRecordingStore
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import java.io.File
import java.nio.ByteBuffer
import java.nio.file.Files
import java.util.concurrent.AbstractExecutorService
import java.util.concurrent.TimeUnit

private const val START = 1_800_000_000_000L

class HandoffFileStoreTest {
    private lateinit var directory: File
    private lateinit var store: HandoffFileStore

    @Before
    fun setUp() {
        directory = File(Files.createTempDirectory("handoffs").toFile(), "store")
        store = HandoffFileStore(directory)
    }

    @After
    fun tearDown() {
        directory.parentFile?.deleteRecursively()
    }

    @Test
    fun missingDirectoryIsEmpty() {
        assertTrue(store.entries().isEmpty())
        assertTrue(store.isEmpty)
    }

    @Test
    fun savesAndReadsBySessionId() {
        store.save("a".toByteArray(), "session-a")
        store.save("b".toByteArray(), "session/b")

        assertEquals(setOf("session-a", "session/b"), store.entries().map { it.sessionId }.toSet())
        assertEquals("b", store.data("session/b")?.toString(Charsets.UTF_8))
    }

    @Test
    fun savingAgainKeepsOneCopy() {
        store.save("first".toByteArray(), "s")
        store.save("second".toByteArray(), "s")

        assertEquals(1, store.entries().size)
        assertEquals("second", store.data("s")?.toString(Charsets.UTF_8))
    }

    @Test
    fun fileNamesAreInjective() {
        val ids = listOf("a_b", "a/b", "a b", "a.b", "a:b", "ä")
        ids.forEach { store.save(it.toByteArray(), it) }

        assertEquals(ids.toSet(), store.entries().map { it.sessionId }.toSet())
        ids.forEach { assertEquals(it, store.data(it)?.toString(Charsets.UTF_8)) }
    }

    @Test(expected = IllegalArgumentException::class)
    fun rejectsAnEmptySessionId() {
        store.save(ByteArray(0), "")
    }

    @Test(expected = IllegalArgumentException::class)
    fun rejectsATooLongSessionId() {
        store.save(ByteArray(0), "x".repeat(HandoffFileStore.MAX_SESSION_ID_BYTES + 1))
    }

    @Test
    fun removeAndPrune() {
        store.save(ByteArray(0), "old")
        store.save(ByteArray(0), "recent")
        store.entry("old")!!.file.setLastModified(START)
        store.entry("recent")!!.file.setLastModified(START + 10_000)

        assertEquals(listOf("old"), store.pruneSavedBefore(START + 5_000))
        assertEquals(listOf("recent"), store.entries().map { it.sessionId })

        store.remove("recent")
        assertTrue(store.isEmpty)
    }

    @Test
    fun ignoresForeignFiles() {
        directory.mkdirs()
        File(directory, "notes.txt").writeText("")
        File(directory, "zz.json").writeText("")
        File(directory, "ff.json").writeText("") // not valid UTF-8
        store.save(ByteArray(0), "s")

        assertEquals(listOf("s"), store.entries().map { it.sessionId })
    }

    @Test
    fun protocolPathsRoundTrip() {
        val path = WatchProtocol.handoffPath("a/b c")
        assertTrue(path.startsWith(WatchProtocol.HANDOFF_PATH_PREFIX))
        assertEquals("a/b c", WatchProtocol.sessionIdFromPath(path, WatchProtocol.HANDOFF_PATH_PREFIX))
        assertNull(WatchProtocol.sessionIdFromPath(path, WatchProtocol.ACK_PATH_PREFIX))
        assertNull(WatchProtocol.sessionIdFromPath(null, WatchProtocol.ACK_PATH_PREFIX))
    }
}

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

    @Test
    fun linkStatusMapping() {
        fun status(
            available: Boolean = true,
            known: Boolean = true,
            reachable: Boolean = true,
            connected: Boolean = true,
        ) = WatchLinkState.status(available, known, reachable, connected)

        assertEquals("unavailable", status(available = false))
        assertEquals("connected", status())
        assertEquals("disconnected", status(reachable = false))
        assertEquals("appNotInstalled", status(known = false, reachable = false))
        assertEquals("unpaired", status(known = false, reachable = false, connected = false))
    }
}

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [35], application = Application::class)
class WatchTransportChannelTest {
    private lateinit var directory: File
    private lateinit var inbox: HandoffFileStore
    private val link = FakeWatchLink()
    private lateinit var channel: WatchTransportChannel

    @Before
    fun setUp() {
        directory = Files.createTempDirectory("inbox").toFile()
        inbox = HandoffFileStore(directory)
        channel = WatchTransportChannel(link, inbox, DirectExecutor())
    }

    @After
    fun tearDown() {
        directory.deleteRecursively()
    }

    @Test
    fun rejectsAnUnsupportedVersion() {
        val result = call("linkStatus", mapOf("version" to 99))
        assertEquals(WatchTransportChannel.ERROR_UNSUPPORTED_VERSION, result.errorCode)
    }

    @Test
    fun reportsTheLinkStatus() {
        link.status = "disconnected"
        assertEquals("disconnected", call("linkStatus", mapOf("version" to 1)).value)
    }

    @Test
    fun drainsReadableEnvelopesAfterPullingFromTheLink() {
        link.pending = mapOf("good" to envelope("good"))
        inbox.save("{broken".toByteArray(), "broken")

        @Suppress("UNCHECKED_CAST")
        val handoffs = call("drainHandoffs", mapOf("version" to 1)).value as List<Map<String, Any?>>

        assertEquals(1, handoffs.size)
        @Suppress("UNCHECKED_CAST")
        val session = handoffs.single()["session"] as Map<String, Any?>
        assertEquals("good", session["localSessionId"])
        assertTrue((handoffs.single()["points"] as List<*>).isEmpty())
        // The unreadable one stays for a later app version.
        assertEquals(2, inbox.entries().size)
    }

    @Test
    fun acknowledgeRemovesTheSessionAndTellsTheWatch() {
        inbox.save(envelope("s"), "s")

        val result = call("acknowledgeHandoff", mapOf("version" to 1, "sessionId" to "s"))

        assertTrue(result.succeeded)
        assertTrue(inbox.isEmpty)
        assertEquals(listOf("s"), link.acknowledged)
    }

    @Test
    fun acknowledgeRequiresASessionId() {
        val result = call("acknowledgeHandoff", mapOf("version" to 1))
        assertEquals(WatchTransportChannel.ERROR_INVALID_ARGUMENTS, result.errorCode)
    }

    @Test
    fun unregisteringAnOlderChannelKeepsTheNewerEnginesHandoffListener() {
        val newer = WatchTransportChannel(FakeWatchLink(), inbox, DirectExecutor())
        channel.register(NoopMessenger())
        newer.register(NoopMessenger())

        channel.unregister()
        assertNotNull(WatchHandoffEvents.listener)

        newer.unregister()
        assertNull(WatchHandoffEvents.listener)
    }

    private fun call(method: String, arguments: Map<String, Any?>): CapturingResult {
        val result = CapturingResult()
        channel.onMethodCall(MethodCall(method, arguments), result)
        shadowOf(Looper.getMainLooper()).idle()
        return result
    }

    private fun envelope(sessionId: String): ByteArray =
        WatchHandoffBuilder.bytes(
            WatchRecording(sessionId, WatchActivityType.RUN, START),
            emptyList(),
            endedAtMillis = START,
            elapsedMillis = 0,
        )

    private class FakeWatchLink : WatchLink {
        var status = "connected"
        var pending: Map<String, ByteArray> = emptyMap()
        val acknowledged = mutableListOf<String>()

        override fun linkStatus(): String = status

        override fun pullPendingHandoffs(inbox: HandoffFileStore) {
            pending.forEach { (id, data) -> inbox.save(data, id) }
        }

        override fun acknowledge(sessionId: String) {
            acknowledged += sessionId
        }

        override fun startObserving(onLinkStatusChanged: (String) -> Unit) {}

        override fun stopObserving() {}
    }

    private class CapturingResult : MethodChannel.Result {
        var value: Any? = null
        var succeeded = false
        var errorCode: String? = null

        override fun success(result: Any?) {
            succeeded = true
            value = result
        }

        override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
            this.errorCode = errorCode
        }

        override fun notImplemented() {
            errorCode = "notImplemented"
        }
    }

    private class NoopMessenger : BinaryMessenger {
        override fun send(channel: String, message: ByteBuffer?) {}

        override fun send(channel: String, message: ByteBuffer?, callback: BinaryMessenger.BinaryReply?) {}

        override fun setMessageHandler(channel: String, handler: BinaryMessenger.BinaryMessageHandler?) {}
    }

    private class DirectExecutor : AbstractExecutorService() {
        private var shutdown = false

        override fun execute(command: Runnable) = command.run()

        override fun shutdown() {
            shutdown = true
        }

        override fun shutdownNow(): MutableList<Runnable> = mutableListOf()

        override fun isShutdown() = shutdown

        override fun isTerminated() = shutdown

        override fun awaitTermination(timeout: Long, unit: TimeUnit) = true
    }
}
