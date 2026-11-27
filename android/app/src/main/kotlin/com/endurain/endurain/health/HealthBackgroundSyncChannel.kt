package com.endurain.endurain.health

import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * The method channel between Dart and the background trigger of automatic
 * health import. Mirrors `HealthBackgroundSyncChannelContract` in
 * `lib/features/health/services/health_background_sync_adapter.dart`.
 *
 * Registered on the app's engine (where Dart calls `listen` once it is ready
 * to run background syncs) and on every headless engine
 * [HealthBackgroundSyncRunner] starts (where Dart calls `reportFinished`).
 * Flutter calls the handler, and [run] must be called, on the main thread.
 */
class HealthBackgroundSyncChannel(
    private val setScheduled: (Boolean) -> Unit,
    private val onListen: (HealthBackgroundSyncChannel) -> Unit,
    private val onFinished: (Boolean) -> Unit,
) : MethodChannel.MethodCallHandler {
    private var channel: MethodChannel? = null

    /** The runs sent to Dart that it has not answered yet. */
    private val pendingRuns = mutableSetOf<PendingRun>()

    fun register(messenger: BinaryMessenger) {
        channel = MethodChannel(messenger, CHANNEL_NAME).also {
            it.setMethodCallHandler(this)
        }
    }

    /**
     * Detaches from the engine. A run Dart has not answered fails, since the
     * engine going away means the answer never comes.
     */
    fun unregister() {
        channel?.setMethodCallHandler(null)
        channel = null
        val unanswered = pendingRuns.toList()
        pendingRuns.clear()
        unanswered.forEach { it.onResult(false) }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            METHOD_SET_SCHEDULED -> {
                val scheduled = call.argument<Boolean>(ARG_SCHEDULED)
                    ?: return result.invalidArguments(ARG_SCHEDULED)
                setScheduled(scheduled)
                result.success(null)
            }
            METHOD_LISTEN -> {
                onListen(this)
                result.success(null)
            }
            METHOD_REPORT_FINISHED -> {
                val succeeded = call.argument<Boolean>(ARG_SUCCEEDED)
                    ?: return result.invalidArguments(ARG_SUCCEEDED)
                onFinished(succeeded)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    /**
     * Asks this engine's Dart side to run one sync. [onResult] gets whether it
     * succeeded; `false` when it failed, Dart does not answer the method, or
     * the engine goes away first.
     */
    fun run(onResult: (Boolean) -> Unit) {
        val channel = channel ?: return onResult(false)
        val run = PendingRun(onResult)
        pendingRuns.add(run)
        channel.invokeMethod(
            METHOD_RUN,
            null,
            object : MethodChannel.Result {
                override fun success(result: Any?) = finish(run, result == true)

                override fun error(code: String, message: String?, details: Any?) =
                    finish(run, false)

                override fun notImplemented() = finish(run, false)
            },
        )
    }

    private fun finish(run: PendingRun, succeeded: Boolean) {
        if (pendingRuns.remove(run)) run.onResult(succeeded)
    }

    /** One run sent to Dart; compared by identity, so each is answered once. */
    private class PendingRun(val onResult: (Boolean) -> Unit)

    private fun MethodChannel.Result.invalidArguments(name: String) =
        error(ERROR_INVALID_ARGUMENTS, "$name must be a boolean", null)

    internal companion object {
        const val CHANNEL_NAME = "endurain/health_background_sync"
        const val METHOD_SET_SCHEDULED = "setScheduled"
        const val METHOD_LISTEN = "listen"
        const val METHOD_RUN = "run"
        const val METHOD_REPORT_FINISHED = "reportFinished"
        const val ARG_SCHEDULED = "scheduled"
        const val ARG_SUCCEEDED = "succeeded"
        const val ERROR_INVALID_ARGUMENTS = "invalid_arguments"
    }
}
