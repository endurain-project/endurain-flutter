package com.endurain.endurain.activity

import android.os.Handler
import android.os.Looper

/** Runs [task] after [delayMillis]; the returned handle cancels it. */
internal fun interface ReconnectScheduler {
    fun schedule(delayMillis: Long, task: Runnable): () -> Unit
}

internal class MainLooperReconnectScheduler : ReconnectScheduler {
    private val handler = Handler(Looper.getMainLooper())

    override fun schedule(delayMillis: Long, task: Runnable): () -> Unit {
        handler.postDelayed(task, delayMillis)
        return { handler.removeCallbacks(task) }
    }
}

/**
 * Decides when a failed GATT link is rebuilt: exponential backoff (1 s, 2 s,
 * 4 s ... capped at [maxDelayMillis]) for at most [maxAttempts] consecutive
 * failures, so a sensor that is gone for good does not keep the radio busy for
 * the rest of the recording.
 *
 * [onReconnect] runs on the scheduler's thread once the delay has elapsed. A
 * successful link calls [reset] so the budget applies per outage, not per
 * recording.
 */
internal class GattReconnectController(
    private val scheduler: ReconnectScheduler,
    private val onReconnect: () -> Unit,
    private val initialDelayMillis: Long = INITIAL_DELAY_MILLIS,
    private val maxDelayMillis: Long = MAX_DELAY_MILLIS,
    private val maxAttempts: Int = MAX_ATTEMPTS,
) {
    private var attempts = 0
    private var cancelPending: (() -> Unit)? = null

    /**
     * Schedules a reconnect. Returns `false` (and schedules nothing) when the
     * attempt budget is spent or a reconnect is already pending.
     */
    @Synchronized
    fun onFailure(): Boolean {
        if (cancelPending != null || attempts >= maxAttempts) {
            return false
        }
        val delay = delayForAttempt(attempts)
        attempts++
        cancelPending = scheduler.schedule(delay) {
            synchronized(this) { cancelPending = null }
            onReconnect()
        }
        return true
    }

    /** Clears the failure count after a link that completed setup. */
    @Synchronized
    fun reset() {
        attempts = 0
    }

    /** Drops any pending reconnect and the failure count. */
    @Synchronized
    fun cancel() {
        cancelPending?.invoke()
        cancelPending = null
        attempts = 0
    }

    private fun delayForAttempt(attempt: Int): Long {
        val shift = attempt.coerceAtMost(MAX_SHIFT)
        return (initialDelayMillis shl shift).coerceAtMost(maxDelayMillis)
    }

    companion object {
        const val INITIAL_DELAY_MILLIS = 1_000L
        const val MAX_DELAY_MILLIS = 30_000L
        const val MAX_ATTEMPTS = 8
        private const val MAX_SHIFT = 20
    }
}
