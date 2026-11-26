package com.endurain.endurain.wear

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/**
 * Runs the start countdown: cues the last seconds and reports when it ends.
 * Cancelling it (or skipping it) never calls [onFinished].
 */
class CountdownController(
    private val scope: CoroutineScope,
    private val nowMillis: () -> Long,
    private val onCue: () -> Unit,
    private val onFinished: suspend () -> Unit,
    private val tickMillis: Long = TICK_MILLIS,
) {
    private var job: Job? = null

    fun start(endsAtMillis: Long) {
        cancel()
        job = scope.launch { run(endsAtMillis) }
    }

    fun cancel() {
        job?.cancel()
        job = null
    }

    private suspend fun run(endsAtMillis: Long) {
        var lastCue: Int? = null
        while (true) {
            val seconds = StartCountdown.remainingSeconds(endsAtMillis, nowMillis())
            if (seconds <= 0) break
            if (seconds <= StartCountdown.CUE_SECONDS && seconds != lastCue) {
                lastCue = seconds
                onCue()
            }
            delay(tickMillis)
        }
        job = null
        onFinished()
    }

    companion object {
        const val TICK_MILLIS = 200L
    }
}
