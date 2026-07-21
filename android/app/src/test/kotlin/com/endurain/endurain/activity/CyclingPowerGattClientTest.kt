package com.endurain.endurain.activity

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

/**
 * JVM unit tests for the GATT Cycling Power Measurement (`0x2A63`) byte parsing.
 *
 * The BLE connection itself is a device-only concern, but the wire-format
 * decoding is pure and lives here so a regression is caught without hardware.
 */
class CyclingPowerGattClientTest {

    @Test
    fun parsesInstantaneousPower() {
        // UINT16 flags then SINT16 power (little-endian) = 250 W.
        assertEquals(
            250,
            CyclingPowerGattClient.parsePowerWatts(
                byteArrayOf(0x00, 0x00, 0xFA.toByte(), 0x00),
            ),
        )
    }

    @Test
    fun parsesPowerAbove255() {
        // 0x012C little-endian = 300 W.
        assertEquals(
            300,
            CyclingPowerGattClient.parsePowerWatts(
                byteArrayOf(0x30, 0x00, 0x2C, 0x01),
            ),
        )
    }

    @Test
    fun clampsNegativePowerToZero() {
        // 0xFFFB little-endian = -5 W -> clamped to 0.
        assertEquals(
            0,
            CyclingPowerGattClient.parsePowerWatts(
                byteArrayOf(0x00, 0x00, 0xFB.toByte(), 0xFF.toByte()),
            ),
        )
    }

    @Test
    fun returnsNullForATruncatedPayload() {
        assertNull(CyclingPowerGattClient.parsePowerWatts(byteArrayOf(0x00, 0x00)))
    }
}
