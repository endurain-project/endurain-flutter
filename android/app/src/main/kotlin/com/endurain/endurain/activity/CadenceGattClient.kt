package com.endurain.endurain.activity

import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCharacteristic
import android.content.Context
import android.os.SystemClock
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
class CadenceGattClient(context: Context) : BleNotifyClient(context, "CadenceGatt") {
    private val reading = FreshReading()

    /**
     * The latest decoded cadence in RPM (cycling) or SPM (running), or `null`
     * when none arrived within [FreshReading.DEFAULT_MAX_AGE_MILLIS].
     */
    val latestRpm: Int?
        get() = reading.value

    // Stateful CSC crank-revolution baseline for cadence derivation.
    private val crankCadence = CrankCadenceCalculator()

    // Prefer whichever supported cadence profile the device exposes.
    override fun selectCharacteristic(gatt: BluetoothGatt): BluetoothGattCharacteristic? =
        gatt.getService(CSC_SERVICE)?.getCharacteristic(CSC_MEASUREMENT)
            ?: gatt.getService(RSC_SERVICE)?.getCharacteristic(RSC_MEASUREMENT)

    override fun onValue(uuid: UUID, value: ByteArray) {
        when (uuid) {
            CSC_MEASUREMENT -> parseCscCadenceRpm(value)?.let { reading.update(it) }
            RSC_MEASUREMENT -> parseRscCadenceSpm(value)?.let { reading.update(it) }
        }
    }

    // Drop the stale reading and baseline so a new link starts a fresh derivation.
    override fun onLinkLost() {
        reading.clear()
        crankCadence.reset()
    }

    /**
     * Derives cycling cadence in RPM from a CSC Measurement, differencing the
     * crank counters against the previous sample (see [CrankCadenceCalculator]).
     * Returns `null` when there is no new cadence to report.
     */
    private fun parseCscCadenceRpm(data: ByteArray): Int? {
        val crank = parseCscCrank(data) ?: return null
        return crankCadence.onMeasurement(crank.first, crank.second, SystemClock.elapsedRealtime())
    }

    companion object {
        private val CSC_SERVICE =
            bluetoothUuid(0x1816)
        private val CSC_MEASUREMENT =
            bluetoothUuid(0x2a5b)
        private val RSC_SERVICE =
            bluetoothUuid(0x1814)
        private val RSC_MEASUREMENT =
            bluetoothUuid(0x2a53)

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
