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
import android.bluetooth.BluetoothStatusCodes
import android.content.Context
import android.util.Log
import java.util.UUID

/**
 * Shared BLE client for sensors that stream a single notifying GATT
 * characteristic (heart rate, cycling power, cadence).
 *
 * It owns the connection life cycle: connect with `autoConnect = true` (so the
 * OS restores a link that merely drifts out of range), discover services,
 * enable notifications through the CCCD and hand every notification value to
 * [onValue]. Subclasses only choose the characteristic and decode the bytes.
 *
 * A link that fails outright (a non-success GATT status, failed discovery or a
 * rejected descriptor write) leaves the [BluetoothGatt] unusable, so it is
 * closed and rebuilt after a bounded backoff, see [GattReconnectController].
 */
abstract class BleNotifyClient internal constructor(
    private val context: Context,
    private val logTag: String,
    scheduler: ReconnectScheduler,
) {
    constructor(context: Context, logTag: String) :
        this(context, logTag, MainLooperReconnectScheduler())

    @Volatile
    private var gatt: BluetoothGatt? = null

    @Volatile
    private var deviceId: String? = null

    private val reconnect = GattReconnectController(scheduler, ::reconnectNow)

    /** Picks the characteristic to subscribe to, or `null` if the sensor lacks it. */
    protected abstract fun selectCharacteristic(gatt: BluetoothGatt): BluetoothGattCharacteristic?

    /** Decodes one notification [value] of the characteristic [uuid]. */
    protected abstract fun onValue(uuid: UUID, value: ByteArray)

    /** Drops cached readings and parser state; the link is gone or restarting. */
    protected abstract fun onLinkLost()

    private val callback = object : BluetoothGattCallback() {
        @SuppressLint("MissingPermission")
        override fun onConnectionStateChange(
            connectedGatt: BluetoothGatt,
            status: Int,
            newState: Int,
        ) {
            if (connectedGatt !== gatt) {
                return
            }
            if (status != BluetoothGatt.GATT_SUCCESS) {
                // e.g. status 133: the stack gave up and this object is dead.
                fail(connectedGatt, "connection state $newState failed with status $status")
                return
            }
            when (newState) {
                BluetoothProfile.STATE_CONNECTED -> {
                    try {
                        connectedGatt.discoverServices()
                    } catch (error: Exception) {
                        fail(connectedGatt, "discoverServices threw", error)
                    }
                }
                BluetoothProfile.STATE_DISCONNECTED -> {
                    // Drop the stale reading; autoConnect will restore the link.
                    onLinkLost()
                }
            }
        }

        @SuppressLint("MissingPermission")
        override fun onServicesDiscovered(discoveredGatt: BluetoothGatt, status: Int) {
            if (discoveredGatt !== gatt) {
                return
            }
            if (status != BluetoothGatt.GATT_SUCCESS) {
                fail(discoveredGatt, "service discovery failed with status $status")
                return
            }
            // A sensor without the profile will not grow it by reconnecting.
            val characteristic = selectCharacteristic(discoveredGatt) ?: return
            discoveredGatt.setCharacteristicNotification(characteristic, true)
            val cccd = characteristic.getDescriptor(CLIENT_CHARACTERISTIC_CONFIG) ?: return
            try {
                val started = if (android.os.Build.VERSION.SDK_INT >=
                    android.os.Build.VERSION_CODES.TIRAMISU
                ) {
                    discoveredGatt.writeDescriptor(
                        cccd,
                        BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE,
                    ) == BluetoothStatusCodes.SUCCESS
                } else {
                    @Suppress("DEPRECATION")
                    cccd.value = BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE
                    @Suppress("DEPRECATION")
                    discoveredGatt.writeDescriptor(cccd)
                }
                if (!started) {
                    fail(discoveredGatt, "could not start the notification descriptor write")
                }
            } catch (error: Exception) {
                fail(discoveredGatt, "enabling notifications threw", error)
            }
        }

        override fun onDescriptorWrite(
            writtenGatt: BluetoothGatt,
            descriptor: BluetoothGattDescriptor,
            status: Int,
        ) {
            if (writtenGatt !== gatt || descriptor.uuid != CLIENT_CHARACTERISTIC_CONFIG) {
                return
            }
            if (status == BluetoothGatt.GATT_SUCCESS) {
                reconnect.reset()
            } else {
                fail(writtenGatt, "notification descriptor write failed with status $status")
            }
        }

        // Android 13+ delivers the value directly.
        override fun onCharacteristicChanged(
            changedGatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic,
            value: ByteArray,
        ) {
            onValue(characteristic.uuid, value)
        }

        // Pre-Android 13 reads the value off the characteristic.
        @Deprecated("Deprecated in API 33")
        override fun onCharacteristicChanged(
            changedGatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic,
        ) {
            @Suppress("DEPRECATION")
            val value = characteristic.value ?: return
            onValue(characteristic.uuid, value)
        }
    }

    /** Connects to [deviceId] (a BLE MAC address) and begins streaming. */
    fun start(deviceId: String) {
        stop()
        this.deviceId = deviceId
        connect(deviceId)
    }

    /** Disconnects and releases the GATT connection. */
    fun stop() {
        reconnect.cancel()
        deviceId = null
        release()
        onLinkLost()
    }

    @SuppressLint("MissingPermission")
    private fun connect(deviceId: String) {
        try {
            val manager =
                context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
                    ?: return
            val adapter: BluetoothAdapter = manager.adapter ?: return
            if (!adapter.isEnabled) {
                return
            }
            gatt = adapter.getRemoteDevice(deviceId)
                .connectGatt(context, true, callback, BluetoothDevice.TRANSPORT_LE)
        } catch (error: Exception) {
            // Bluetooth unavailable, permission missing, or malformed address:
            // degrade gracefully to recording without this sensor.
            Log.w(logTag, "Could not connect to the sensor", error)
            gatt = null
        }
    }

    private fun reconnectNow() {
        val id = deviceId ?: return
        release()
        connect(id)
    }

    private fun fail(failedGatt: BluetoothGatt, reason: String, error: Exception? = null) {
        Log.w(logTag, reason, error)
        if (failedGatt === gatt) {
            release()
        }
        onLinkLost()
        if (deviceId != null && !reconnect.onFailure()) {
            Log.w(logTag, "Giving up on the sensor after repeated failures")
        }
    }

    @SuppressLint("MissingPermission")
    private fun release() {
        val active = gatt ?: return
        gatt = null
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

    private companion object {
        val CLIENT_CHARACTERISTIC_CONFIG: UUID =
            UUID.fromString("00002902-0000-1000-8000-00805f9b34fb")
    }
}
