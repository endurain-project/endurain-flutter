package com.endurain.endurain.activity

import org.junit.Assert.assertEquals
import org.junit.Test

class BleBytesTest {
    @Test
    fun decodesLittleEndianUint16() {
        assertEquals(0x0201, BleBytes.u16Le(byteArrayOf(0x01, 0x02), 0))
        assertEquals(0x1234, BleBytes.u16Le(byteArrayOf(0x00, 0x34, 0x12), 1))
    }

    @Test
    fun treatsBytesAsUnsigned() {
        assertEquals(0xFFFF, BleBytes.u16Le(byteArrayOf(-1, -1), 0))
        assertEquals(0x8000, BleBytes.u16Le(byteArrayOf(0x00, -128), 0))
        assertEquals(0xFF, BleBytes.u8(byteArrayOf(-1), 0))
    }
}
