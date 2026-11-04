package com.endurain.endurain.activity

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class BluetoothAddressUtilTest {
    @Test
    fun normalize_uppercasesTheAddress() {
        val normalized = BluetoothAddressUtil.normalize("aa:bb:cc:dd:ee:ff")

        assertEquals("AA:BB:CC:DD:EE:FF", normalized)
    }

    @Test
    fun normalize_trimsWhitespace() {
        val normalized = BluetoothAddressUtil.normalize(" AA:BB:CC:DD:EE:FF\n")

        assertEquals("AA:BB:CC:DD:EE:FF", normalized)
    }

    @Test
    fun normalize_returnsNullForNullInput() {
        assertNull(BluetoothAddressUtil.normalize(null))
    }
}
