package com.endurain.endurain.watch

import android.content.Context

/** Build with the Wearable Data Layer (the default). */
object WatchLinkFactory {
    fun create(context: Context): WatchLink = DataLayerWatchLink(context.applicationContext)
}
