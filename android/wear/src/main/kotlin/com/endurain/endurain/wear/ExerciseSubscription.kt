package com.endurain.endurain.wear

import kotlinx.coroutines.CoroutineScope

/** Keeps [listener] registered with the [gateway] at most once, and removes it in the background. */
internal class ExerciseSubscription(
    private val gateway: ExerciseGateway,
    private val scope: CoroutineScope,
    private val listener: ExerciseListener,
) {
    private var registered = false

    fun register() {
        if (registered) return
        gateway.setListener(listener)
        registered = true
    }

    fun unregister() {
        if (!registered) return
        registered = false
        scope.launchLogged("stop exercise updates") { gateway.clearListener() }
    }
}
