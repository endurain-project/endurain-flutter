package com.endurain.endurain.wear

import android.content.Context
import android.util.Log
import com.endurain.endurain.watchlink.HandoffFileStore
import com.endurain.endurain.watchlink.WatchProtocol
import com.google.android.gms.wearable.Asset
import com.google.android.gms.wearable.PutDataMapRequest
import com.google.android.gms.wearable.DataClient
import com.google.android.gms.wearable.DataMapItem
import com.google.android.gms.wearable.Wearable
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await
import java.io.File
import java.io.IOException
import java.util.concurrent.TimeUnit

/**
 * Watch end of the link to the Endurain phone app.
 *
 * Every finished workout is kept in a durable outbox and published as a
 * Wearable Data Layer item. Google Play Services stores the item and syncs
 * it whenever the phone connects, so a workout finished out of range still
 * arrives. The outbox copy and the item stay until the phone confirms that
 * Endurain stored the workout, so a session the phone cannot store yet (for
 * example one without a GPS route) is never lost on the watch. Workouts the
 * phone never confirms are dropped after [RETENTION_MILLIS]; by then the
 * phone has long had its own copy.
 */
class PhoneLink(context: Context) : HandoffSink {
    private val appContext = context.applicationContext
    private val dataClient by lazy { Wearable.getDataClient(appContext) }
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    /** `noBackupFilesDir` keeps workout routes out of device backups. */
    val outbox = HandoffFileStore(File(appContext.noBackupFilesDir, "watch_outbox"))

    private val waiting = MutableStateFlow(0)

    /** Workouts not yet confirmed by the phone. */
    val waitingCount: StateFlow<Int> = waiting.asStateFlow()

    @Throws(IOException::class)
    override fun enqueue(data: ByteArray, sessionId: String) {
        outbox.save(data, sessionId)
        refreshWaitingCount()
        scope.launch { publish(sessionId, data) }
    }

    /**
     * Reconciles with the phone at launch: drops what the phone already
     * acknowledged (an ack event missed while the app was not running would
     * otherwise keep the workout in the outbox for [RETENTION_MILLIS]), then
     * publishes every remaining outbox entry again. Publishing an unchanged
     * item is a no-op for the Data Layer, so that only matters for an item
     * that was lost (for example after Play Services data was cleared).
     */
    fun republishPending() {
        scope.launch {
            readAcknowledgedSessions().forEach { acknowledged(it) }
            val cutoff = System.currentTimeMillis() - RETENTION_MILLIS
            outbox.pruneSavedBefore(cutoff).forEach { deleteHandoffItem(it) }
            for (entry in outbox.entries()) {
                val data =
                    try {
                        entry.file.readBytes()
                    } catch (_: IOException) {
                        continue
                    }
                publish(entry.sessionId, data)
            }
            refreshWaitingCount()
        }
    }

    /** The phone stored [sessionId]: drop the watch's copy. */
    fun acknowledged(sessionId: String) {
        outbox.remove(sessionId)
        refreshWaitingCount()
        scope.launch { deleteHandoffItem(sessionId) }
    }

    private suspend fun publish(sessionId: String, data: ByteArray) {
        val request =
            PutDataMapRequest.create(WatchProtocol.handoffPath(sessionId)).apply {
                dataMap.putString(WatchProtocol.KEY_SESSION_ID, sessionId)
                dataMap.putInt(WatchProtocol.KEY_VERSION, WatchProtocol.PAYLOAD_VERSION)
                dataMap.putAsset(WatchProtocol.KEY_PAYLOAD, Asset.createFromBytes(data))
            }
        try {
            dataClient.putDataItem(request.asPutDataRequest().setUrgent()).await()
        } catch (error: Exception) {
            // Retried by republishPending() at the next launch.
            Log.w(TAG, "Could not publish a workout to the phone", error)
        }
    }

    /** Session ids of the acknowledgement items the phone left in the Data Layer. */
    private suspend fun readAcknowledgedSessions(): List<String> {
        val uri = WatchProtocol.dataLayerUri(WatchProtocol.ACK_PATH_PREFIX)
        return try {
            val buffer = dataClient.getDataItems(uri, DataClient.FILTER_PREFIX).await()
            try {
                AcknowledgementReader.sessionIds(
                    buffer.map { it.uri.path to DataMapItem.fromDataItem(it).dataMap.getInt(WatchProtocol.KEY_VERSION) },
                )
            } finally {
                buffer.release()
            }
        } catch (error: Exception) {
            Log.w(TAG, "Could not read the phone's acknowledgements", error)
            emptyList()
        }
    }

    private suspend fun deleteHandoffItem(sessionId: String) {
        val uri = WatchProtocol.dataLayerUri(WatchProtocol.handoffPath(sessionId))
        try {
            dataClient.deleteDataItems(uri).await()
        } catch (error: Exception) {
            Log.w(TAG, "Could not delete a delivered workout item", error)
        }
    }

    private fun refreshWaitingCount() {
        waiting.value = outbox.entries().size
    }

    companion object {
        private const val TAG = "EndurainWear"
        val RETENTION_MILLIS = TimeUnit.DAYS.toMillis(90)
    }
}
