package com.endurain.endurain.activity

import java.util.Locale

internal object BluetoothAddressUtil {
    /**
     * Canonicalizes a BLE MAC address for Android Bluetooth validation.
     *
     * Android requires uppercase hex digits in direct Bluetooth addresses, so the
     * address is trimmed and uppercased before being handed to
     * BluetoothAdapter.getRemoteDevice(). We intentionally do not strip invalid
     * characters here: malformed addresses should fail early so the native
     * recorder can avoid connecting with an unusable value.
     */
    fun normalize(raw: String?): String? {
        if (raw == null) {
            return null
        }
        return raw.trim().uppercase(Locale.US)
    }
}
