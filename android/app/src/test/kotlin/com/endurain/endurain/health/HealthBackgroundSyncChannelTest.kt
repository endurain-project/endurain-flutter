package com.endurain.endurain.health

import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMethodCodec
import java.nio.ByteBuffer
import org.junit.Assert.assertEquals
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test

class HealthBackgroundSyncChannelTest {
    private val scheduled = mutableListOf<Boolean>()
    private val listened = mutableListOf<HealthBackgroundSyncChannel>()
    private val finished = mutableListOf<Boolean>()

    private val channel = HealthBackgroundSyncChannel(
        setScheduled = { scheduled.add(it) },
        onListen = { listened.add(it) },
        onFinished = { finished.add(it) },
    )

    private fun call(method: String, arguments: Any? = null): CapturingResult =
        CapturingResult().also { channel.onMethodCall(MethodCall(method, arguments), it) }

    @Test
    fun schedulesAndCancelsTheTrigger() {
        call("setScheduled", mapOf("scheduled" to true))
        call("setScheduled", mapOf("scheduled" to false))

        assertEquals(listOf(true, false), scheduled)
    }

    @Test
    fun rejectsAMissingArgument() {
        val result = call("setScheduled", emptyMap<String, Any>())

        assertEquals("invalid_arguments", result.errorCode)
        assertTrue(scheduled.isEmpty())
    }

    @Test
    fun listenHandsOverThisChannel() {
        call("listen")

        assertSame(channel, listened.single())
    }

    @Test
    fun reportsAFinishedHeadlessRun() {
        call("reportFinished", mapOf("succeeded" to false))

        assertEquals(listOf(false), finished)
    }

    @Test
    fun answersNoOtherMethod() {
        assertTrue(call("other").notImplemented)
    }

    @Test
    fun aRunWithoutAnEngineFails() {
        val results = mutableListOf<Boolean>()

        channel.run { results.add(it) }

        assertEquals(listOf(false), results)
    }

    @Test
    fun aRunGetsDartsAnswer() {
        val messenger = CapturingMessenger()
        channel.register(messenger)
        val results = mutableListOf<Boolean>()

        channel.run { results.add(it) }
        messenger.reply(StandardMethodCodec.INSTANCE.encodeSuccessEnvelope(true))

        assertEquals("run", messenger.method)
        assertEquals(listOf(true), results)
    }

    @Test
    fun aRunDartDoesNotHandleFails() {
        val messenger = CapturingMessenger()
        channel.register(messenger)
        val results = mutableListOf<Boolean>()

        channel.run { results.add(it) }
        messenger.reply(null)

        assertEquals(listOf(false), results)
    }

    @Test
    fun anUnansweredRunFailsOnceTheEngineGoes() {
        val messenger = CapturingMessenger()
        channel.register(messenger)
        val results = mutableListOf<Boolean>()

        channel.run { results.add(it) }
        channel.unregister()
        messenger.reply(StandardMethodCodec.INSTANCE.encodeSuccessEnvelope(true))

        assertEquals(listOf(false), results)
    }

    private class CapturingResult : MethodChannel.Result {
        var errorCode: String? = null
        var notImplemented = false

        override fun success(result: Any?) = Unit

        override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
            this.errorCode = errorCode
        }

        override fun notImplemented() {
            notImplemented = true
        }
    }

    /** Keeps the last message sent to Dart so a test can answer it. */
    private class CapturingMessenger : BinaryMessenger {
        var method: String? = null
        private var pendingReply: BinaryMessenger.BinaryReply? = null

        fun reply(envelope: ByteBuffer?) {
            envelope?.rewind()
            pendingReply?.reply(envelope)
        }

        override fun send(channel: String, message: ByteBuffer?) = Unit

        override fun send(
            channel: String,
            message: ByteBuffer?,
            callback: BinaryMessenger.BinaryReply?,
        ) {
            message?.rewind()
            method = message?.let { StandardMethodCodec.INSTANCE.decodeMethodCall(it).method }
            pendingReply = callback
        }

        override fun setMessageHandler(
            channel: String,
            handler: BinaryMessenger.BinaryMessageHandler?,
        ) = Unit
    }
}
