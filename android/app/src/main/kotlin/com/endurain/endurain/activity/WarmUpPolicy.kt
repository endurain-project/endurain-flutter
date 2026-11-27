package com.endurain.endurain.activity

/** Sizing of the start-countdown warm-up's safety timeout. */
internal object WarmUpPolicy {
    /**
     * Leak guard for a warm-up nobody ended (Dart died mid-countdown), used
     * when the countdown length is unknown. Longer than the longest
     * countdown Dart allows (StartCountdown's 10-minute maxRemaining), so
     * it never ends a live countdown early. Also the upper clamp of
     * [timeoutMillis].
     */
    const val MAX_TIMEOUT_MILLIS = 11 * 60_000L

    /** Lower clamp of [timeoutMillis]. */
    const val MIN_TIMEOUT_MILLIS = 60_000L

    /** Slack past the countdown's end before the warm-up is ended anyway. */
    private const val MARGIN_MILLIS = 60_000L

    /**
     * The warm-up's safety timeout: the countdown plus a minute, clamped
     * to [[MIN_TIMEOUT_MILLIS], [MAX_TIMEOUT_MILLIS]], so a leaked warm-up of
     * a short countdown does not hold a location foreground service for 11
     * minutes. [MAX_TIMEOUT_MILLIS] when [countdownSeconds] is unknown (an
     * older Dart build).
     */
    fun timeoutMillis(countdownSeconds: Long?): Long {
        if (countdownSeconds == null) {
            return MAX_TIMEOUT_MILLIS
        }
        // Bounded first so the multiplication cannot overflow.
        val countdownMillis =
            countdownSeconds.coerceIn(0L, MAX_TIMEOUT_MILLIS / 1000L) * 1000L
        return (countdownMillis + MARGIN_MILLIS)
            .coerceIn(MIN_TIMEOUT_MILLIS, MAX_TIMEOUT_MILLIS)
    }
}
