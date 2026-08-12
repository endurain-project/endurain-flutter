package com.endurain.endurain

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class DeviceMeasurementSystemChannelTest {
    @Test
    fun returnsResolvedMeasurementSystem() {
        val result = CapturingResult()
        val channel = DeviceMeasurementSystemChannel { "imperial" }

        channel.onMethodCall(MethodCall("getMeasurementSystem", null), result)

        assertEquals("imperial", result.value)
    }

    @Test
    fun returnsNullWhenResolutionFails() {
        val result = CapturingResult()
        val channel = DeviceMeasurementSystemChannel {
            throw IllegalStateException("Unavailable")
        }

        channel.onMethodCall(MethodCall("getMeasurementSystem", null), result)

        assertTrue(result.succeeded)
        assertEquals(null, result.value)
    }

    @Test
    fun rejectsUnknownMethods() {
        val result = CapturingResult()
        val channel = DeviceMeasurementSystemChannel { "metric" }

        channel.onMethodCall(MethodCall("unknown", null), result)

        assertTrue(result.notImplemented)
    }

    private class CapturingResult : MethodChannel.Result {
        var value: Any? = null
        var succeeded = false
        var notImplemented = false

        override fun success(result: Any?) {
            value = result
            succeeded = true
        }

        override fun error(code: String, message: String?, details: Any?) {
            throw AssertionError("Unexpected error: $code $message $details")
        }

        override fun notImplemented() {
            notImplemented = true
        }
    }
}