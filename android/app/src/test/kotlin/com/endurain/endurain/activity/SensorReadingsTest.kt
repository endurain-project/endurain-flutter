package com.endurain.endurain.activity

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

/** JVM unit tests for BLE reading freshness and crank-cadence derivation. */
class SensorReadingsTest {

    @Test
    fun freshReadingExpiresAfterItsMaximumAge() {
        var now = 1_000L
        val reading = FreshReading(maxAgeMillis = 5_000L, clock = { now })
        assertNull(reading.value)

        reading.update(142)
        now += 5_000L
        assertEquals(142, reading.value)

        now += 1L
        assertNull(reading.value)

        reading.update(150)
        assertEquals(150, reading.value)
        reading.clear()
        assertNull(reading.value)
    }

    @Test
    fun crankCadenceNeedsABaselineSample() {
        val calculator = CrankCadenceCalculator()
        assertNull(calculator.onMeasurement(revolutions = 10, eventTime = 0, nowMillis = 0L))
        // One revolution in one second (1024 ticks) = 60 rpm.
        assertEquals(60, calculator.onMeasurement(revolutions = 11, eventTime = 1024, nowMillis = 1_000L))
    }

    @Test
    fun crankCadenceWrapsTheSixteenBitCounters() {
        val calculator = CrankCadenceCalculator()
        calculator.onMeasurement(revolutions = 0xFFFF, eventTime = 0xFE00, nowMillis = 0L)
        // +2 revolutions over 1024 ticks across both wraps = 120 rpm.
        assertEquals(120, calculator.onMeasurement(revolutions = 1, eventTime = 0x0200, nowMillis = 1_000L))
    }

    @Test
    fun crankCadenceDropsToZeroOnceTheCrankStopsAdvancing() {
        val calculator = CrankCadenceCalculator(stoppedAfterMillis = 2_500L)
        calculator.onMeasurement(revolutions = 10, eventTime = 0, nowMillis = 0L)
        assertEquals(60, calculator.onMeasurement(revolutions = 11, eventTime = 1024, nowMillis = 1_000L))

        // Same event time: a duplicate, or the rider just stopped.
        assertNull(calculator.onMeasurement(revolutions = 11, eventTime = 1024, nowMillis = 2_000L))
        assertNull(calculator.onMeasurement(revolutions = 11, eventTime = 1024, nowMillis = 3_000L))
        assertEquals(0, calculator.onMeasurement(revolutions = 11, eventTime = 1024, nowMillis = 3_500L))
        assertEquals(0, calculator.onMeasurement(revolutions = 11, eventTime = 1024, nowMillis = 4_500L))

        // Pedalling again reports a real cadence straight away.
        assertEquals(60, calculator.onMeasurement(revolutions = 12, eventTime = 2048, nowMillis = 5_000L))
    }

    @Test
    fun crankCadenceResetStartsFromANewBaseline() {
        val calculator = CrankCadenceCalculator()
        calculator.onMeasurement(revolutions = 10, eventTime = 0, nowMillis = 0L)
        calculator.reset()
        assertNull(calculator.onMeasurement(revolutions = 50, eventTime = 4096, nowMillis = 10_000L))
    }
}
