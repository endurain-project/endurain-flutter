package com.endurain.endurain.watch

import android.content.Context
import com.endurain.endurain.watchlink.HandoffFileStore

/**
 * Build without Google Play Services (`-Pendurain.wearable=false`): there is
 * no Wear OS link, so the Dart side sees "unsupported" and stays inert.
 */
object WatchLinkFactory {
    fun create(context: Context): WatchLink = UnsupportedWatchLink
}

private object UnsupportedWatchLink : WatchLink {
    override fun linkStatus(): String = "unsupported"

    override fun pullPendingHandoffs(inbox: HandoffFileStore) {}

    override fun acknowledge(sessionId: String) {}

    override fun startObserving(onLinkStatusChanged: (String) -> Unit) {}

    override fun stopObserving() {}
}
