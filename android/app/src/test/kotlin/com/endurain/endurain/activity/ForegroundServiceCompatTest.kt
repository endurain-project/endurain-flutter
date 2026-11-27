package com.endurain.endurain.activity

import android.Manifest
import android.app.Application
import android.os.Looper
import org.junit.After
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf
import org.robolectric.android.controller.ServiceController
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [35], application = Application::class)
class ForegroundServiceCompatTest {
    private lateinit var application: Application
    private lateinit var controller: ServiceController<ActivityRecorderService>
    private lateinit var compat: ForegroundServiceCompat

    private fun session(heartRateDeviceId: String? = null) = ActiveActivitySessionData(
        localSessionId = "s1",
        activityType = "ride",
        status = ActiveActivitySessionData.STATUS_RECORDING,
        startedAt = "2026-07-15T10:00:00.000Z",
        heartRateDeviceId = heartRateDeviceId,
    )

    @Before
    fun setUp() {
        application = RuntimeEnvironment.getApplication()
        RecorderWorker.looperOverride = Looper.getMainLooper()
        controller = Robolectric.buildService(ActivityRecorderService::class.java).create()
        val service = controller.get()
        compat = ForegroundServiceCompat(
            service,
            RecorderNotifications(service),
            ActiveActivityStore.of(application),
        )
    }

    @After
    fun tearDown() {
        controller.destroy()
        RecorderWorker.looperOverride = null
    }

    @Test
    fun aSessionWithoutASensorNeverDeclaresTheConnectedDeviceType() {
        shadowOf(application).grantPermissions(Manifest.permission.BLUETOOTH_CONNECT)

        assertFalse(compat.canDeclareConnectedDeviceType(null))
        assertFalse(compat.canDeclareConnectedDeviceType(session()))
    }

    @Test
    fun aBoundSensorNeedsANearbyDevicePermissionToDeclareTheType() {
        val bound = session(heartRateDeviceId = "AA:BB:CC:DD:EE:FF")
        shadowOf(application).denyPermissions(
            Manifest.permission.BLUETOOTH_CONNECT,
            Manifest.permission.BLUETOOTH_SCAN,
        )
        assertFalse(compat.canDeclareConnectedDeviceType(bound))
        assertFalse(compat.hasConnectedDevicePermission())

        shadowOf(application).grantPermissions(Manifest.permission.BLUETOOTH_SCAN)

        assertTrue(compat.hasConnectedDevicePermission())
        assertTrue(compat.canDeclareConnectedDeviceType(bound))
    }

    @Test
    fun trackingWhetherTheServiceIsInTheForeground() {
        assertFalse(compat.inForeground)

        compat.start("title", "text", connectedDevice = false)
        assertTrue(compat.inForeground)

        compat.stop()
        assertFalse(compat.inForeground)
    }
}
