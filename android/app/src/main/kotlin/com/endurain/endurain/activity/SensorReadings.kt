package com.endurain.endurain.activity

import android.os.SystemClock

/**
 * The latest value of one BLE sensor stream, which reads as `null` once it is
 * older than [maxAgeMillis].
 *
 * A sensor that stops notifying without disconnecting (out of range before the
 * link times out, strap taken off, a stuck stream) would otherwise keep
 * stamping its last value onto every point. Written from the GATT callback
 * thread and read from the service's main thread, so the value and its time
 * are published together as one immutable sample.
 */
internal class FreshReading(
    private val maxAgeMillis: Long = DEFAULT_MAX_AGE_MILLIS,
    private val clock: () -> Long = SystemClock::elapsedRealtime,
) {
    private class Sample(val value: Int, val atMillis: Long)

    @Volatile
    private var sample: Sample? = null

    /** The value, or `null` when none was received in the last [maxAgeMillis]. */
    val value: Int?
        get() {
            val current = sample ?: return null
            return if (clock() - current.atMillis <= maxAgeMillis) current.value else null
        }

    fun update(value: Int) {
        sample = Sample(value, clock())
    }

    fun clear() {
        sample = null
    }

    companion object {
        const val DEFAULT_MAX_AGE_MILLIS = 5_000L
    }
}

/**
 * Derives cycling cadence from consecutive CSC crank measurements.
 *
 * The crank counter and event time only advance when the crank completes a
 * revolution, so a rider who stops pedalling keeps sending notifications with
 * an unchanged event time. Once that lasts [stoppedAfterMillis], the cadence is
 * reported as 0 instead of keeping the last pedalling RPM.
 */
internal class CrankCadenceCalculator(
    private val stoppedAfterMillis: Long = DEFAULT_STOPPED_AFTER_MILLIS,
) {
    private var previousRevolutions: Int? = null
    private var previousEventTime: Int? = null
    private var lastAdvanceAtMillis: Long? = null

    /**
     * Feeds one measurement received at [nowMillis]. Returns the new cadence in
     * RPM, or `null` when there is nothing new to report (the baseline sample,
     * or a repeated event time that does not yet mean the crank stopped).
     */
    fun onMeasurement(revolutions: Int, eventTime: Int, nowMillis: Long): Int? {
        val lastRevolutions = previousRevolutions
        val lastEventTime = previousEventTime
        previousRevolutions = revolutions
        previousEventTime = eventTime
        if (lastRevolutions == null || lastEventTime == null) {
            lastAdvanceAtMillis = nowMillis
            return null
        }
        val deltaRevolutions = (revolutions - lastRevolutions) and 0xFFFF
        val deltaTime = (eventTime - lastEventTime) and 0xFFFF
        if (deltaTime == 0) {
            val since = lastAdvanceAtMillis ?: nowMillis
            return if (nowMillis - since >= stoppedAfterMillis) 0 else null
        }
        lastAdvanceAtMillis = nowMillis
        // One crank event time tick is 1/1024 s; 60 s/min * 1024 ticks/s.
        return (deltaRevolutions * 60 * 1024) / deltaTime
    }

    fun reset() {
        previousRevolutions = null
        previousEventTime = null
        lastAdvanceAtMillis = null
    }

    companion object {
        const val DEFAULT_STOPPED_AFTER_MILLIS = 2_500L
    }
}
