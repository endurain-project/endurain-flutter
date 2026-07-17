package com.endurain.endurain.activity

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

/**
 * JVM unit tests for the GATT Heart Rate Measurement (`0x2A37`) byte parsing.
 *
 * The BLE connection itself is a device-only concern, but the wire-format
 * decoding is pure and lives here so a regression (e.g. dropping 16-bit values)
 * is caught without hardware.
 */
class HeartRateGattClientTest {

    @Test
    fun parsesAn8BitHeartRate() {
        // Flags 0x00 => 8-bit value; 0x48 = 72 bpm.
        assertEquals(72, HeartRateGattClient.parseHeartRate(byteArrayOf(0x00, 0x48)))
    }

    @Test
    fun parsesA16BitHeartRateAbove255() {
        // Flag bit 0 set => UINT16 little-endian 0x012C = 300.
        assertEquals(
            300,
            HeartRateGattClient.parseHeartRate(byteArrayOf(0x01, 0x2C, 0x01)),
        )
    }

    @Test
    fun ignoresContactFlagsWhenReadingAn8BitValue() {
        // Flags 0x06 (sensor-contact bits) still carry an 8-bit value; 0x41 = 65.
        assertEquals(65, HeartRateGattClient.parseHeartRate(byteArrayOf(0x06, 0x41)))
    }

    @Test
    fun returnsNullForEmptyData() {
        assertNull(HeartRateGattClient.parseHeartRate(byteArrayOf()))
    }

    @Test
    fun returnsNullForATruncated16BitValue() {
        assertNull(HeartRateGattClient.parseHeartRate(byteArrayOf(0x01, 0x2C)))
    }

    @Test
    fun returnsNullForAMissing8BitValue() {
        assertNull(HeartRateGattClient.parseHeartRate(byteArrayOf(0x00)))
    }
}
