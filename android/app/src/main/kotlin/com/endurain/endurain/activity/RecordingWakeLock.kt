package com.endurain.endurain.activity

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.os.PowerManager

/**
 * Partial wake lock held while location is being collected.
 *
 * A foreground service is not kept awake by itself: between distance-filtered
 * GPS fixes the AP can suspend, which drops BLE `onCharacteristicChanged`
 * callbacks and delays the `points.jsonl` append that must happen on the same
 * wake window. This is what the declared `WAKE_LOCK` permission is for.
 *
 * The lock carries a [TIMEOUT_MILLIS] timeout and is renewed every
 * [RENEW_INTERVAL_MILLIS] (and on demand, throttled, from each fix) while it is
 * held. A missed [release] therefore frees the CPU after at most the timeout
 * instead of draining the battery until the process dies, yet an
 * ultra-distance recording never loses it.
 */
internal class RecordingWakeLock(
    private val context: Context,
    private val handler: Handler = Handler(Looper.getMainLooper()),
    private val clock: () -> Long = android.os.SystemClock::elapsedRealtime,
) {
    private var wakeLock: PowerManager.WakeLock? = null
    private var lastAcquiredAtMillis = 0L

    private val renewTick = object : Runnable {
        override fun run() {
            if (renew(force = true)) {
                handler.postDelayed(this, RENEW_INTERVAL_MILLIS)
            }
        }
    }

    val isHeld: Boolean
        get() = wakeLock?.isHeld == true

    fun acquire() {
        if (isHeld) {
            return
        }
        val powerManager = context.getSystemService(Context.POWER_SERVICE) as? PowerManager
            ?: return
        val lock = powerManager.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, WAKE_LOCK_TAG)
        lock.setReferenceCounted(false)
        try {
            lock.acquire(TIMEOUT_MILLIS)
        } catch (_: RuntimeException) {
            // Losing the wake lock degrades sampling but must never abort the
            // recording; GPS delivery still holds its own wakelock per fix.
            return
        }
        wakeLock = lock
        lastAcquiredAtMillis = clock()
        handler.removeCallbacks(renewTick)
        handler.postDelayed(renewTick, RENEW_INTERVAL_MILLIS)
    }

    /**
     * Extends the timeout of a held lock. Without [force] it does nothing until
     * [MIN_RENEW_GAP_MILLIS] passed since the last extension, so calling it on
     * every fix costs one clock read. Returns whether the lock is still held.
     */
    fun renew(force: Boolean = false): Boolean {
        val lock = wakeLock ?: return false
        if (!force && clock() - lastAcquiredAtMillis < MIN_RENEW_GAP_MILLIS) {
            return true
        }
        return try {
            lock.acquire(TIMEOUT_MILLIS)
            lastAcquiredAtMillis = clock()
            true
        } catch (_: RuntimeException) {
            false
        }
    }

    fun release() {
        handler.removeCallbacks(renewTick)
        val lock = wakeLock ?: return
        wakeLock = null
        try {
            if (lock.isHeld) {
                lock.release()
            }
        } catch (_: RuntimeException) {
            // Already released or never held.
        }
    }

    companion object {
        /** Namespaced so this lock is attributable in `dumpsys power`. */
        const val WAKE_LOCK_TAG = "endurain:activity-recording"
        const val TIMEOUT_MILLIS = 10 * 60_000L
        const val RENEW_INTERVAL_MILLIS = 5 * 60_000L
        const val MIN_RENEW_GAP_MILLIS = 60_000L
    }
}
