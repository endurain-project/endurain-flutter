package com.endurain.endurain.activity

import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCharacteristic
import android.content.Context
import java.util.UUID

/**
 * Minimal BLE client that connects to a heart-rate strap and exposes the most
 * recent BPM.
 *
 * It is owned by [ActivityRecorderService] so the heart-rate connection has the
 * same lifetime as GPS collection (running inside the recording foreground
 * service, surviving app backgrounding). It reads the standard GATT Heart Rate
 * Service (`0x180D`) / Heart Rate Measurement characteristic (`0x2A37`) and
 * uses `autoConnect = true` so the OS restores the link if the strap briefly
 * drops out of range mid-activity.
 */
class HeartRateGattClient(context: Context) : BleNotifyClient(context, "HeartRateGatt") {
    private val reading = FreshReading()

    /**
     * The latest decoded heart rate in BPM, or `null` when not connected or when none
     * arrived within [FreshReading.DEFAULT_MAX_AGE_MILLIS].
     */
    val latestBpm: Int?
        get() = reading.value

    override fun selectCharacteristic(gatt: BluetoothGatt): BluetoothGattCharacteristic? =
        gatt.getService(HEART_RATE_SERVICE)?.getCharacteristic(HEART_RATE_MEASUREMENT)

    override fun onValue(uuid: UUID, value: ByteArray) {
        if (uuid == HEART_RATE_MEASUREMENT) {
            parseHeartRate(value)?.let { reading.update(it) }
        }
    }

    override fun onLinkLost() {
        reading.clear()
    }

    companion object {
        private val HEART_RATE_SERVICE =
            bluetoothUuid(0x180d)
        private val HEART_RATE_MEASUREMENT =
            bluetoothUuid(0x2a37)

        private const val FLAG_VALUE_IS_16_BIT = 0x01
        private const val FLAG_ENERGY_PRESENT = 0x08

        /**
         * Decodes the GATT Heart Rate Measurement value: flags byte then an
         * 8- or 16-bit little-endian BPM. Returns `null` for malformed data,
         * including a payload whose flags promise an energy-expended field that
         * is cut short (the Dart parser rejects it too, so both layers agree).
         */
        fun parseHeartRate(data: ByteArray): Int? {
            if (data.isEmpty()) {
                return null
            }
            val flags = data[0].toInt() and 0xFF
            val is16Bit = (flags and FLAG_VALUE_IS_16_BIT) != 0
            val valueSize = if (is16Bit) 2 else 1
            val energySize = if ((flags and FLAG_ENERGY_PRESENT) != 0) 2 else 0
            if (data.size < 1 + valueSize + energySize) {
                return null
            }
            return if (is16Bit) {
                (data[1].toInt() and 0xFF) or ((data[2].toInt() and 0xFF) shl 8)
            } else {
                data[1].toInt() and 0xFF
            }
        }
    }
}
