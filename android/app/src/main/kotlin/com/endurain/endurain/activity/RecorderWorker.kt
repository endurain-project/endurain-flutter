package com.endurain.endurain.activity

import android.os.Handler
import android.os.HandlerThread
import android.os.Looper
import androidx.annotation.VisibleForTesting

/**
 * The background thread that owns the recorder's session state.
 *
 * Location callbacks, the per-fix store reads and writes (a session save ends
 * in `fd.sync()`), announcement timers, the wake-lock renewal and every
 * service command run on [looper], never on the main thread, so a slow disk
 * cannot drop frames or trigger an ANR while the app is visible.
 *
 * Thread ownership inside [ActivityRecorderService]: everything that is not
 * `@Volatile` (session processing state, sensor clients, collector, wake lock,
 * announcement driver) is touched only on this thread. The main thread only
 * posts commands here ([run]) and receives Flutter event-sink callbacks, which
 * [ActivityRecorderCoordinator] posts back to it. Because one looper runs every
 * task in order, fixes and commands never interleave.
 */
internal class RecorderWorker private constructor(
    private val thread: HandlerThread?,
    val looper: Looper,
) {
    val handler = Handler(looper)

    private val isCurrent: Boolean
        get() = Looper.myLooper() === looper

    /** Runs [block] on the worker: inline when already there, otherwise posted. */
    fun run(block: () -> Unit) {
        if (isCurrent) {
            block()
        } else {
            handler.post(block)
        }
    }

    /** Ends the thread after the tasks already posted ran. Idempotent. */
    fun quitWhenIdle() {
        thread?.quitSafely()
    }

    companion object {
        private const val THREAD_NAME = "endurain-recorder"

        /**
         * Tests set this to the main looper so service commands and fixes run
         * synchronously on the test thread under Robolectric's paused looper.
         * Never set in production.
         */
        @VisibleForTesting
        @Volatile
        internal var looperOverride: Looper? = null

        fun create(): RecorderWorker {
            looperOverride?.let { return RecorderWorker(null, it) }
            val thread = HandlerThread(THREAD_NAME).also { it.start() }
            return RecorderWorker(thread, thread.looper)
        }
    }
}
