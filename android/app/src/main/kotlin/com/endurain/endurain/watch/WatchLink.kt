package com.endurain.endurain.watch

import android.content.Context
import com.endurain.endurain.watchlink.HandoffFileStore
import java.io.File

/**
 * Phone end of the link to the Endurain Wear OS app.
 *
 * Two implementations exist, picked at build time by the `endurain.wearable`
 * Gradle property (see `android/app/build.gradle.kts`): the Wearable Data
 * Layer one (`src/watchLinkPlay`, play-services-wearable) and an inert one
 * (`src/watchLinkNone`) for builds published without the Wear OS link.
 *
 * Every method may block; call them off the main thread.
 */
interface WatchLink {
    /** A Dart `WatchLinkStatus` name. */
    fun linkStatus(): String

    /**
     * Copies every session the watch published, and the phone has not
     * acknowledged yet, into [inbox]. Covers sessions whose delivery the
     * phone missed (for example while the app was being updated).
     */
    fun pullPendingHandoffs(inbox: HandoffFileStore)

    /** Tells the watch it may delete its copy of [sessionId]. */
    fun acknowledge(sessionId: String)

    /** Starts reporting link changes to [onLinkStatusChanged]. */
    fun startObserving(onLinkStatusChanged: (String) -> Unit)

    fun stopObserving()
}

/** Maps the link state to a Dart `WatchLinkStatus` name. */
object WatchLinkState {
    fun status(
        isAvailable: Boolean,
        appNodesKnown: Boolean,
        appNodeReachable: Boolean,
        anyNodeConnected: Boolean,
    ): String =
        when {
            !isAvailable -> "unavailable"
            appNodeReachable -> "connected"
            appNodesKnown -> "disconnected"
            anyNodeConnected -> "appNotInstalled"
            else -> "unpaired"
        }
}

/**
 * Process-wide signal that a session landed in the inbox. The Data Layer
 * listener service may run without any Flutter engine; when one is attached
 * the channel registers here to forward the event to Dart.
 */
object WatchHandoffEvents {
    @Volatile
    var listener: (() -> Unit)? = null

    fun notifyHandoffReceived() {
        listener?.invoke()
    }

    /** Clears [expected] if it is still the registered listener (another engine's stays). */
    fun clearListener(expected: () -> Unit) {
        if (listener === expected) {
            listener = null
        }
    }
}

object WatchInbox {
    /** `noBackupFilesDir` keeps workout routes out of device backups. */
    fun create(context: Context): HandoffFileStore =
        HandoffFileStore(File(context.noBackupFilesDir, "watch_inbox"))
}
