package com.endurain.endurain.activity

import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCharacteristic
import android.content.Context
import java.util.UUID

/**
 * Minimal BLE client that connects to a cycling power meter and exposes the most
 * recent power in watts.
 *
 * Owned by [ActivityRecorderService] so the power connection has the same
 * lifetime as GPS collection (running inside the recording foreground service,
 * surviving app backgrounding). It reads the standard GATT Cycling Power Service
 * (`0x1818`) / Cycling Power Measurement characteristic (`0x2A63`) and uses
 * `autoConnect = true` so the OS restores the link if the meter briefly drops
 * out of range mid-activity.
 */
class CyclingPowerGattClient(context: Context) :
    BleNotifyClient(context, "CyclingPowerGatt") {
    private val reading = FreshReading()

    /**
     * The latest decoded instantaneous power in watts, or `null` when not connected or when none
     * arrived within [FreshReading.DEFAULT_MAX_AGE_MILLIS].
     */
    val latestWatts: Int?
        get() = reading.value

    override fun selectCharacteristic(gatt: BluetoothGatt): BluetoothGattCharacteristic? =
        gatt.getService(CYCLING_POWER_SERVICE)?.getCharacteristic(CYCLING_POWER_MEASUREMENT)

    override fun onValue(uuid: UUID, value: ByteArray) {
        if (uuid == CYCLING_POWER_MEASUREMENT) {
            parsePowerWatts(value)?.let { reading.update(it) }
        }
    }

    override fun onLinkLost() {
        reading.clear()
    }

    companion object {
        private val CYCLING_POWER_SERVICE =
            UUID.fromString("00001818-0000-1000-8000-00805f9b34fb")
        private val CYCLING_POWER_MEASUREMENT =
            UUID.fromString("00002a63-0000-1000-8000-00805f9b34fb")

        /**
         * Decodes the GATT Cycling Power Measurement value: a UINT16 flags field
         * then the instantaneous power as a SINT16 (little-endian) in watts.
         * Negative power (some trainers report it while coasting) is clamped to
         * zero. Returns `null` for malformed data.
         */
        fun parsePowerWatts(data: ByteArray): Int? {
            if (data.size < 4) {
                return null
            }
            val raw = (data[2].toInt() and 0xFF) or ((data[3].toInt() and 0xFF) shl 8)
            val signed = if (raw and 0x8000 != 0) raw - 0x10000 else raw
            return if (signed < 0) 0 else signed
        }
    }
}
