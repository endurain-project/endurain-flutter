package com.endurain.endurain.wear

import android.util.Log
import com.google.android.gms.wearable.DataEvent
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.WearableListenerService

/** Receives the phone's confirmation that Endurain stored a workout. */
class AcknowledgementListenerService : WearableListenerService() {
    override fun onDataChanged(dataEvents: DataEventBuffer) {
        val phoneLink = (application as EndurainWearApplication).phoneLink
        for (event in dataEvents) {
            if (event.type != DataEvent.TYPE_CHANGED) continue
            try {
                val sessionId = AcknowledgementReader.sessionIds(listOf(event.dataItem.uri.path)).firstOrNull()
                    ?: continue
                phoneLink.acknowledged(sessionId)
            } catch (error: Exception) {
                // One malformed item must not stop the others from clearing the outbox.
                Log.w(TAG, "Could not read an acknowledgement", error)
            }
        }
    }
}
