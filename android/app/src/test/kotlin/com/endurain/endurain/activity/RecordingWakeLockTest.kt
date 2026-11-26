package com.endurain.endurain.activity

import android.app.Application
import android.os.Looper
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import java.time.Duration

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [35], application = Application::class)
class RecordingWakeLockTest {
    private val application: Application = RuntimeEnvironment.getApplication()
    private var nowMillis = 0L

    private fun wakeLock() = RecordingWakeLock(application) { nowMillis }

    private fun latest() = org.robolectric.shadows.ShadowPowerManager.getLatestWakeLock()

    @Test
    fun acquiresATaggedLock() {
        val lock = wakeLock()
        lock.acquire()

        assertTrue(lock.isHeld)
        assertNotNull(latest())
        assertEquals(RecordingWakeLock.WAKE_LOCK_TAG, shadowOf(latest()).tag)
        lock.release()
    }

    @Test
    fun releaseDropsTheLockAndStopsRenewing() {
        val lock = wakeLock()
        lock.acquire()
        lock.release()

        assertFalse(lock.isHeld)
        assertFalse(latest().isHeld)
        assertFalse(lock.renew(force = true))
        shadowOf(Looper.getMainLooper()).idleFor(Duration.ofMinutes(20))
        assertFalse(latest().isHeld)
    }

    @Test
    fun theLockIsRenewedPeriodicallyWhileHeld() {
        val lock = wakeLock()
        lock.acquire()
        shadowOf(Looper.getMainLooper()).idleFor(
            Duration.ofMillis(RecordingWakeLock.RENEW_INTERVAL_MILLIS + 1),
        )

        assertTrue(lock.isHeld)
        assertTrue(shadowOf(latest()).timesHeld > 1)
        lock.release()
    }

    @Test
    fun renewIsThrottledUnlessForced() {
        val lock = wakeLock()
        lock.acquire()
        val initial = shadowOf(latest()).timesHeld

        // Within the throttle window nothing changes.
        nowMillis += RecordingWakeLock.MIN_RENEW_GAP_MILLIS - 1
        assertTrue(lock.renew())
        assertEquals(initial, shadowOf(latest()).timesHeld)

        nowMillis += 2
        assertTrue(lock.renew())
        assertEquals(initial + 1, shadowOf(latest()).timesHeld)
        lock.release()
    }
}
