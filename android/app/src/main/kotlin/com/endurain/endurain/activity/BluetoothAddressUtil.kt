package com.endurain.endurain.activity

import java.util.Locale

internal object BluetoothAddressUtil {
    /**
     * Canonicalizes a BLE MAC address for Android Bluetooth validation.
     *
     * Android requires uppercase hex digits in direct Bluetooth addresses, so the
     * address is trimmed and uppercased before being handed to
     * BluetoothAdapter.getRemoteDevice(). We intentionally do not strip invalid
     * characters here: malformed addresses should fail early. Null or blank input yields null so
     * the caller can treat the sensor as absent.
     */
    fun normalize(raw: String?): String? {
        val trimmed = raw?.trim()
        if (trimmed.isNullOrEmpty()) {
            return null
        }
        return trimmed.uppercase(Locale.US)
    }
}
