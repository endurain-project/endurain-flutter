package com.endurain.endurain.activity

import android.Manifest
import android.app.Application
import android.content.Context
import android.location.LocationManager
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.nio.ByteBuffer
import java.util.Date
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [35], application = Application::class)
class ActivityRecorderChannelTest {
    private lateinit var application: Application
    private lateinit var store: ActiveActivityStore
    private val channels = mutableListOf<ActivityRecorderChannel>()

    @Before
    fun setUp() {
        application = RuntimeEnvironment.getApplication()
        shadowOf(application).grantPermissions(
            Manifest.permission.ACCESS_FINE_LOCATION,
            Manifest.permission.ACCESS_COARSE_LOCATION,
        )
        val locations = application.getSystemService(Context.LOCATION_SERVICE) as LocationManager
        shadowOf(locations).setProviderEnabled(LocationManager.GPS_PROVIDER, true)
        store = ActiveActivityStore.of(application)
        store.clear()
    }

    @After
    fun tearDown() {
        channels.forEach { it.unregister() }
        channels.clear()
        ActivityRecorderCoordinator.detachAll()
        store.clear()
    }

    private fun channel(): ActivityRecorderChannel =
        ActivityRecorderChannel(application).also {
            it.register(NoopMessenger())
            channels.add(it)
        }

    @Test
    fun anOlderEnginesCancelDoesNotDetachTheNewerEnginesSink() {
        val older = channel()
        val newer = channel()
        val olderEvents = RecordingSink()
        val newerEvents = RecordingSink()
        older.onListen(null, olderEvents)
        newer.onListen(null, newerEvents)

        older.onCancel(null)
        older.unregister()
        ActivityRecorderCoordinator.emitFailed(ActivityRecorderCoordinator.REASON_PERMISSION_LOST)
        shadowOf(Looper.getMainLooper()).idle()

        assertEquals(1, newerEvents.events.size)
        assertTrue(olderEvents.events.isEmpty())

        newer.onCancel(null)
        ActivityRecorderCoordinator.emitFailed(ActivityRecorderCoordinator.REASON_PERMISSION_LOST)
        shadowOf(Looper.getMainLooper()).idle()
        assertEquals(1, newerEvents.events.size)
    }

    @Test
    fun drainSkipsPointsBeforeTheOffsetAndRepliesOnTheMainThread() {
        store.appendPoints((0 until 3).map { index ->
            RecordedActivityPointData(
                timestamp = IsoTime.format(Date(1_700_000_000_000L + index * 1000L)),
                latitude = 41.0,
                longitude = -8.0,
                segmentIndex = index,
            )
        })
        val result = CapturingResult()

        channel().onMethodCall(MethodCall("drain", mapOf("sinceOffset" to 1)), result)
        repeat(200) {
            if (result.done) return@repeat
            Thread.sleep(10)
            shadowOf(Looper.getMainLooper()).idle()
        }

        assertTrue(result.done)
        assertEquals(Looper.getMainLooper().thread, result.thread)
        @Suppress("UNCHECKED_CAST")
        val points = result.value as List<Map<String, Any?>>
        assertEquals(listOf(1, 2), points.map { it["seg"] })
    }

    @Test
    fun unregisteringEndsAWarmUpThisEngineBegan() {
        val channel = channel()
        channel.onMethodCall(MethodCall("beginStartWarmUp", null), CapturingResult())
        val controller = Robolectric.buildService(ActivityRecorderService::class.java).create()
        controller.get().onStartCommand(shadowOf(application).nextStartedService, 0, 1)
        assertFalse(shadowOf(controller.get()).isStoppedBySelf)

        channel.unregister()

        assertTrue(shadowOf(controller.get()).isStoppedBySelf)
        controller.destroy()
    }

    private class RecordingSink : EventChannel.EventSink {
        val events = mutableListOf<Any?>()

        override fun success(event: Any?) {
            events.add(event)
        }

        override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) = Unit

        override fun endOfStream() = Unit
    }

    private class CapturingResult : MethodChannel.Result {
        @Volatile var done = false
        var value: Any? = null
        var thread: Thread? = null

        override fun success(result: Any?) {
            value = result
            thread = Thread.currentThread()
            done = true
        }

        override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
            thread = Thread.currentThread()
            done = true
        }

        override fun notImplemented() {
            done = true
        }
    }

    private class NoopMessenger : BinaryMessenger {
        override fun send(channel: String, message: ByteBuffer?) {}

        override fun send(channel: String, message: ByteBuffer?, callback: BinaryMessenger.BinaryReply?) {}

        override fun setMessageHandler(channel: String, handler: BinaryMessenger.BinaryMessageHandler?) {}
    }
}
