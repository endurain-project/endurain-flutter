package com.endurain.endurain.activity

import android.content.Context

/**
 * The paired external sensors (heart rate, power, cadence) recorded in the
 * active session, so their latest readings can be stamped onto points inside
 * the same foreground service that owns GPS. Started and stopped from the
 * recorder thread; the readings themselves are `@Volatile` in the clients.
 */
internal class RecorderSensors(private val context: Context) {
    private var heartRateClient: HeartRateGattClient? = null
    private var powerClient: CyclingPowerGattClient? = null
    private var cadenceClient: CadenceGattClient? = null

    val heartRateBpm: Int?
        get() = heartRateClient?.latestBpm

    val powerWatts: Int?
        get() = powerClient?.latestWatts

    val cadenceRpm: Int?
        get() = cadenceClient?.latestRpm

    /** (Re)connects to the sensors bound in [session], if any. */
    fun start(session: ActiveActivitySessionData?) {
        stop()
        session?.heartRateDeviceId?.takeIf { it.isNotEmpty() }?.let { deviceId ->
            heartRateClient = HeartRateGattClient(context).also { it.start(deviceId) }
        }
        session?.powerDeviceId?.takeIf { it.isNotEmpty() }?.let { deviceId ->
            powerClient = CyclingPowerGattClient(context).also { it.start(deviceId) }
        }
        session?.cadenceDeviceId?.takeIf { it.isNotEmpty() }?.let { deviceId ->
            cadenceClient = CadenceGattClient(context).also { it.start(deviceId) }
        }
    }

    fun stop() {
        heartRateClient?.stop()
        heartRateClient = null
        powerClient?.stop()
        powerClient = null
        cadenceClient?.stop()
        cadenceClient = null
    }
}
