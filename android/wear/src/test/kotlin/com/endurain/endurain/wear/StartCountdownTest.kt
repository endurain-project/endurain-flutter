package com.endurain.endurain.wear

import org.junit.Assert.assertEquals
import org.junit.Test

class StartCountdownTest {
    @Test
    fun nextCyclesThroughTheOptionsAndWraps() {
        assertEquals(3, StartCountdown.next(0))
        assertEquals(5, StartCountdown.next(3))
        assertEquals(10, StartCountdown.next(5))
        assertEquals(0, StartCountdown.next(10))
    }

    @Test
    fun nextRestartsFromAnUnknownValue() {
        assertEquals(0, StartCountdown.next(7))
    }

    @Test
    fun sanitizeKeepsValidChoicesAndTurnsOthersOff() {
        assertEquals(5, StartCountdown.sanitize(5))
        assertEquals(0, StartCountdown.sanitize(42))
        assertEquals(0, StartCountdown.sanitize(-1))
    }

    @Test
    fun remainingSecondsRoundsUpUntilTheEnd() {
        assertEquals(3, StartCountdown.remainingSeconds(endsAtMillis = 10_000, nowMillis = 7_000))
        assertEquals(3, StartCountdown.remainingSeconds(endsAtMillis = 10_000, nowMillis = 7_001))
        assertEquals(1, StartCountdown.remainingSeconds(endsAtMillis = 10_000, nowMillis = 9_999))
        assertEquals(0, StartCountdown.remainingSeconds(endsAtMillis = 10_000, nowMillis = 10_000))
        assertEquals(0, StartCountdown.remainingSeconds(endsAtMillis = 10_000, nowMillis = 12_000))
    }
}
