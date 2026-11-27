package com.endurain.endurain.activity

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.RejectedExecutionException

/**
 * Hosts the method/event channels that bridge the Dart
 * `NativeActivityRecorderChannel` to the native foreground recorder.
 *
 * Channel names, method names, and payload keys mirror
 * `NativeActivityRecorderChannelContract`. Lifecycle transitions (start/pause/
 * resume/stop/discard) are owned here; point batches and collection failures
 * are emitted by the service via [ActivityRecorderCoordinator]. Drain/recover
 * read directly from the durable [ActiveActivityStore].
 *
 * Threading: handlers that touch the store (every save ends in `fd.sync()`)
 * run in call order on a single I/O thread and reply on the main thread, so
 * disk latency never blocks the UI. Any failure they raise is replied as
 * `store_read_failed` rather than thrown. Handlers that only start speech or
 * ask for a permission stay on the main thread.
 */
class ActivityRecorderChannel(
    context: Context,
    private val notificationPermission: NotificationPermissionRequester? = null,
) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    private val appContext = context.applicationContext
    private val store = ActiveActivityStore.of(appContext)

    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null

    /** Whether this engine's Dart started a start-countdown warm-up it has not ended. */
    @Volatile
    private var warmUpBegun = false

    /** Store work runs off the main thread, in call order. */
    private val ioExecutor: ExecutorService = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

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
        eventSink?.let(ActivityRecorderCoordinator::detach)
        eventSink = null
        methodChannel = null
        eventChannel = null
        // Dart can no longer end the countdown's warm-up, so end it here; it
        // is a no-op once a recording started from it.
        if (warmUpBegun) {
            warmUpBegun = false
            ActivityRecorderService.endWarmUp()
        }
        ioExecutor.shutdown()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            METHOD_START -> offMain(result) { handleStart(call, it) }
            METHOD_PAUSE -> offMain(result, ::handlePause)
            METHOD_RESUME -> offMain(result, ::handleResume)
            METHOD_STOP -> offMain(result, ::handleStop)
            METHOD_DISCARD -> offMain(result, ::handleDiscard)
            METHOD_DRAIN -> offMain(result) { handleDrain(call, it) }
            METHOD_RECOVER -> offMain(result, ::handleRecover)
            METHOD_SPEAK_PREVIEW -> handleSpeakPreview(call, result)
            METHOD_SPEAK_CUE -> handleSpeakCue(call, result)
            METHOD_BEGIN_START_WARM_UP -> offMain(result) { handleBeginStartWarmUp(call, it) }
            METHOD_REQUEST_NOTIFICATION_PERMISSION -> handleRequestNotificationPermission(result)
            METHOD_END_START_WARM_UP -> {
                warmUpBegun = false
                ActivityRecorderService.endWarmUp()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    /**
     * Runs [task] on the I/O thread with a reply that hops to the main thread.
     * An exception it leaves behind (a store that cannot be read or written)
     * becomes a typed `store_read_failed` reply; a reply already sent wins.
     */
    private fun offMain(result: MethodChannel.Result, task: (MethodChannel.Result) -> Unit) {
        val reply = MainThreadResult(result, mainHandler)
        try {
            ioExecutor.execute {
                try {
                    task(reply)
                } catch (_: Exception) {
                    reply.error(ERROR_STORE, "Unable to access the recording store", null)
                }
            }
        } catch (_: RejectedExecutionException) {
            // The channel was unregistered; its engine is going away.
            result.error(ERROR_STORE, "Recorder channel unregistered", null)
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        eventSink = events
        ActivityRecorderCoordinator.attach(events)
    }

    override fun onCancel(arguments: Any?) {
        eventSink?.let(ActivityRecorderCoordinator::detach)
        eventSink = null
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
        if (store.hasRecoverableData()) {
            result.error(ERROR_STATE, "A recoverable session already exists", null)
            return
        }
        // Before anything is persisted: nothing was recorded, so no session
        // may be left behind to block the next start.
        if (!hasLocationPermission()) {
            replyLocationPermissionMissing(result)
            return
        }
        val activityType = call.argument<String>("activityType") ?: ""
        val startedAt = call.argument<String>("startedAt") ?: IsoTime.nowUtc()
        val connectionOrigin = call.argument<String>("connectionOrigin")
        val connectionProfileId = call.argument<String>("connectionProfileId")
        val heartRateDeviceId =
            BluetoothAddressUtil.normalize(call.argument<String>("hrDeviceId"))
        val powerDeviceId =
            BluetoothAddressUtil.normalize(call.argument<String>("powerDeviceId"))
        val cadenceDeviceId =
            BluetoothAddressUtil.normalize(call.argument<String>("cadenceDeviceId"))
        val title = call.argument<String>("notificationTitle")
        val text = call.argument<String>("notificationText")
        // `Boolean`/`Int` arguments arrive as their boxed Kotlin types from the
        // method channel; default conservatively (disabled) if omitted by an
        // older Dart build.
        val autoPauseEnabled = call.argument<Boolean>("autoPauseEnabled") ?: false
        val autoPauseDelaySeconds = call.argument<Int>("autoPauseDelaySeconds") ?: 5
        @Suppress("UNCHECKED_CAST")
        val audioAnnouncements = call.argument<Map<String, Any?>>("audioAnnouncements")

        val session = ActiveActivitySessionData(
            localSessionId = localSessionId,
            activityType = activityType,
            status = ActiveActivitySessionData.STATUS_RECORDING,
            startedAt = startedAt,
            connectionOrigin = connectionOrigin,
            connectionProfileId = connectionProfileId,
            heartRateDeviceId = heartRateDeviceId,
            powerDeviceId = powerDeviceId,
            cadenceDeviceId = cadenceDeviceId,
            currentSegmentIndex = 0,
            autoPauseEnabled = autoPauseEnabled,
            autoPauseDelaySeconds = autoPauseDelaySeconds,
        )
        try {
            store.saveSession(session)
            AnnouncementStateData.fromStartArguments(audioAnnouncements)?.let {
                store.saveAnnouncementState(it)
            }
        } catch (_: Exception) {
            // Nothing recorded yet: a half-written start must not be left
            // behind to reject every later start as `invalid_state`.
            try {
                store.clear()
            } catch (_: Exception) {
                // Best effort; the store reports its own failure below.
            }
            result.error(ERROR_STORE, "Unable to persist the new recording", null)
            return
        }
        try {
            ActivityRecorderService.start(appContext, title, text)
        } catch (_: RuntimeException) {
            // The service never started, so no point was ever collected. Clear
            // the store rather than persisting an empty `failed` session:
            // leaving it behind makes `hasRecoverableData()` true forever, so
            // every later `start` is rejected with `invalid_state` and
            // recording stays broken until the process is restarted.
            store.clear()
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
        val nowMillis = System.currentTimeMillis()
        // Atomic against the recorder thread's own session rewrites.
        val updated = store.updateSession { session ->
            session.copy(
                status = ActiveActivitySessionData.STATUS_PAUSED,
                pausedAt = IsoTime.format(java.util.Date(nowMillis)),
                elapsedDurationSeconds = session.elapsedSecondsAt(nowMillis),
                pausedAutomatically = false,
            )
        }
        if (updated == null) {
            result.error(ERROR_STATE, "No active session", null)
            return
        }
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
        // The session stays paused, so it resumes once permission is back.
        if (!hasLocationPermission()) {
            replyLocationPermissionMissing(result)
            return
        }
        val nowMillis = System.currentTimeMillis()
        val updated = store.updateSession { current ->
            current.copy(
                status = ActiveActivitySessionData.STATUS_RECORDING,
                resumedAt = IsoTime.format(java.util.Date(nowMillis)),
                pausedAt = null,
                pausedAutomatically = false,
            )
        }
        if (updated == null) {
            result.error(ERROR_STATE, "No active session", null)
            return
        }
        try {
            ActivityRecorderService.resume(appContext)
        } catch (_: RuntimeException) {
            // Started from the background or refused by the system (for
            // example ForegroundServiceStartNotAllowedException). Put the
            // paused session back so the stored state matches the idle
            // service and the user can retry; no `failed` event, since the
            // recording itself is intact.
            store.saveSession(session)
            result.error(ERROR_SERVICE, "Unable to resume recorder service", null)
            return
        }
        ActivityRecorderCoordinator.emitSession(
            ActivityRecorderCoordinator.TYPE_RESUMED,
            updated,
        )
        result.success(null)
    }

    private fun handleStop(result: MethodChannel.Result) {
        val nowMillis = System.currentTimeMillis()
        // Mark the session completed before tearing the service down. The
        // collection guard in the recorder's fix pipeline drops any in-flight
        // fix once the status is no longer recording, so the recorder is
        // quiesced before Dart drains the store for completion.
        val updated = store.updateSession { session ->
            session.copy(
                status = ActiveActivitySessionData.STATUS_COMPLETED,
                endedAt = IsoTime.format(java.util.Date(nowMillis)),
                elapsedDurationSeconds = session.elapsedSecondsAt(nowMillis),
            )
        }
        ActivityRecorderService.stop(appContext)
        if (updated != null) {
            ActivityRecorderCoordinator.emitSession(
                ActivityRecorderCoordinator.TYPE_STOPPED,
                updated,
            )
        }
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
        result.success(store.readPoints(sinceOffset).map { it.toMap() })
    }

    private fun handleRecover(result: MethodChannel.Result) {
        result.success(SessionRecovery.recover(appContext)?.toMap())
    }

    /**
     * Whether the recorder may be started with `startForegroundService`.
     * Without location it cannot claim its `location` foreground type on
     * Android 14+, so it could never satisfy the `startForeground` contract
     * and the app would crash. The service keeps its own check for a
     * permission revoked after this one.
     */
    private fun hasLocationPermission(): Boolean =
        ActivityRecorderService.hasLocationPermission(appContext)

    /**
     * Rejects a recorder start for missing location permission. The event
     * lets Dart report the permission problem (`permissionLost` maps to
     * `locationPermissionDenied`), not a generic stream failure; it is
     * delivered after the reply, so it is the error Dart is left showing.
     */
    private fun replyLocationPermissionMissing(result: MethodChannel.Result) {
        ActivityRecorderCoordinator.emitFailed(
            ActivityRecorderCoordinator.REASON_PERMISSION_LOST,
        )
        result.error(ERROR_SERVICE, "Location permission is not granted", null)
    }

    private fun isSupportedVersion(call: MethodCall): Boolean {
        val version = call.argument<Int>("version") ?: return true
        return version == PAYLOAD_VERSION
    }

    /**
     * Speaks one sample announcement so the user can verify the device has a
     * working speech engine, at an audible volume, in the expected language.
     * Deliberately independent of the recorder lifecycle: it never touches the
     * durable store, so a preview cannot disturb an in-progress recording.
     */
    private fun handleSpeakPreview(call: MethodCall, result: MethodChannel.Result) {
        if (!isSupportedVersion(call)) {
            result.error(ERROR_VERSION, "Unsupported payload version", null)
            return
        }
        @Suppress("UNCHECKED_CAST")
        val arguments = call.argument<Map<String, Any?>>("audioAnnouncements")
        val state = AnnouncementStateData.fromStartArguments(arguments)
        if (state == null) {
            result.error(ERROR_ARGS, "Missing audioAnnouncements", null)
            return
        }
        AudioAnnouncer.speak(
            appContext,
            AnnouncementSpeechBuilder.buildPreview(state),
            state.duckOtherAudio,
            state.languageTag,
        )
        result.success(null)
    }

    /**
     * Starts the foreground service that keeps the app from being frozen
     * during the start countdown. Best effort: if Android refuses, the
     * countdown still runs while the app stays in the foreground.
     *
     * The optional `countdownSeconds` argument sizes the warm-up's safety
     * timeout; it is ignored when absent or not an integer.
     */
    private fun handleBeginStartWarmUp(call: MethodCall, result: MethodChannel.Result) {
        if (store.hasRecoverableData()) {
            result.success(null)
            return
        }
        if (!hasLocationPermission()) {
            // No `failed` event: no recording exists for Dart to fail.
            result.error(ERROR_SERVICE, "Location permission is not granted", null)
            return
        }
        try {
            ActivityRecorderService.beginWarmUp(appContext, countdownSecondsArgument(call))
            warmUpBegun = true
        } catch (_: RuntimeException) {
            // Started from the background or refused by the system.
        }
        result.success(null)
    }

    private fun countdownSecondsArgument(call: MethodCall): Long? {
        return when (val value = (call.arguments as? Map<*, *>)?.get(ARG_COUNTDOWN_SECONDS)) {
            is Int -> value.toLong()
            is Long -> value
            else -> null
        }
    }

    /**
     * Asks for the Android 13+ notification permission, which keeps the
     * recorder's foreground notification visible. Dart calls it right before
     * a recording or its start countdown begins, while the app is in front.
     * Replies whether the permission is granted afterwards; a "no" never
     * blocks recording, which runs without a visible notification.
     */
    private fun handleRequestNotificationPermission(result: MethodChannel.Result) {
        val requester = notificationPermission
        if (requester == null) {
            result.success(false)
            return
        }
        requester.request { granted -> result.success(granted) }
    }

    /**
     * Speaks one short start-countdown cue. Like the preview, it never
     * touches the durable session store.
     */
    private fun handleSpeakCue(call: MethodCall, result: MethodChannel.Result) {
        if (!isSupportedVersion(call)) {
            result.error(ERROR_VERSION, "Unsupported payload version", null)
            return
        }
        val text = call.argument<String>("text")
        val languageTag = call.argument<String>("languageTag")
        if (text.isNullOrBlank() || languageTag.isNullOrBlank()) {
            result.error(ERROR_ARGS, "Missing text or languageTag", null)
            return
        }
        val duck = call.argument<Boolean>("duckOtherAudio") ?: true
        AudioAnnouncer.speak(appContext, text, duck, languageTag)
        result.success(null)
    }

    companion object {
        const val PAYLOAD_VERSION = 2

        const val METHOD_CHANNEL = "endurain/activity_recorder/methods"
        const val EVENT_CHANNEL = "endurain/activity_recorder/events"

        const val METHOD_START = "start"
        const val METHOD_PAUSE = "pause"
        const val METHOD_RESUME = "resume"
        const val METHOD_STOP = "stop"
        const val METHOD_DISCARD = "discard"
        const val METHOD_DRAIN = "drain"
        const val METHOD_RECOVER = "recover"
        const val METHOD_SPEAK_PREVIEW = "speakAnnouncementPreview"
        const val METHOD_SPEAK_CUE = "speakCue"
        const val METHOD_BEGIN_START_WARM_UP = "beginStartWarmUp"
        const val METHOD_END_START_WARM_UP = "endStartWarmUp"
        const val METHOD_REQUEST_NOTIFICATION_PERMISSION = "requestNotificationPermission"

        private const val ARG_COUNTDOWN_SECONDS = "countdownSeconds"

        private const val ERROR_ARGS = "invalid_arguments"
        private const val ERROR_STATE = "invalid_state"
        private const val ERROR_SERVICE = "service_start_failed"
        private const val ERROR_STORE = "store_read_failed"
        private const val ERROR_VERSION = "unsupported_version"
    }
}
