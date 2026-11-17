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
class CyclingPowerGattClient(private val context: Context) {
    /** The latest decoded instantaneous power in watts, or `null` when not connected. */
    @Volatile
    var latestWatts: Int? = null
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
                    latestWatts = null
                }
            }
        }

        @SuppressLint("MissingPermission")
        override fun onServicesDiscovered(discoveredGatt: BluetoothGatt, status: Int) {
            if (status != BluetoothGatt.GATT_SUCCESS) {
                return
            }
            val service = discoveredGatt.getService(CYCLING_POWER_SERVICE) ?: return
            val characteristic =
                service.getCharacteristic(CYCLING_POWER_MEASUREMENT) ?: return
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
                // Notifications could not be enabled; no power will arrive.
            }
        }

        // Android 13+ delivers the value directly.
        override fun onCharacteristicChanged(
            changedGatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic,
            value: ByteArray,
        ) {
            if (characteristic.uuid == CYCLING_POWER_MEASUREMENT) {
                parsePowerWatts(value)?.let { latestWatts = it }
            }
        }

        // Pre-Android 13 reads the value off the characteristic.
        @Deprecated("Deprecated in API 33")
        override fun onCharacteristicChanged(
            changedGatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic,
        ) {
            if (characteristic.uuid == CYCLING_POWER_MEASUREMENT) {
                @Suppress("DEPRECATION")
                val value = characteristic.value ?: return
                parsePowerWatts(value)?.let { latestWatts = it }
            }
        }
    }

    /** Connects to [deviceId] (a BLE MAC address) and begins streaming power. */
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
            // degrade gracefully to recording without power.
            gatt = null
        }
    }

    /** Disconnects and releases the GATT connection. */
    @SuppressLint("MissingPermission")
    fun stop() {
        latestWatts = null
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
        private val CYCLING_POWER_SERVICE =
            UUID.fromString("00001818-0000-1000-8000-00805f9b34fb")
        private val CYCLING_POWER_MEASUREMENT =
            UUID.fromString("00002a63-0000-1000-8000-00805f9b34fb")
        private val CLIENT_CHARACTERISTIC_CONFIG =
            UUID.fromString("00002902-0000-1000-8000-00805f9b34fb")

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
