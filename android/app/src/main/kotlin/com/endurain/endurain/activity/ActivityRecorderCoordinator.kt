package com.endurain.endurain.activity

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel

/**
 * In-process bridge between the foreground service and the Flutter event sink.
 *
 * The foreground service and the [ActivityRecorderChannel] run in the same
 * process, so a volatile sink reference is sufficient. When Flutter is detached
 * (app killed/backgrounded with no engine) events are dropped silently; points
 * are still persisted durably and replayed on the next `drain`.
 *
 * Payloads carry only sanitized lifecycle data and track points; no file paths,
 * tokens, or free-form diagnostics are emitted here.
 */
object ActivityRecorderCoordinator {
    @Volatile
    private var eventSink: EventChannel.EventSink? = null

    private val mainHandler = Handler(Looper.getMainLooper())

    fun attach(sink: EventChannel.EventSink) {
        eventSink = sink
    }

    fun detach() {
        eventSink = null
    }

    fun emitSession(type: String, session: ActiveActivitySessionData) {
        emit(
            mapOf(
                KEY_TYPE to type,
                KEY_SESSION to session.toMap(),
            ),
        )
    }

    fun emitPointBatch(points: List<RecordedActivityPointData>) {
        if (points.isEmpty()) {
            return
        }
        emit(
            mapOf(
                KEY_TYPE to TYPE_POINT_BATCH_AVAILABLE,
                KEY_POINTS to points.map { it.toMap() },
            ),
        )
    }

    fun emitRecoverableStateChanged(session: ActiveActivitySessionData?) {
        val payload = LinkedHashMap<String, Any?>()
        payload[KEY_TYPE] = TYPE_RECOVERABLE_STATE_CHANGED
        if (session != null) {
            payload[KEY_SESSION] = session.toMap()
        }
        emit(payload)
    }

    fun emitFailed(reason: String) {
        emit(
            mapOf(
                KEY_TYPE to TYPE_FAILED,
                KEY_REASON to reason,
            ),
        )
    }

    private fun emit(payload: Map<String, Any?>) {
        val sink = eventSink ?: return
        mainHandler.post {
            // The sink may have detached between the null check and delivery.
            if (eventSink === sink) {
                sink.success(payload)
            }
        }
    }

    // Event payload keys (mirror NativeActivityRecorderChannelContract).
    const val KEY_TYPE = "type"
    const val KEY_SESSION = "session"
    const val KEY_POINTS = "points"
    const val KEY_REASON = "reason"

    // Event type values.
    const val TYPE_STARTED = "started"
    const val TYPE_POINT_BATCH_AVAILABLE = "pointBatchAvailable"
    const val TYPE_PAUSED = "paused"
    const val TYPE_RESUMED = "resumed"
    const val TYPE_STOPPED = "stopped"
    const val TYPE_FAILED = "failed"
    const val TYPE_RECOVERABLE_STATE_CHANGED = "recoverableStateChanged"

    // Failure reasons (mirror Dart ActivityRecorderFailureReason names).
    const val REASON_LOCATION_STREAM_FAILED = "locationStreamFailed"
    const val REASON_LOCATION_UNAVAILABLE = "locationUnavailable"
    const val REASON_PERMISSION_LOST = "permissionLost"
    const val REASON_PERSISTENCE_FAILED = "persistenceFailed"
    const val REASON_UNSUPPORTED_PLATFORM = "unsupportedPlatform"
}
