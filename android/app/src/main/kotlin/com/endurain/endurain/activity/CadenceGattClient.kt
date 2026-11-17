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
 * Minimal BLE client that connects to a cadence sensor and exposes the most
 * recent cadence in revolutions/steps per minute.
 *
 * Owned by [ActivityRecorderService] so the cadence connection has the same
 * lifetime as GPS collection. A cadence sensor advertises either the Cycling
 * Speed and Cadence service (CSC, `0x1816` / `0x2A5B`) or the Running Speed and
 * Cadence service (RSC, `0x1814` / `0x2A53`); this client discovers whichever
 * the device exposes and parses accordingly. Cycling cadence must be derived by
 * differencing the cumulative crank-revolution counter and last crank event time
 * between consecutive notifications, so that state is kept here; running cadence
 * is reported directly.
 */
class CadenceGattClient(private val context: Context) {
    /** The latest decoded cadence in RPM (cycling) or SPM (running), or `null`. */
    @Volatile
    var latestRpm: Int? = null
        private set

    private var gatt: BluetoothGatt? = null

    // Stateful CSC crank-revolution baseline for cadence derivation.
    private var previousCrankRevolutions: Int? = null
    private var previousCrankEventTime: Int? = null

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
                    // Drop the stale reading and baseline; autoConnect restores.
                    latestRpm = null
                    previousCrankRevolutions = null
                    previousCrankEventTime = null
                }
            }
        }

        @SuppressLint("MissingPermission")
        override fun onServicesDiscovered(discoveredGatt: BluetoothGatt, status: Int) {
            if (status != BluetoothGatt.GATT_SUCCESS) {
                return
            }
            // Prefer whichever supported cadence profile the device exposes.
            val characteristic =
                discoveredGatt.getService(CSC_SERVICE)?.getCharacteristic(CSC_MEASUREMENT)
                    ?: discoveredGatt.getService(RSC_SERVICE)?.getCharacteristic(RSC_MEASUREMENT)
                    ?: return
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
                // Notifications could not be enabled; no cadence will arrive.
            }
        }

        // Android 13+ delivers the value directly.
        override fun onCharacteristicChanged(
            changedGatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic,
            value: ByteArray,
        ) {
            handleValue(characteristic.uuid, value)
        }

        // Pre-Android 13 reads the value off the characteristic.
        @Deprecated("Deprecated in API 33")
        override fun onCharacteristicChanged(
            changedGatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic,
        ) {
            @Suppress("DEPRECATION")
            val value = characteristic.value ?: return
            handleValue(characteristic.uuid, value)
        }
    }

    private fun handleValue(uuid: UUID, value: ByteArray) {
        when (uuid) {
            CSC_MEASUREMENT -> parseCscCadenceRpm(value)?.let { latestRpm = it }
            RSC_MEASUREMENT -> parseRscCadenceSpm(value)?.let { latestRpm = it }
        }
    }

    /**
     * Derives cycling cadence in RPM from a CSC Measurement, differencing the
     * crank counters against the previous sample. Returns `null` on the first
     * (baseline) sample, when no crank data is present, or when no time has
     * elapsed (a duplicate notification, or the rider is coasting).
     */
    private fun parseCscCadenceRpm(data: ByteArray): Int? {
        val crank = parseCscCrank(data) ?: return null
        val previousRevolutions = previousCrankRevolutions
        val previousEventTime = previousCrankEventTime
        previousCrankRevolutions = crank.first
        previousCrankEventTime = crank.second
        if (previousRevolutions == null || previousEventTime == null) {
            return null
        }
        val deltaRevolutions = (crank.first - previousRevolutions) and 0xFFFF
        val deltaTime = (crank.second - previousEventTime) and 0xFFFF
        if (deltaTime == 0) {
            return null
        }
        // One crank event time tick is 1/1024 s; 60 s/min * 1024 ticks/s.
        return (deltaRevolutions * 60 * 1024) / deltaTime
    }

    /** Connects to [deviceId] (a BLE MAC address) and begins streaming cadence. */
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
            // degrade gracefully to recording without cadence.
            gatt = null
        }
    }

    /** Disconnects and releases the GATT connection. */
    @SuppressLint("MissingPermission")
    fun stop() {
        latestRpm = null
        previousCrankRevolutions = null
        previousCrankEventTime = null
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
        private val CSC_SERVICE =
            UUID.fromString("00001816-0000-1000-8000-00805f9b34fb")
        private val CSC_MEASUREMENT =
            UUID.fromString("00002a5b-0000-1000-8000-00805f9b34fb")
        private val RSC_SERVICE =
            UUID.fromString("00001814-0000-1000-8000-00805f9b34fb")
        private val RSC_MEASUREMENT =
            UUID.fromString("00002a53-0000-1000-8000-00805f9b34fb")
        private val CLIENT_CHARACTERISTIC_CONFIG =
            UUID.fromString("00002902-0000-1000-8000-00805f9b34fb")

        private const val FLAG_WHEEL_DATA_PRESENT = 0x01
        private const val FLAG_CRANK_DATA_PRESENT = 0x02

        /**
         * Extracts the cumulative crank revolutions (UINT16) and last crank
         * event time (UINT16, 1/1024 s) from a CSC Measurement, or `null` when
         * the payload is truncated or carries no crank data.
         */
        fun parseCscCrank(data: ByteArray): Pair<Int, Int>? {
            if (data.isEmpty()) {
                return null
            }
            val flags = data[0].toInt() and 0xFF
            if (flags and FLAG_CRANK_DATA_PRESENT == 0) {
                return null
            }
            var offset = 1
            if (flags and FLAG_WHEEL_DATA_PRESENT != 0) {
                // UINT32 cumulative wheel revolutions + UINT16 last wheel event time.
                offset += 6
            }
            if (data.size < offset + 4) {
                return null
            }
            val crankRevolutions =
                (data[offset].toInt() and 0xFF) or ((data[offset + 1].toInt() and 0xFF) shl 8)
            val crankEventTime =
                (data[offset + 2].toInt() and 0xFF) or ((data[offset + 3].toInt() and 0xFF) shl 8)
            return Pair(crankRevolutions, crankEventTime)
        }

        /**
         * Decodes the instantaneous cadence (UINT8, steps per minute) from an
         * RSC Measurement, or `null` when the payload is truncated.
         */
        fun parseRscCadenceSpm(data: ByteArray): Int? {
            if (data.size < 4) {
                return null
            }
            return data[3].toInt() and 0xFF
        }
    }
}
