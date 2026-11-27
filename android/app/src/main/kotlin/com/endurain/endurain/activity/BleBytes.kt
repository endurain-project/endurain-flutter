package com.endurain.endurain.activity

/** Byte decoding shared by the GATT measurement parsers. */
internal object BleBytes {
    /** The unsigned byte at [index] as an `Int` (0..255). */
    fun u8(data: ByteArray, index: Int): Int = data[index].toInt() and 0xFF

    /**
     * The little-endian UINT16 at [offset] as an `Int` (0..65535), the byte
     * order every Bluetooth GATT characteristic uses. The caller checks that
     * both bytes exist.
     */
    fun u16Le(data: ByteArray, offset: Int): Int =
        u8(data, offset) or (u8(data, offset + 1) shl 8)
}
