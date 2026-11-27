package com.endurain.endurain

import android.content.Intent
import android.os.Build
import android.app.Application
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [35], application = Application::class)
class HealthConnectSettingsChannelTest {
    private val launched = mutableListOf<Intent>()

    private fun channel(
        sdkInt: Int,
        resolves: Boolean = true,
        launchThrows: Boolean = false,
    ) = HealthConnectSettingsChannel(
        launcher = {
            if (launchThrows) throw android.content.ActivityNotFoundException()
            launched.add(it)
        },
        resolves = { resolves },
        packageName = "com.endurain.endurain",
        sdkInt = sdkInt,
    )

    private fun open(channel: HealthConnectSettingsChannel): CapturingResult =
        CapturingResult().also {
            channel.onMethodCall(MethodCall("openPermissions", null), it)
        }

    @Test
    fun android14OpensTheFrameworkScreenForThisApp() {
        val result = open(channel(Build.VERSION_CODES.UPSIDE_DOWN_CAKE))

        assertEquals(true, result.value)
        val intent = launched.single()
        assertEquals("android.health.connect.action.MANAGE_HEALTH_PERMISSIONS", intent.action)
        assertEquals("com.endurain.endurain", intent.getStringExtra(Intent.EXTRA_PACKAGE_NAME))
    }

    @Test
    fun olderAndroidOpensTheHealthConnectAppSettings() {
        val result = open(channel(Build.VERSION_CODES.TIRAMISU))

        assertEquals(true, result.value)
        val intent = launched.single()
        assertEquals("androidx.health.ACTION_HEALTH_CONNECT_SETTINGS", intent.action)
        assertNull(intent.getStringExtra(Intent.EXTRA_PACKAGE_NAME))
    }

    @Test
    fun repliesFalseWhenNoActivityHandlesTheIntent() {
        val result = open(channel(Build.VERSION_CODES.UPSIDE_DOWN_CAKE, resolves = false))

        assertEquals(false, result.value)
        assertTrue(launched.isEmpty())
    }

    @Test
    fun repliesFalseWhenStartingTheActivityThrows() {
        val result = open(channel(Build.VERSION_CODES.TIRAMISU, launchThrows = true))

        assertEquals(false, result.value)
    }

    @Test
    fun rejectsUnknownMethods() {
        val result = CapturingResult()

        channel(Build.VERSION_CODES.TIRAMISU).onMethodCall(MethodCall("unknown", null), result)

        assertTrue(result.notImplemented)
    }

    private class CapturingResult : MethodChannel.Result {
        var value: Any? = null
        var notImplemented = false

        override fun success(result: Any?) {
            value = result
        }

        override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) = Unit

        override fun notImplemented() {
            notImplemented = true
        }
    }
}
