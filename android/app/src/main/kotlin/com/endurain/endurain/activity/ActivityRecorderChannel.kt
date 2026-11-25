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
 */
class ActivityRecorderChannel(context: Context) :
    MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    private val appContext = context.applicationContext
    private val store = ActiveActivityStore.of(appContext)

    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null

    /** Whether this engine's Dart started a start-countdown warm-up it has not ended. */
    private var warmUpBegun = false

    /** Drains read the points file off the main thread, in call order. */
    private val drainExecutor: ExecutorService = Executors.newSingleThreadExecutor()
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
        drainExecutor.shutdown()
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
            METHOD_SPEAK_PREVIEW -> handleSpeakPreview(call, result)
            METHOD_SPEAK_CUE -> handleSpeakCue(call, result)
            METHOD_BEGIN_START_WARM_UP -> handleBeginStartWarmUp(result)
            METHOD_END_START_WARM_UP -> {
                warmUpBegun = false
                ActivityRecorderService.endWarmUp()
                result.success(null)
            }
            else -> result.notImplemented()
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
        store.saveSession(session)
        AnnouncementStateData.fromStartArguments(audioAnnouncements)?.let {
            store.saveAnnouncementState(it)
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
        val session = store.loadSession()
        if (session == null) {
            result.error(ERROR_STATE, "No active session", null)
            return
        }
        val nowMillis = System.currentTimeMillis()
        val updated = session.copy(
            status = ActiveActivitySessionData.STATUS_PAUSED,
            pausedAt = IsoTime.format(java.util.Date(nowMillis)),
            elapsedDurationSeconds = session.elapsedSecondsAt(nowMillis),
            pausedAutomatically = false,
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
            pausedAutomatically = false,
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
            elapsedDurationSeconds = session.elapsedSecondsAt(nowMillis),
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
        try {
            drainExecutor.execute {
                val points = try {
                    store.readPoints(sinceOffset).map { it.toMap() }
                } catch (_: Exception) {
                    mainHandler.post {
                        result.error(ERROR_STORE, "Unable to read recorded points", null)
                    }
                    return@execute
                }
                mainHandler.post { result.success(points) }
            }
        } catch (_: RejectedExecutionException) {
            // The channel was unregistered; its engine is going away.
            result.error(ERROR_STORE, "Recorder channel unregistered", null)
        }
    }

    private fun handleRecover(result: MethodChannel.Result) {
        try {
            result.success(ActivityRecorderService.recover(appContext)?.toMap())
        } catch (_: Exception) {
            result.error(ERROR_STORE, "Unable to recover recording", null)
        }
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
     */
    private fun handleBeginStartWarmUp(result: MethodChannel.Result) {
        if (store.hasRecoverableData()) {
            result.success(null)
            return
        }
        try {
            ActivityRecorderService.beginWarmUp(appContext)
            warmUpBegun = true
        } catch (_: RuntimeException) {
            // Started from the background or refused by the system.
        }
        result.success(null)
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

        private const val ERROR_ARGS = "invalid_arguments"
        private const val ERROR_STATE = "invalid_state"
        private const val ERROR_SERVICE = "service_start_failed"
        private const val ERROR_STORE = "store_read_failed"
        private const val ERROR_VERSION = "unsupported_version"
    }
}
