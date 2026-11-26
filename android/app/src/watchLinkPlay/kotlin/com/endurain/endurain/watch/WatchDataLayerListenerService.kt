package com.endurain.endurain.watch

import android.util.Log
import com.endurain.endurain.watchlink.WatchProtocol
import com.google.android.gms.wearable.DataEvent
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.Wearable
import com.google.android.gms.wearable.WearableListenerService

/**
 * Receives sessions from the Wear OS app, even when Endurain is not running.
 *
 * Each published session is downloaded into the durable inbox right away;
 * Dart drains the inbox whenever it runs. When the watch deletes a session
 * (after the phone's acknowledgement), the acknowledgement item is dropped.
 */
class WatchDataLayerListenerService : WearableListenerService() {
    override fun onDataChanged(dataEvents: DataEventBuffer) {
        val inbox = WatchInbox.create(applicationContext)
        var received = false
        for (event in dataEvents) {
            val path = event.dataItem.uri.path
            val sessionId = WatchProtocol.sessionIdFromPath(path, WatchProtocol.HANDOFF_PATH_PREFIX) ?: continue
            when (event.type) {
                DataEvent.TYPE_CHANGED ->
                    if (DataLayerWatchLink.storeHandoff(applicationContext, event.dataItem, inbox)) {
                        received = true
                    }
                DataEvent.TYPE_DELETED -> deleteAcknowledgement(sessionId)
            }
        }
        if (received) {
            WatchHandoffEvents.notifyHandoffReceived()
        }
    }

    private fun deleteAcknowledgement(sessionId: String) {
        val uri = WatchProtocol.dataLayerUri(WatchProtocol.ackPath(sessionId))
        Wearable.getDataClient(applicationContext).deleteDataItems(uri).addOnFailureListener { error ->
            Log.w("EndurainWatch", "Could not drop a watch acknowledgement", error)
        }
    }
}
