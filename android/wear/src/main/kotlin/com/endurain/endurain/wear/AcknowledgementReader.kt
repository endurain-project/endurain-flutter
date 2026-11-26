package com.endurain.endurain.wear

import com.endurain.endurain.watchlink.WatchProtocol

/** Turns acknowledgement items into the sessions they confirm. */
object AcknowledgementReader {
    /**
     * The session ids of the `(path, version)` pairs that are acknowledgements.
     *
     * Any version is accepted: an acknowledgement only names a session the
     * phone has stored, so rejecting a newer one would leave workouts stuck in
     * the outbox whenever the phone app updates before the watch app.
     */
    fun sessionIds(items: List<Pair<String?, Int>>): List<String> =
        items.mapNotNull { (path, _) ->
            WatchProtocol.sessionIdFromPath(path, WatchProtocol.ACK_PATH_PREFIX)
        }
}
