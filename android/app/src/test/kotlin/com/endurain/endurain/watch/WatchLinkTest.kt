package com.endurain.endurain.watch

import android.app.Application
import android.os.Looper
import com.endurain.endurain.watchlink.HandoffFileStore
import com.endurain.endurain.watchlink.WatchProtocol
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
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

    /** The text saved for [sessionId], read straight from its file. */
    private fun contents(sessionId: String): String? = store.entry(sessionId)?.file?.readText()

    @Test
    fun missingDirectoryIsEmpty() {
        assertTrue(store.entries().isEmpty())
        assertTrue(store.entries().isEmpty())
    }

    @Test
    fun savesAndReadsBySessionId() {
        store.save("a".toByteArray(), "session-a")
        store.save("b".toByteArray(), "session/b")

        assertEquals(setOf("session-a", "session/b"), store.entries().map { it.sessionId }.toSet())
        assertEquals("b", contents("session/b"))
    }

    @Test
    fun savingAgainKeepsOneCopy() {
        store.save("first".toByteArray(), "s")
        store.save("second".toByteArray(), "s")

        assertEquals(1, store.entries().size)
        assertEquals("second", contents("s"))
    }

    @Test
    fun fileNamesAreInjective() {
        val ids = listOf("a_b", "a/b", "a b", "a.b", "a:b", "ä")
        ids.forEach { store.save(it.toByteArray(), it) }

        assertEquals(ids.toSet(), store.entries().map { it.sessionId }.toSet())
        ids.forEach { assertEquals(it, contents(it)) }
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
        assertTrue(store.entries().isEmpty())
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

class WatchLinkStateTest {
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
        assertTrue(inbox.entries().isEmpty())
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

    /** A minimal handoff envelope; the channel only relays the JSON it finds. */
    private fun envelope(sessionId: String): ByteArray =
        JSONObject()
            .put("version", WatchProtocol.PAYLOAD_VERSION)
            .put("session", JSONObject().put("localSessionId", sessionId))
            .put("points", JSONArray())
            .toString()
            .toByteArray(Charsets.UTF_8)

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
