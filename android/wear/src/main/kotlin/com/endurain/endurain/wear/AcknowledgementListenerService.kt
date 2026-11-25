package com.endurain.endurain.wear

import com.endurain.endurain.watchlink.WatchProtocol
import com.google.android.gms.wearable.DataEvent
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.WearableListenerService

/** Receives the phone's confirmation that Endurain stored a workout. */
class AcknowledgementListenerService : WearableListenerService() {
    override fun onDataChanged(dataEvents: DataEventBuffer) {
        val phoneLink = (application as EndurainWearApplication).phoneLink
        for (event in dataEvents) {
            if (event.type != DataEvent.TYPE_CHANGED) continue
            val sessionId =
                WatchProtocol.sessionIdFromPath(event.dataItem.uri.path, WatchProtocol.ACK_PATH_PREFIX)
                    ?: continue
            phoneLink.acknowledged(sessionId)
        }
    }
}
