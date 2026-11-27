package com.endurain.endurain.activity

import android.os.Build

/** Asks the user for the notification permission and reports the answer. */
fun interface NotificationPermissionRequester {
    /** Calls [onResult] on the main thread with whether the permission is granted. */
    fun request(onResult: (Boolean) -> Unit)
}

/**
 * Decides whether and when to show the Android 13+ (API 33)
 * `POST_NOTIFICATIONS` prompt, and fans the single system answer out to every
 * caller waiting for it.
 *
 * It is the contextual replacement for asking on app start: the recorder's
 * foreground notification (and with it the user's visible sign that a
 * recording is running) needs the permission, so Dart asks right before a
 * recording or its start countdown begins. The prompt is skipped below API 33
 * (nothing to ask) and when already granted. After a permanent denial the
 * system answers "denied" without showing a dialog, so no extra bookkeeping is
 * needed (a dismissed dialog must not be mistaken for one). Recording never
 * depends on the answer. Main-thread only.
 *
 * [launch] shows the system dialog; its outcome must be fed to [onResult].
 */
internal class NotificationPermissionGate(
    private val sdkInt: Int = Build.VERSION.SDK_INT,
    private val isGranted: () -> Boolean,
    private val launch: () -> Unit,
) : NotificationPermissionRequester {
    private val waiting = mutableListOf<(Boolean) -> Unit>()

    override fun request(onResult: (Boolean) -> Unit) {
        if (sdkInt < Build.VERSION_CODES.TIRAMISU) {
            onResult(true)
            return
        }
        if (isGranted()) {
            onResult(true)
            return
        }
        val alreadyAsking = waiting.isNotEmpty()
        waiting.add(onResult)
        if (alreadyAsking) {
            return
        }
        try {
            launch()
        } catch (_: RuntimeException) {
            complete(false)
        }
    }

    /** Delivers the system dialog's answer to every waiting caller. */
    fun onResult(granted: Boolean) = complete(granted)

    /** Answers every waiting caller with "not granted", e.g. when the screen goes away. */
    fun cancelPending() = complete(false)

    private fun complete(granted: Boolean) {
        val callbacks = waiting.toList()
        waiting.clear()
        callbacks.forEach { it(granted) }
    }
}
