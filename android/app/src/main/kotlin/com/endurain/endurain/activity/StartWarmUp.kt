package com.endurain.endurain.activity

import android.app.Service
import android.content.Intent

/**
 * Keeps the app alive during the start countdown.
 *
 * On newer Android versions an app the user switched away from can be
 * frozen within seconds, which would stall the countdown. A foreground
 * service prevents that. It is started while the app is still in the
 * foreground, so it gets location access now; when the countdown ends the
 * recording starts inside this same service (see
 * [ActivityRecorderService.start]) instead of starting a new one from the
 * background, which Android would refuse or grant without location. GPS runs
 * meanwhile, so the first point is accurate, but every fix is dropped and
 * nothing is stored.
 *
 * The safety timeout is sized from the countdown length the channel put in
 * [ActivityRecorderService.EXTRA_COUNTDOWN_SECONDS]; see
 * [WarmUpPolicy.timeoutMillis]. Used only on the recorder thread; [isActive]
 * may be read from any thread.
 */
internal class StartWarmUp(
    private val service: Service,
    private val worker: RecorderWorker,
    private val collector: RecorderLocationCollector,
    private val foreground: ForegroundServiceCompat,
    private val notifications: RecorderNotifications,
    private val hasLocationPermission: () -> Boolean,
    private val recordingOwnsService: () -> Boolean,
) {
    /** Whether the service only keeps the app alive for a start countdown. */
    @Volatile
    var isActive = false
        private set

    /** Ends a warm-up that no recording and no `endStartWarmUp` ever ended. */
    private val timeoutRunnable = Runnable { finish() }

    fun begin(intent: Intent) {
        if (recordingOwnsService()) {
            // A recording already owns this service. A fresh instance started
            // just for this warm-up must still enter the foreground before it
            // stops.
            if (!foreground.inForeground) {
                foreground.stopBeforeForegroundWork()
            }
            return
        }
        if (!hasLocationPermission()) {
            foreground.stopBeforeForegroundWork()
            return
        }
        try {
            // Declares `connectedDevice` whenever it is permitted, before the
            // session says whether a sensor is bound: the recording that starts
            // from this service may then keep or drop the type, but never has
            // to add one while the app is in the background.
            foreground.start(
                notifications.defaultTitle(),
                notifications.startingText(),
                connectedDevice = foreground.hasConnectedDevicePermission(),
            )
        } catch (_: RuntimeException) {
            service.stopSelf()
            return
        }
        isActive = true
        collector.startWarmUp()
        worker.handler.removeCallbacks(timeoutRunnable)
        val countdownSeconds =
            if (intent.hasExtra(ActivityRecorderService.EXTRA_COUNTDOWN_SECONDS)) {
                intent.getLongExtra(ActivityRecorderService.EXTRA_COUNTDOWN_SECONDS, 0L)
            } else {
                null
            }
        worker.handler.postDelayed(timeoutRunnable, WarmUpPolicy.timeoutMillis(countdownSeconds))
    }

    /** Hands the service over to a recording starting from the warm-up. */
    fun handOver() {
        collector.stopWarmUp()
        cancelTimeout()
        isActive = false
    }

    /** Drops the pending safety timeout. */
    fun cancelTimeout() {
        worker.handler.removeCallbacks(timeoutRunnable)
    }

    /** Ends the warm-up when no recording started from it. */
    fun finish() {
        cancelTimeout()
        if (!isActive) {
            return
        }
        isActive = false
        collector.stopWarmUp()
        foreground.stop()
        service.stopSelf()
    }
}
