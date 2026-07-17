package com.endurain.endurain.activity

import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattDescriptor
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.content.Context
import android.os.Build
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
class HeartRateGattClient(private val context: Context) {
    /** The latest decoded heart rate in BPM, or `null` when not connected. */
    @Volatile
    var latestBpm: Int? = null
        private set

    private var gatt: BluetoothGatt? = null

    private val callback = object : BluetoothGattCallback() {
        @SuppressLint("MissingPermission")
        override fun onConnectionStateChange(
            connectedGatt: BluetoothGatt,
            status: Int,
            newState: Int,
        ) {
            when (newState) {
                BluetoothProfile.STATE_CONNECTED -> {
                    try {
                        connectedGatt.discoverServices()
                    } catch (_: Exception) {
                        // Ignore: a later reconnect will retry discovery.
                    }
                }
                BluetoothProfile.STATE_DISCONNECTED -> {
                    // Drop the stale reading; autoConnect will restore the link.
                    latestBpm = null
                }
            }
        }

        @SuppressLint("MissingPermission")
        override fun onServicesDiscovered(discoveredGatt: BluetoothGatt, status: Int) {
            if (status != BluetoothGatt.GATT_SUCCESS) {
                return
            }
            val service = discoveredGatt.getService(HEART_RATE_SERVICE) ?: return
            val characteristic =
                service.getCharacteristic(HEART_RATE_MEASUREMENT) ?: return
            discoveredGatt.setCharacteristicNotification(characteristic, true)
            val cccd = characteristic.getDescriptor(CLIENT_CHARACTERISTIC_CONFIG) ?: return
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    discoveredGatt.writeDescriptor(
                        cccd,
                        BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE,
                    )
                } else {
                    @Suppress("DEPRECATION")
                    cccd.value = BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE
                    @Suppress("DEPRECATION")
                    discoveredGatt.writeDescriptor(cccd)
                }
            } catch (_: Exception) {
                // Notifications could not be enabled; no heart rate will arrive.
            }
        }

        // Android 13+ delivers the value directly.
        override fun onCharacteristicChanged(
            changedGatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic,
            value: ByteArray,
        ) {
            if (characteristic.uuid == HEART_RATE_MEASUREMENT) {
                parseHeartRate(value)?.let { latestBpm = it }
            }
        }

        // Pre-Android 13 reads the value off the characteristic.
        @Deprecated("Deprecated in API 33")
        override fun onCharacteristicChanged(
            changedGatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic,
        ) {
            if (characteristic.uuid == HEART_RATE_MEASUREMENT) {
                @Suppress("DEPRECATION")
                val value = characteristic.value ?: return
                parseHeartRate(value)?.let { latestBpm = it }
            }
        }
    }

    /** Connects to [deviceId] (a BLE MAC address) and begins streaming HR. */
    @SuppressLint("MissingPermission")
    fun start(deviceId: String) {
        stop()
        try {
            val manager =
                context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
                    ?: return
            val adapter: BluetoothAdapter = manager.adapter ?: return
            if (!adapter.isEnabled) {
                return
            }
            val device = adapter.getRemoteDevice(deviceId)
            gatt = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                device.connectGatt(context, true, callback, BluetoothDevice.TRANSPORT_LE)
            } else {
                device.connectGatt(context, true, callback)
            }
        } catch (_: Exception) {
            // Bluetooth unavailable, permission missing, or malformed address:
            // degrade gracefully to recording without heart rate.
            gatt = null
        }
    }

    /** Disconnects and releases the GATT connection. */
    @SuppressLint("MissingPermission")
    fun stop() {
        latestBpm = null
        gatt?.let { active ->
            try {
                active.disconnect()
            } catch (_: Exception) {
                // Best effort.
            }
            try {
                active.close()
            } catch (_: Exception) {
                // Best effort.
            }
        }
        gatt = null
    }

    companion object {
        private val HEART_RATE_SERVICE =
            UUID.fromString("0000180d-0000-1000-8000-00805f9b34fb")
        private val HEART_RATE_MEASUREMENT =
            UUID.fromString("00002a37-0000-1000-8000-00805f9b34fb")
        private val CLIENT_CHARACTERISTIC_CONFIG =
            UUID.fromString("00002902-0000-1000-8000-00805f9b34fb")

        /**
         * Decodes the GATT Heart Rate Measurement value: flags byte then an
         * 8- or 16-bit little-endian BPM. Returns `null` for malformed data.
         */
        fun parseHeartRate(data: ByteArray): Int? {
            if (data.isEmpty()) {
                return null
            }
            val flags = data[0].toInt() and 0xFF
            val is16Bit = (flags and 0x01) != 0
            return if (is16Bit) {
                if (data.size < 3) {
                    return null
                }
                (data[1].toInt() and 0xFF) or ((data[2].toInt() and 0xFF) shl 8)
            } else {
                if (data.size < 2) {
                    return null
                }
                data[1].toInt() and 0xFF
            }
        }
    }
}
