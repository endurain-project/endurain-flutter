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

    @Test
    fun normalize_returnsNullForBlankInput() {
        assertNull(BluetoothAddressUtil.normalize(""))
        assertNull(BluetoothAddressUtil.normalize("  \n"))
    }

    @Test
    fun bluetoothUuid_expandsA16BitAssignedNumber() {
        assertEquals(
            "0000180d-0000-1000-8000-00805f9b34fb",
            bluetoothUuid(0x180d).toString(),
        )
    }
}
