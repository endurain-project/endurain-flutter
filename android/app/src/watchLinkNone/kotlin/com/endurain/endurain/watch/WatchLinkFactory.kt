package com.endurain.endurain.watch

import android.content.Context
import com.endurain.endurain.watchlink.HandoffFileStore

/**
 * Build without the Wear OS link (`-Pendurain.wearable=false`, which leaves
 * out play-services-wearable): the Dart side sees "unsupported" and stays
 * inert.
 */
object WatchLinkFactory {
    // `context` is unused here but the signature must match the
    // watchLinkPlay flavor, which MainActivity calls identically.
    @Suppress("UNUSED_PARAMETER")
    fun create(context: Context): WatchLink = UnsupportedWatchLink
}

private object UnsupportedWatchLink : WatchLink {
    override fun linkStatus(): String = "unsupported"

    override fun pullPendingHandoffs(inbox: HandoffFileStore) {}

    override fun acknowledge(sessionId: String) {}

    override fun startObserving(onLinkStatusChanged: (String) -> Unit) {}

    override fun stopObserving() {}
}
