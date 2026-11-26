package com.endurain.endurain.activity

import android.Manifest
import android.app.Application
import android.content.Context
import android.content.Intent
import android.location.Location
import android.location.LocationManager
import android.os.Looper
import io.flutter.plugin.common.EventChannel
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
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
import java.util.Date

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [35], application = Application::class)
class ActivityRecorderServiceTest {
    private lateinit var application: Application
    private lateinit var store: ActiveActivityStore
    private lateinit var locations: LocationManager
    private val controllers = mutableListOf<ServiceController<ActivityRecorderService>>()

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
    }

    @After
    fun tearDown() {
        controllers.forEach { it.destroy() }
        controllers.clear()
        ActivityRecorderCoordinator.detachAll()
        store.clear()
    }

    private fun session(status: String = ActiveActivitySessionData.STATUS_RECORDING) =
        ActiveActivitySessionData(
            localSessionId = "existing_session",
            activityType = "ride",
            status = status,
            startedAt = IsoTime.format(Date(System.currentTimeMillis() - 60_000)),
            connectionOrigin = "https://example.test",
            connectionProfileId = "profile_1",
        )

    private fun service(): ServiceController<ActivityRecorderService> =
        Robolectric.buildService(ActivityRecorderService::class.java).create().also {
            controllers.add(it)
        }

    private fun fix(latitude: Double, timeMillis: Long = System.currentTimeMillis()) {
        shadowOf(Looper.getMainLooper()).idleFor(java.time.Duration.ofSeconds(1))
        shadowOf(locations).simulateLocation(Location(LocationManager.GPS_PROVIDER).apply {
            this.latitude = latitude
            longitude = -8.0
            time = timeMillis
            accuracy = 5f
            elapsedRealtimeNanos = android.os.SystemClock.elapsedRealtimeNanos()
        })
        shadowOf(Looper.getMainLooper()).idle()
    }

    private fun warmUp(
        controller: ServiceController<ActivityRecorderService>,
        countdownSeconds: Long? = null,
    ) {
        controller.get().onStartCommand(Intent(application, ActivityRecorderService::class.java).apply {
            action = ActivityRecorderService.ACTION_WARM_UP
            countdownSeconds?.let {
                putExtra(ActivityRecorderService.EXTRA_COUNTDOWN_SECONDS, it)
            }
        }, 0, 1)
    }

    @Test
    fun warmUpRunsInTheForegroundAndDropsEveryFix() {
        val controller = service()
        warmUp(controller)

        assertNotNull(shadowOf(controller.get()).lastForegroundNotification)
        fix(41.1)

        assertNull(store.loadSession())
        assertEquals(0, store.pointCount())
        assertFalse(shadowOf(controller.get()).isStoppedBySelf)
    }

    @Test
    fun aWarmUpNobodyEndsTimesOut() {
        val controller = service()
        warmUp(controller)

        shadowOf(Looper.getMainLooper()).idleFor(
            java.time.Duration.ofMillis(ActivityRecorderService.WARM_UP_TIMEOUT_MILLIS - 1_000),
        )
        assertFalse(shadowOf(controller.get()).isStoppedBySelf)
        shadowOf(Looper.getMainLooper()).idleFor(java.time.Duration.ofSeconds(2))

        assertTrue(shadowOf(controller.get()).isStoppedBySelf)
        assertTrue(shadowOf(controller.get()).isForegroundStopped)
    }

    @Test
    fun aWarmUpTimesOutAMinuteAfterItsCountdown() {
        val controller = service()
        warmUp(controller, countdownSeconds = 30)

        shadowOf(Looper.getMainLooper()).idleFor(java.time.Duration.ofSeconds(89))
        assertFalse(shadowOf(controller.get()).isStoppedBySelf)
        shadowOf(Looper.getMainLooper()).idleFor(java.time.Duration.ofSeconds(2))

        assertTrue(shadowOf(controller.get()).isStoppedBySelf)
        assertTrue(shadowOf(controller.get()).isForegroundStopped)
    }

    @Test
    fun warmUpTimeoutIsTheCountdownPlusAMinuteClampedToOneToElevenMinutes() {
        assertEquals(90_000L, ActivityRecorderService.warmUpTimeoutMillis(30))
        assertEquals(60_000L, ActivityRecorderService.warmUpTimeoutMillis(0))
        assertEquals(60_000L, ActivityRecorderService.warmUpTimeoutMillis(-5))
        assertEquals(11 * 60_000L, ActivityRecorderService.warmUpTimeoutMillis(600))
        assertEquals(11 * 60_000L, ActivityRecorderService.warmUpTimeoutMillis(3_600))
        assertEquals(11 * 60_000L, ActivityRecorderService.warmUpTimeoutMillis(Long.MAX_VALUE))
        assertEquals(60_000L, ActivityRecorderService.warmUpTimeoutMillis(Long.MIN_VALUE))
        assertEquals(
            ActivityRecorderService.MIN_WARM_UP_TIMEOUT_MILLIS,
            ActivityRecorderService.warmUpTimeoutMillis(0),
        )
    }

    @Test
    fun warmUpTimeoutDefaultsToElevenMinutesWithoutACountdownLength() {
        assertEquals(
            ActivityRecorderService.WARM_UP_TIMEOUT_MILLIS,
            ActivityRecorderService.warmUpTimeoutMillis(null),
        )
        assertEquals(11 * 60_000L, ActivityRecorderService.WARM_UP_TIMEOUT_MILLIS)
    }

    @Test
    fun beginWarmUpPutsTheCountdownLengthOnTheIntentOnlyWhenKnown() {
        ActivityRecorderService.beginWarmUp(application, 45L)
        assertEquals(
            45L,
            shadowOf(application).nextStartedService!!
                .getLongExtra(ActivityRecorderService.EXTRA_COUNTDOWN_SECONDS, -1L),
        )

        ActivityRecorderService.beginWarmUp(application)
        assertFalse(
            shadowOf(application).nextStartedService!!
                .hasExtra(ActivityRecorderService.EXTRA_COUNTDOWN_SECONDS),
        )
    }

    @Test
    fun aWarmUpForAnExistingRecordingStillEntersTheForegroundBeforeStopping() {
        store.saveSession(session(ActiveActivitySessionData.STATUS_PAUSED))
        val controller = service()
        warmUp(controller)

        // The notification is removed again on stop; its id stays.
        assertNotEquals(0, shadowOf(controller.get()).lastForegroundNotificationId)
        assertTrue(shadowOf(controller.get()).isStoppedBySelf)
        assertEquals(ActiveActivitySessionData.STATUS_PAUSED, store.loadSession()?.status)
    }

    @Test
    fun removingTheTaskEndsAWarmUp() {
        val controller = service()
        warmUp(controller)

        controller.get().onTaskRemoved(Intent())

        assertTrue(shadowOf(controller.get()).isStoppedBySelf)
    }

    // Android 14+ refuses the location type without the permission, so the
    // contract can only be met before it.
    @Test
    @Config(sdk = [33])
    fun aWarmUpWithoutLocationPermissionEntersTheForegroundBeforeStopping() {
        shadowOf(application).denyPermissions(
            Manifest.permission.ACCESS_FINE_LOCATION,
            Manifest.permission.ACCESS_COARSE_LOCATION,
        )
        val controller = service()
        warmUp(controller)

        // The notification is removed again on stop; its id stays.
        assertNotEquals(0, shadowOf(controller.get()).lastForegroundNotificationId)
        assertTrue(shadowOf(controller.get()).isStoppedBySelf)
    }

    // Android 14+ refuses the location type without the permission, so the
    // contract can only be met before it.
    @Test
    @Config(sdk = [33])
    fun aStartWithoutLocationPermissionEntersTheForegroundBeforeStopping() {
        store.saveSession(session())
        shadowOf(application).denyPermissions(
            Manifest.permission.ACCESS_FINE_LOCATION,
            Manifest.permission.ACCESS_COARSE_LOCATION,
        )
        val controller = service()
        controller.get().onStartCommand(Intent(application, ActivityRecorderService::class.java).apply {
            action = ActivityRecorderService.ACTION_START
        }, 0, 1)

        // The notification is removed again on stop; its id stays.
        assertNotEquals(0, shadowOf(controller.get()).lastForegroundNotificationId)
        assertTrue(shadowOf(controller.get()).isStoppedBySelf)
        assertEquals(ActiveActivitySessionData.STATUS_FAILED, store.loadSession()?.status)
    }

    @Test
    fun aStartWithNoLocationProviderStopsTheService() {
        shadowOf(locations).setProviderEnabled(LocationManager.GPS_PROVIDER, false)
        shadowOf(locations).setProviderEnabled(LocationManager.NETWORK_PROVIDER, false)
        store.saveSession(session())
        val controller = service()
        controller.get().onStartCommand(Intent(application, ActivityRecorderService::class.java).apply {
            action = ActivityRecorderService.ACTION_START
        }, 0, 1)

        assertEquals(ActiveActivitySessionData.STATUS_FAILED, store.loadSession()?.status)
        assertTrue(shadowOf(controller.get()).isForegroundStopped)
        assertTrue(shadowOf(controller.get()).isStoppedBySelf)
    }

    @Test
    fun aFailedStickyRestartDoesNotCountTheDeadGapAndTellsTheUser() {
        shadowOf(application).grantPermissions(Manifest.permission.POST_NOTIFICATIONS)
        val startedMillis = System.currentTimeMillis() - 600_000
        store.saveSession(session().copy(startedAt = IsoTime.format(Date(startedMillis))))
        store.appendPoints(listOf(RecordedActivityPointData(
            timestamp = IsoTime.format(Date(startedMillis + 60_000)),
            latitude = 41.1,
            longitude = -8.0,
            segmentIndex = 0,
        )))
        shadowOf(application).denyPermissions(
            Manifest.permission.ACCESS_FINE_LOCATION,
            Manifest.permission.ACCESS_COARSE_LOCATION,
        )

        val controller = service()
        controller.get().onStartCommand(null, 0, 1)

        val failed = store.loadSession()!!
        assertEquals(ActiveActivitySessionData.STATUS_FAILED, failed.status)
        // Recorded until the last point, not through the nine dead minutes.
        assertTrue(failed.elapsedDurationSeconds in 60..62)
        assertTrue(shadowOf(controller.get()).isStoppedBySelf)
        val notifications = application.getSystemService(android.app.NotificationManager::class.java)
        assertEquals(1, shadowOf(notifications).allNotifications.size)
    }

    @Test
    fun aStickyRestartRefusedTheForegroundIsRebasedBeforeFailing() {
        shadowOf(application).grantPermissions(Manifest.permission.POST_NOTIFICATIONS)
        val startedMillis = System.currentTimeMillis() - 600_000
        store.saveSession(session().copy(startedAt = IsoTime.format(Date(startedMillis))))
        store.appendPoints(listOf(RecordedActivityPointData(
            timestamp = IsoTime.format(Date(startedMillis + 120_000)),
            latitude = 41.1,
            longitude = -8.0,
            segmentIndex = 0,
        )))

        val controller = service()
        shadowOf(controller.get()).setThrowInStartForeground(SecurityException("background"))
        controller.get().onStartCommand(null, 0, 1)

        val failed = store.loadSession()!!
        assertEquals(ActiveActivitySessionData.STATUS_FAILED, failed.status)
        assertTrue(failed.elapsedDurationSeconds in 120..122)
        assertTrue(shadowOf(controller.get()).isStoppedBySelf)
        val notifications = application.getSystemService(android.app.NotificationManager::class.java)
        assertEquals(1, shadowOf(notifications).allNotifications.size)
    }

    @Test
    fun recordingStartsInsideTheWarmUpServiceWithoutStartingAnotherOne() {
        val controller = service()
        warmUp(controller)
        fix(41.0)

        store.saveSession(session())
        ActivityRecorderService.start(application, null, null)
        shadowOf(Looper.getMainLooper()).idle()

        // No new service start: Android would refuse it, or grant it no
        // location, if the user had switched apps by now.
        assertNull(shadowOf(application).nextStartedService)
        fix(41.1)
        assertEquals(1, store.pointCount())

        // Ending the warm-up afterwards leaves the recording running.
        ActivityRecorderService.endWarmUp()
        assertFalse(shadowOf(controller.get()).isStoppedBySelf)
        fix(41.2, System.currentTimeMillis() + 1_000)
        assertEquals(2, store.pointCount())
    }

    @Test
    fun endingTheWarmUpWithoutARecordingStopsTheService() {
        val controller = service()
        warmUp(controller)

        ActivityRecorderService.endWarmUp()

        assertTrue(shadowOf(controller.get()).isStoppedBySelf)
        assertTrue(shadowOf(controller.get()).isForegroundStopped)
        assertNull(store.loadSession())
    }

    @Test
    fun warmUpIsIgnoredWhileARecordingOwnsTheService() {
        store.saveSession(session())
        val controller = service()
        controller.get().onStartCommand(Intent(application, ActivityRecorderService::class.java).apply {
            action = ActivityRecorderService.ACTION_START
        }, 0, 1)

        warmUp(controller)
        ActivityRecorderService.endWarmUp()
        fix(41.1)

        assertFalse(shadowOf(controller.get()).isStoppedBySelf)
        assertEquals(1, store.pointCount())
    }

    @Test
    fun startWithoutAWarmUpStartsTheServiceAsBefore() {
        store.saveSession(session())

        ActivityRecorderService.start(application, null, null)

        assertEquals(
            ActivityRecorderService.ACTION_START,
            shadowOf(application).nextStartedService?.action,
        )
    }

    @Test
    fun liveRecoveryAndTaskRemovalKeepTheSameRecordingRunning() {
        val original = session()
        store.saveSession(original)
        val controller = service()
        controller.get().onStartCommand(Intent(application, ActivityRecorderService::class.java).apply {
            action = ActivityRecorderService.ACTION_START
        }, 0, 1)
        fix(41.1)
        assertEquals(1, store.pointCount())

        controller.get().onTaskRemoved(Intent())
        assertEquals(original, ActivityRecorderCoordinator.recover(application))
        assertEquals(original, ActivityRecorderCoordinator.recover(application))
        assertNull(shadowOf(application).nextStartedService)
        assertFalse(shadowOf(controller.get()).isStoppedBySelf)
        fix(41.2, System.currentTimeMillis() + 1_000)

        assertEquals(listOf(0, 0), store.readPoints().map { it.segmentIndex })
        assertEquals(original.localSessionId, store.loadSession()?.localSessionId)
    }

    @Test
    fun recoveryRestartsCollectionAndBeginsANewSegment() {
        val original = session()
        store.saveSession(original)
        store.appendPoints(listOf(RecordedActivityPointData(
            timestamp = IsoTime.format(Date(System.currentTimeMillis() - 1_000)),
            latitude = 41.1,
            longitude = -8.0,
            segmentIndex = 0,
        )))

        val recovered = ActivityRecorderCoordinator.recover(application)!!
        assertEquals(original.localSessionId, recovered.localSessionId)
        assertEquals(original.connectionProfileId, recovered.connectionProfileId)
        assertEquals(ActiveActivitySessionData.STATUS_RECORDING, recovered.status)
        assertNotNull(recovered.resumedAt)
        val intent = shadowOf(application).nextStartedService!!
        val controller = service()
        controller.get().onStartCommand(intent, 0, 1)
        fix(41.2)

        assertEquals(listOf(0, 1), store.readPoints().map { it.segmentIndex })
    }

    @Test
    fun stickyRestartPreservesTheSessionAndRestartsCollection() {
        store.saveSession(session())
        val controller = service()
        assertEquals(android.app.Service.START_STICKY, controller.get().onStartCommand(null, 0, 1))
        fix(41.1)

        assertEquals("existing_session", store.loadSession()?.localSessionId)
        assertEquals(1, store.pointCount())
    }

    @Test
    fun pausedAndFailedSessionsAreNotAutomaticallyStarted() {
        for (status in listOf(
            ActiveActivitySessionData.STATUS_PAUSED,
            ActiveActivitySessionData.STATUS_FAILED,
        )) {
            store.saveSession(session(status))
            val recovered = ActivityRecorderCoordinator.recover(application)!!
            assertEquals(ActiveActivitySessionData.STATUS_PAUSED, recovered.status)
            assertEquals("existing_session", recovered.localSessionId)
            assertNull(shadowOf(application).nextStartedService)
        }
    }

    @Test
    fun recoveryBeforeFirstFixDoesNotDiscardTheSession() {
        store.saveSession(session())
        val recovered = ActivityRecorderCoordinator.recover(application)!!
        assertEquals(ActiveActivitySessionData.STATUS_RECORDING, recovered.status)
        assertEquals(0, store.pointCount())
        assertNotNull(store.loadSession())
        val controller = service()
        controller.get().onStartCommand(shadowOf(application).nextStartedService!!, 0, 1)
        fix(41.1)
        assertEquals(1, store.pointCount())
    }

    @Test
    fun recoveryWithoutPermissionStartsNoServiceAndKeepsDurablePoints() {
        store.saveSession(session())
        store.appendPoints(listOf(RecordedActivityPointData(
            timestamp = IsoTime.nowUtc(), latitude = 41.1, longitude = -8.0, segmentIndex = 0,
        )))
        shadowOf(application).denyPermissions(
            Manifest.permission.ACCESS_FINE_LOCATION,
            Manifest.permission.ACCESS_COARSE_LOCATION,
        )

        val recovered = ActivityRecorderCoordinator.recover(application)

        assertEquals(ActiveActivitySessionData.STATUS_PAUSED, recovered?.status)
        assertEquals(ActiveActivitySessionData.STATUS_PAUSED, store.loadSession()?.status)
        assertNull(shadowOf(application).nextStartedService)
        assertEquals(1, store.pointCount())
    }

    @Test
    fun deniedPermissionKeepsDurablePointsForExplicitRecovery() {
        // A permission revoked after recover() checked it: the reconnect
        // intent still arrives, and the service must fail safely on its own.
        store.saveSession(session())
        store.appendPoints(listOf(RecordedActivityPointData(
            timestamp = IsoTime.nowUtc(), latitude = 41.1, longitude = -8.0, segmentIndex = 0,
        )))
        shadowOf(application).denyPermissions(
            Manifest.permission.ACCESS_FINE_LOCATION,
            Manifest.permission.ACCESS_COARSE_LOCATION,
        )
        val controller = service()
        controller.get().onStartCommand(Intent(application, ActivityRecorderService::class.java).apply {
            action = ActivityRecorderService.ACTION_RECONNECT
        }, 0, 1)
        shadowOf(Looper.getMainLooper()).idle()

        assertEquals(ActiveActivitySessionData.STATUS_FAILED, store.loadSession()?.status)
        assertEquals(1, store.pointCount())
        assertTrue(shadowOf(controller.get()).isStoppedBySelf)
        assertEquals(
            ActiveActivitySessionData.STATUS_PAUSED,
            ActivityRecorderCoordinator.recover(application)?.status,
        )
    }

    @Test
    fun pointEventsIncludeSessionIdentityAndDurableOffset() {
        val events = mutableListOf<Map<*, *>>()
        ActivityRecorderCoordinator.attach(object : EventChannel.EventSink {
            override fun success(event: Any?) { events.add(event as Map<*, *>) }
            override fun error(code: String, message: String?, details: Any?) = Unit
            override fun endOfStream() = Unit
        })
        store.saveSession(session())
        val controller = service()
        controller.get().onStartCommand(Intent(application, ActivityRecorderService::class.java).apply {
            action = ActivityRecorderService.ACTION_START
        }, 0, 1)
        fix(41.1)
        fix(41.2, System.currentTimeMillis() + 1_000)
        val batches = events.filter { it["type"] == "pointBatchAvailable" }

        assertEquals(listOf(0, 1), batches.map { it["pointOffset"] })
        assertTrue(batches.all { it["localSessionId"] == "existing_session" })
        assertTrue(batches.all { it["version"] == ActivityRecorderChannel.PAYLOAD_VERSION })
    }

    @Test
    fun pauseAndStopAreDeliveredBeforeTheServiceIsCreated() {
        // start() hands the intent to the system; onCreate runs later. A stop
        // sent in that window must still reach the service.
        ActivityRecorderService.pause(application)
        ActivityRecorderService.stop(application)

        assertEquals(
            ActivityRecorderService.ACTION_PAUSE,
            shadowOf(application).nextStartedService?.action,
        )
        assertEquals(
            ActivityRecorderService.ACTION_STOP,
            shadowOf(application).nextStartedService?.action,
        )
    }

    @Test
    fun pauseAndStopReachARunningService() {
        service()

        ActivityRecorderService.pause(application)
        ActivityRecorderService.stop(application)

        assertEquals(
            ActivityRecorderService.ACTION_PAUSE,
            shadowOf(application).nextStartedService?.action,
        )
        assertEquals(
            ActivityRecorderService.ACTION_STOP,
            shadowOf(application).nextStartedService?.action,
        )
    }

    @Test
    fun pauseSurvivesAnApplicationThatCannotStartServices() {
        service()
        val refusing = object : android.content.ContextWrapper(application) {
            override fun startService(service: Intent?): android.content.ComponentName? =
                throw IllegalStateException("app is in the background")
        }

        ActivityRecorderService.pause(refusing)
        ActivityRecorderService.stop(refusing)
    }
}
