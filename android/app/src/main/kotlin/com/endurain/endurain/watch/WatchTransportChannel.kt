package com.endurain.endurain.watch

import android.os.Handler
import android.os.Looper
import android.util.Log
import com.endurain.endurain.watchlink.HandoffFileStore
import com.endurain.endurain.watchlink.WatchProtocol
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/**
 * Serves the Dart `WatchTransportChannelContract` from a [WatchLink] and the
 * phone's durable inbox.
 *
 * Methods: `linkStatus`, `drainHandoffs` and `acknowledgeHandoff`, each with
 * a `version` argument that must match [WatchProtocol.PAYLOAD_VERSION].
 * Events: `linkStatusChanged` and `handoffAvailable`.
 */
class WatchTransportChannel(
    private val link: WatchLink,
    private val inbox: HandoffFileStore,
    private val executor: ExecutorService = Executors.newSingleThreadExecutor(),
) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    private val mainHandler = Handler(Looper.getMainLooper())
    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null

    fun register(messenger: BinaryMessenger) {
        methodChannel = MethodChannel(messenger, METHOD_CHANNEL).also { it.setMethodCallHandler(this) }
        eventChannel = EventChannel(messenger, EVENT_CHANNEL).also { it.setStreamHandler(this) }
        WatchHandoffEvents.listener = {
            mainHandler.post { send(mapOf("type" to "handoffAvailable")) }
        }
    }

    fun unregister() {
        WatchHandoffEvents.listener = null
        link.stopObserving()
        methodChannel?.setMethodCallHandler(null)
        eventChannel?.setStreamHandler(null)
        methodChannel = null
        eventChannel = null
        eventSink = null
        executor.shutdown()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method !in KNOWN_METHODS) {
            result.notImplemented()
            return
        }
        val version = (call.argument<Any>("version") as? Number)?.toInt()
        if (version != WatchProtocol.PAYLOAD_VERSION) {
            result.error(ERROR_UNSUPPORTED_VERSION, "Unsupported watch transport version", null)
            return
        }
        when (call.method) {
            "linkStatus" -> runInBackground(result) { link.linkStatus() }
            "drainHandoffs" ->
                executor.execute {
                    val handoffs =
                        try {
                            link.pullPendingHandoffs(inbox)
                            readInbox(inbox)
                        } catch (error: Exception) {
                            Log.w(TAG, "Could not read the watch inbox", error)
                            mainHandler.post {
                                result.error(ERROR_STORE_READ_FAILED, "Could not read the watch inbox", null)
                            }
                            return@execute
                        }
                    mainHandler.post { result.success(handoffs) }
                }
            else -> {
                val sessionId = call.argument<String>("sessionId")
                if (sessionId.isNullOrEmpty()) {
                    result.error(ERROR_INVALID_ARGUMENTS, "Missing sessionId", null)
                    return
                }
                runInBackground(result) {
                    inbox.remove(sessionId)
                    link.acknowledge(sessionId)
                    null
                }
            }
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        eventSink = events
        link.startObserving { status ->
            mainHandler.post { send(mapOf("type" to "linkStatusChanged", "linkStatus" to status)) }
        }
        executor.execute {
            val status = link.linkStatus()
            val hasPending = !inbox.isEmpty
            mainHandler.post {
                send(mapOf("type" to "linkStatusChanged", "linkStatus" to status))
                if (hasPending) send(mapOf("type" to "handoffAvailable"))
            }
        }
    }

    override fun onCancel(arguments: Any?) {
        link.stopObserving()
        eventSink = null
    }

    private fun send(event: Map<String, Any?>) {
        eventSink?.success(event)
    }

    private fun runInBackground(result: MethodChannel.Result, work: () -> Any?) {
        executor.execute {
            try {
                val value = work()
                mainHandler.post { result.success(value) }
            } catch (error: Exception) {
                Log.w(TAG, "Watch transport call failed", error)
                mainHandler.post { result.error(ERROR_STORE_READ_FAILED, error.javaClass.simpleName, null) }
            }
        }
    }

    companion object {
        private const val TAG = "EndurainWatch"
        const val METHOD_CHANNEL = "endurain/watch_transport/methods"
        const val EVENT_CHANNEL = "endurain/watch_transport/events"
        const val ERROR_INVALID_ARGUMENTS = "invalid_arguments"
        const val ERROR_UNSUPPORTED_VERSION = "unsupported_version"
        const val ERROR_STORE_READ_FAILED = "store_read_failed"
        private val KNOWN_METHODS = setOf("linkStatus", "drainHandoffs", "acknowledgeHandoff")

        /**
         * Every readable envelope in [inbox], as plain maps and lists the
         * Flutter codec accepts. An unreadable file is left in place (and
         * skipped) so a later app version can still read it.
         */
        fun readInbox(inbox: HandoffFileStore): List<Map<String, Any?>> =
            inbox.entries().mapNotNull { entry ->
                try {
                    toMap(JSONObject(entry.file.readText()))
                } catch (_: JSONException) {
                    null
                } catch (_: java.io.IOException) {
                    null
                }
            }

        fun toMap(json: JSONObject): Map<String, Any?> =
            json.keys().asSequence().associateWith { key -> toPlain(json.get(key)) }

        private fun toPlain(value: Any?): Any? =
            when (value) {
                JSONObject.NULL -> null
                is JSONObject -> toMap(value)
                is JSONArray -> (0 until value.length()).map { toPlain(value.get(it)) }
                else -> value
            }
    }
}
