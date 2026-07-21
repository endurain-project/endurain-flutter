package com.endurain.endurain.activity

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

/**
 * JVM unit tests for the GATT CSC (`0x2A5B`) and RSC (`0x2A53`) cadence byte
 * parsing.
 *
 * The BLE connection and the stateful crank-to-RPM derivation are device/runtime
 * concerns; the pure wire-format extraction is tested here without hardware.
 */
class CadenceGattClientTest {

    @Test
    fun parsesCrankOnlyCscMeasurement() {
        // Flags 0x02 (crank present), crank revs = 100, event time = 1024.
        val crank = CadenceGattClient.parseCscCrank(
            byteArrayOf(0x02, 0x64, 0x00, 0x00, 0x04),
        )
        assertEquals(100, crank?.first)
        assertEquals(1024, crank?.second)
    }

    @Test
    fun skipsWheelDataToReadCrankData() {
        // Flags 0x03 (wheel + crank). Wheel = 6 bytes, then crank revs = 50,
        // event time = 2048 (0x0800).
        val crank = CadenceGattClient.parseCscCrank(
            byteArrayOf(
                0x03,
                0x10, 0x00, 0x00, 0x00, // wheel revolutions (uint32)
                0x00, 0x02, // wheel event time (uint16)
                0x32, 0x00, // crank revolutions = 50
                0x00, 0x08, // crank event time = 2048
            ),
        )
        assertEquals(50, crank?.first)
        assertEquals(2048, crank?.second)
    }

    @Test
    fun returnsNullWhenNoCrankDataPresent() {
        // Flags 0x01 (wheel only) -> no cadence to derive.
        assertNull(
            CadenceGattClient.parseCscCrank(
                byteArrayOf(0x01, 0x10, 0x00, 0x00, 0x00, 0x00, 0x02),
            ),
        )
    }

    @Test
    fun returnsNullForTruncatedCrankData() {
        assertNull(CadenceGattClient.parseCscCrank(byteArrayOf(0x02, 0x32, 0x00)))
    }

    @Test
    fun returnsNullForEmptyCscData() {
        assertNull(CadenceGattClient.parseCscCrank(byteArrayOf()))
    }

    @Test
    fun parsesRscInstantaneousCadence() {
        // Flags + instantaneous speed (uint16) + cadence (uint8) = 85 spm.
        assertEquals(
            85,
            CadenceGattClient.parseRscCadenceSpm(byteArrayOf(0x00, 0x00, 0x02, 0x55)),
        )
    }

    @Test
    fun returnsNullForTruncatedRscData() {
        assertNull(CadenceGattClient.parseRscCadenceSpm(byteArrayOf(0x00, 0x00, 0x02)))
    }
}
