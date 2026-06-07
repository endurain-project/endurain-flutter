package com.endurain.endurain.activity

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlin.math.max

/**
 * Hosts the method/event channels that bridge the Dart
 * `NativeActivityRecorderChannel` to the native foreground recorder.
 *
 * Channel names, method names, and payload keys mirror
 * `NativeActivityRecorderChannelContract`. Lifecycle transitions (start/pause/
 * resume/stop/discard) are owned here; point batches and collection failures
 * are emitted by the service via [ActivityRecorderCoordinator]. Drain/recover
 * read directly from the durable [ActiveActivityStore].
 */
class ActivityRecorderChannel(context: Context) :
    MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    private val appContext = context.applicationContext
    private val store = ActiveActivityStore.of(appContext)

    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null

    fun register(messenger: BinaryMessenger) {
        methodChannel = MethodChannel(messenger, METHOD_CHANNEL).also {
            it.setMethodCallHandler(this)
        }
        eventChannel = EventChannel(messenger, EVENT_CHANNEL).also {
            it.setStreamHandler(this)
        }
    }

    fun unregister() {
        methodChannel?.setMethodCallHandler(null)
        eventChannel?.setStreamHandler(null)
        ActivityRecorderCoordinator.detach()
        methodChannel = null
        eventChannel = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            METHOD_START -> handleStart(call, result)
            METHOD_PAUSE -> handlePause(result)
            METHOD_RESUME -> handleResume(result)
            METHOD_STOP -> handleStop(result)
            METHOD_DISCARD -> handleDiscard(result)
            METHOD_DRAIN -> handleDrain(call, result)
            METHOD_RECOVER -> handleRecover(result)
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        ActivityRecorderCoordinator.attach(events)
    }

    override fun onCancel(arguments: Any?) {
        ActivityRecorderCoordinator.detach()
    }

    private fun handleStart(call: MethodCall, result: MethodChannel.Result) {
        if (!isSupportedVersion(call)) {
            result.error(ERROR_VERSION, "Unsupported payload version", null)
            return
        }
        val localSessionId = call.argument<String>("localSessionId")
        if (localSessionId.isNullOrEmpty()) {
            result.error(ERROR_ARGS, "Missing localSessionId", null)
            return
        }
        val activityType = call.argument<String>("activityType") ?: ""
        val startedAt = call.argument<String>("startedAt") ?: IsoTime.nowUtc()
        val title = call.argument<String>("notificationTitle")
        val text = call.argument<String>("notificationText")

        val session = ActiveActivitySessionData(
            localSessionId = localSessionId,
            activityType = activityType,
            status = ActiveActivitySessionData.STATUS_RECORDING,
            startedAt = startedAt,
            currentSegmentIndex = 0,
        )
        store.clear()
        store.saveSession(session)
        try {
            ActivityRecorderService.start(appContext, title, text)
        } catch (_: RuntimeException) {
            store.saveSession(
                session.copy(status = ActiveActivitySessionData.STATUS_FAILED),
            )
            ActivityRecorderCoordinator.emitFailed(
                ActivityRecorderCoordinator.REASON_LOCATION_STREAM_FAILED,
            )
            result.error(ERROR_SERVICE, "Unable to start recorder service", null)
            return
        }
        ActivityRecorderCoordinator.emitSession(
            ActivityRecorderCoordinator.TYPE_STARTED,
            session,
        )
        result.success(null)
    }

    private fun handlePause(result: MethodChannel.Result) {
        val session = store.loadSession()
        if (session == null) {
            result.error(ERROR_STATE, "No active session", null)
            return
        }
        val nowMillis = System.currentTimeMillis()
        val updated = session.copy(
            status = ActiveActivitySessionData.STATUS_PAUSED,
            pausedAt = IsoTime.format(java.util.Date(nowMillis)),
            elapsedDurationSeconds = elapsedSeconds(session, nowMillis),
        )
        store.saveSession(updated)
        ActivityRecorderService.pause(appContext)
        ActivityRecorderCoordinator.emitSession(
            ActivityRecorderCoordinator.TYPE_PAUSED,
            updated,
        )
        result.success(null)
    }

    private fun handleResume(result: MethodChannel.Result) {
        val session = store.loadSession()
        if (session == null) {
            result.error(ERROR_STATE, "No active session", null)
            return
        }
        val nowMillis = System.currentTimeMillis()
        val updated = session.copy(
            status = ActiveActivitySessionData.STATUS_RECORDING,
            resumedAt = IsoTime.format(java.util.Date(nowMillis)),
            pausedAt = null,
        )
        store.saveSession(updated)
        ActivityRecorderService.resume(appContext)
        ActivityRecorderCoordinator.emitSession(
            ActivityRecorderCoordinator.TYPE_RESUMED,
            updated,
        )
        result.success(null)
    }

    private fun handleStop(result: MethodChannel.Result) {
        val session = store.loadSession()
        if (session == null) {
            ActivityRecorderService.stop(appContext)
            result.success(null)
            return
        }
        val nowMillis = System.currentTimeMillis()
        val updated = session.copy(
            status = ActiveActivitySessionData.STATUS_COMPLETED,
            endedAt = IsoTime.format(java.util.Date(nowMillis)),
            elapsedDurationSeconds = elapsedSeconds(session, nowMillis),
        )
        // Mark the session completed before tearing the service down. The
        // collection guard in onLocationFix drops any in-flight fix once the
        // status is no longer recording, so the recorder is quiesced before
        // Dart drains the store for completion.
        store.saveSession(updated)
        ActivityRecorderService.stop(appContext)
        ActivityRecorderCoordinator.emitSession(
            ActivityRecorderCoordinator.TYPE_STOPPED,
            updated,
        )
        result.success(null)
    }

    private fun handleDiscard(result: MethodChannel.Result) {
        ActivityRecorderService.stop(appContext)
        store.clear()
        ActivityRecorderCoordinator.emitRecoverableStateChanged(null)
        result.success(null)
    }

    private fun handleDrain(call: MethodCall, result: MethodChannel.Result) {
        val sinceOffset = call.argument<Int>("sinceOffset") ?: 0
        val points = store.readPoints(sinceOffset).map { it.toMap() }
        result.success(points)
    }

    private fun handleRecover(result: MethodChannel.Result) {
        result.success(store.loadSession()?.toMap())
    }

    /**
     * Accumulated elapsed seconds, mirroring the Dart geolocator recorder:
     * paused sessions keep their stored value; otherwise add the current
     * segment's running time from `resumedAt ?? startedAt`.
     */
    private fun elapsedSeconds(
        session: ActiveActivitySessionData,
        referenceMillis: Long,
    ): Int {
        if (session.status == ActiveActivitySessionData.STATUS_PAUSED) {
            return session.elapsedDurationSeconds
        }
        val anchor = IsoTime.toEpochMillis(session.resumedAt ?: session.startedAt)
            ?: return session.elapsedDurationSeconds
        val segmentSeconds = ((referenceMillis - anchor) / 1000L).toInt()
        return session.elapsedDurationSeconds + max(0, segmentSeconds)
    }

    private fun isSupportedVersion(call: MethodCall): Boolean {
        val version = call.argument<Int>("version") ?: return true
        return version == PAYLOAD_VERSION
    }

    companion object {
        const val PAYLOAD_VERSION = 1

        const val METHOD_CHANNEL = "endurain/activity_recorder/methods"
        const val EVENT_CHANNEL = "endurain/activity_recorder/events"

        const val METHOD_START = "start"
        const val METHOD_PAUSE = "pause"
        const val METHOD_RESUME = "resume"
        const val METHOD_STOP = "stop"
        const val METHOD_DISCARD = "discard"
        const val METHOD_DRAIN = "drain"
        const val METHOD_RECOVER = "recover"

        private const val ERROR_ARGS = "invalid_arguments"
        private const val ERROR_STATE = "invalid_state"
        private const val ERROR_SERVICE = "service_start_failed"
        private const val ERROR_VERSION = "unsupported_version"
    }
}
