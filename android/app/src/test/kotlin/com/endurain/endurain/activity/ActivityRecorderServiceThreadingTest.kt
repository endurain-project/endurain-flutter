package com.endurain.endurain.activity

import android.Manifest
import android.app.Application
import android.content.Context
import android.content.Intent
import android.location.Location
import android.location.LocationManager
import java.util.Date
import org.junit.After
import org.junit.Assert.assertEquals
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

/**
 * Runs the service on its real recorder thread (no looper override): the main
 * looper is never idled here, so a point can only reach the store if fixes
 * were delivered and persisted off the main thread.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [35], application = Application::class)
class ActivityRecorderServiceThreadingTest {
    private lateinit var application: Application
    private lateinit var store: ActiveActivityStore
    private lateinit var locations: LocationManager
    private var controller: ServiceController<ActivityRecorderService>? = null

    @Before
    fun setUp() {
        application = RuntimeEnvironment.getApplication()
        shadowOf(application).grantPermissions(
            Manifest.permission.ACCESS_FINE_LOCATION,
            Manifest.permission.ACCESS_COARSE_LOCATION,
        )
        locations = application.getSystemService(Context.LOCATION_SERVICE) as LocationManager
        shadowOf(locations).setProviderEnabled(LocationManager.GPS_PROVIDER, true)
        store = ActiveActivityStore.of(application)
        store.clear()
        RecorderWorker.looperOverride = null
    }

    @After
    fun tearDown() {
        controller?.destroy()
        store.clear()
    }

    @Test
    fun fixesAreDeliveredAndPersistedWithoutTheMainLooper() {
        store.saveSession(
            ActiveActivitySessionData(
                localSessionId = "threaded_session",
                activityType = "run",
                status = ActiveActivitySessionData.STATUS_RECORDING,
                startedAt = IsoTime.format(Date(System.currentTimeMillis() - 60_000)),
            ),
        )
        val service = Robolectric.buildService(ActivityRecorderService::class.java).create()
        controller = service

        service.get().onStartCommand(
            Intent(application, ActivityRecorderService::class.java).apply {
                action = ActivityRecorderService.ACTION_START
            },
            0,
            1,
        )

        // The command and the listener registration happen on the worker;
        // keep feeding fixes until one lands after the subscription exists.
        var attempt = 0
        val deadline = System.currentTimeMillis() + 10_000
        while (store.pointCount() == 0 && System.currentTimeMillis() < deadline) {
            attempt++
            shadowOf(locations).simulateLocation(Location(LocationManager.GPS_PROVIDER).apply {
                latitude = 41.0 + attempt * 0.0001
                longitude = -8.0
                time = System.currentTimeMillis()
                accuracy = 5f
                elapsedRealtimeNanos = android.os.SystemClock.elapsedRealtimeNanos()
            })
            Thread.sleep(50)
        }

        assertTrue("no point was persisted off the main thread", store.pointCount() >= 1)
        assertEquals("threaded_session", store.loadSession()?.localSessionId)
    }
}
