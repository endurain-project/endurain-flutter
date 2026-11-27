package com.endurain.endurain.wear

import android.util.Log
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch

/** Log tag shared by the watch app. */
internal const val TAG = "EndurainWear"

/** Runs [block] in the background, logging instead of swallowing its failure. */
internal fun CoroutineScope.launchLogged(
    what: String,
    block: suspend () -> Unit,
) {
    launch {
        try {
            block()
        } catch (error: CancellationException) {
            throw error
        } catch (error: Exception) {
            Log.w(TAG, "Could not $what", error)
        }
    }
}
