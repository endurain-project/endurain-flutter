package com.endurain.endurain.wear

import android.content.Context
import android.util.Log
import com.endurain.endurain.watchlink.WatchActivityType
import com.endurain.endurain.watchlink.WatchRecordingStore
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.io.File

/**
 * Records one outdoor workout through an [ExerciseGateway] (Health Services)
 * and hands it to the phone.
 *
 * Health Services owns the exercise (GPS, heart rate, distance) and keeps it
 * running even if this process dies; [ExerciseService] keeps the process in
 * the foreground meanwhile. GPS fixes are written to a durable
 * [WatchRecordingStore] as they arrive (off the main thread, through a
 * [RecordingWriter]), so a crash costs at most a few
 * seconds of track. On finish the session is turned into a handoff envelope
 * and queued in the [HandoffSink] (the [PhoneLink] outbox).
 */
class WorkoutRecorder(
    private val gateway: ExerciseGateway,
    private val store: WatchRecordingStore,
    handoffs: HandoffSink,
    private val platform: WorkoutPlatform,
    private val countdownSetting: CountdownSetting,
    private val scope: CoroutineScope,
    restoreBackoffMillis: List<Long> = RESTORE_BACKOFF_MILLIS,
    ioDispatcher: CoroutineDispatcher = Dispatchers.IO,
    endTimeoutMillis: Long = END_TIMEOUT_MILLIS,
    countdownTickMillis: Long = CountdownController.TICK_MILLIS,
) {
    constructor(context: Context, phoneLink: PhoneLink) : this(
        gateway = HealthServicesExerciseGateway(context),
        store = WatchRecordingStore(File(context.applicationContext.noBackupFilesDir, "watch_recording")),
        handoffs = phoneLink,
        platform = AndroidWorkoutPlatform(context),
        countdownSetting = StartCountdownSettings(context),
        scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate),
    )

    private val session = WorkoutSession(platform, RecordingWriter(store, scope, ioDispatcher))
    private val mutableState get() = session.state
    val state: StateFlow<WorkoutUiState> = session.state.asStateFlow()

    private val mutableCountdownSeconds = MutableStateFlow(countdownSetting.seconds)

    /** Seconds counted down before a workout starts, saved on the watch. */
    val countdownSeconds: StateFlow<Int> = mutableCountdownSeconds.asStateFlow()

    private val subscription =
        ExerciseSubscription(
            gateway,
            scope,
            object : ExerciseListener {
                override fun onUpdate(snapshot: ExerciseSnapshot) {
                    handle(snapshot)
                }

                override fun onAvailabilityChanged(
                    metric: WorkoutMetric,
                    status: SensorStatus,
                ) {
                    when (metric) {
                        WorkoutMetric.LOCATION -> mutableState.update { it.copy(locationStatus = status) }
                        WorkoutMetric.HEART_RATE -> mutableState.update { it.copy(heartRateStatus = status) }
                        WorkoutMetric.DISTANCE -> Unit
                    }
                }

                override fun onRegistrationFailed(error: Throwable) {
                    Log.w(TAG, "Could not receive exercise updates", error)
                }
            },
        )

    private val finisher =
        WorkoutFinisher(
            session = session,
            gateway = gateway,
            handoff = WorkoutHandoff(store, handoffs),
            platform = platform,
            subscription = subscription,
            scope = scope,
            endTimeoutMillis = endTimeoutMillis,
        )

    private val starter =
        WorkoutStarter(
            session = session,
            store = store,
            gateway = gateway,
            platform = platform,
            subscription = subscription,
            countdownSeconds = countdownSeconds,
            scope = scope,
            countdownTickMillis = countdownTickMillis,
        )

    private val restorer =
        WorkoutRestorer(
            session = session,
            store = store,
            gateway = gateway,
            finisher = finisher,
            subscription = subscription,
            scope = scope,
            backoffMillis = restoreBackoffMillis,
        )

    fun start(type: WatchActivityType) {
        if (mutableState.value.phase != WorkoutPhase.Idle) return
        // A saved recording whose restore failed is still on disk; a new
        // workout would overwrite it. Dismissing the error retries the restore.
        if (restorer.failed) return
        starter.start(type)
    }

    /** Starts the workout that [start] held back until the user agreed to end the other app's. */
    fun confirmTakeover() = starter.confirmTakeover()

    /** Backs out of starting while another app's workout runs. */
    fun cancelTakeover() = starter.cancelTakeover()

    /** Whether a workout is saved on disk (recording, or waiting to be finished). */
    fun hasSavedRecording(): Boolean = store.hasRecording()

    /** Cycles the countdown through [StartCountdown.OPTIONS]. */
    fun cycleCountdown() {
        val next = StartCountdown.next(countdownSeconds.value)
        countdownSetting.seconds = next
        mutableCountdownSeconds.value = next
    }

    /** Starts the workout now instead of waiting for the countdown. */
    fun skipCountdown() = starter.skipCountdown()

    /** Stops the countdown without recording anything. */
    fun cancelCountdown() = starter.cancelCountdown()

    fun pause() {
        scope.launchLogged("pause the exercise") { gateway.pause() }
    }

    fun resume() {
        scope.launchLogged("resume the exercise") { gateway.resume() }
    }

    fun end() = finisher.end()

    fun dismissSummary() {
        if (mutableState.value.phase is WorkoutPhase.Finished) {
            mutableState.update { WorkoutUiState() }
        }
    }

    fun dismissError() {
        mutableState.update { it.copy(errorMessage = null) }
        restorer.retry()
    }

    /**
     * Called at launch: re-attaches to an exercise Health Services kept
     * running while the process was dead, or finishes and sends a recording
     * whose exercise is gone. See [WorkoutRestorer].
     */
    fun restoreUnfinishedRecording() = restorer.restore()

    // MARK: - Exercise updates

    /** Applies a Health Services update; runs on the main thread, writes go through the session's writer. */
    private fun handle(snapshot: ExerciseSnapshot) {
        val current = session.recording ?: return

        snapshot.heartRateBpm?.let { bpm ->
            snapshot.heartRateAtMillis?.let { session.track.noteHeartRate(bpm, it) }
            mutableState.update { it.copy(heartRateBpm = bpm) }
        }
        snapshot.distanceTotalMeters?.let { total ->
            mutableState.update { it.copy(distanceMeters = total) }
        }
        snapshot.activeDurationMillis?.let { session.activeDurationMillis = it }

        if (!current.isPaused && snapshot.state == GatewayExerciseState.ACTIVE) {
            if (session.track.add(snapshot.locations, current)) session.flushPoints()
        }

        val now = platform.nowMillis()
        when {
            snapshot.state == GatewayExerciseState.ENDED -> scope.launch { finisher.finish() }
            snapshot.state == GatewayExerciseState.PAUSED && !current.isPaused -> {
                session.flushPoints()
                session.setRecording(current.paused(now))
                mutableState.update { it.copy(phase = WorkoutPhase.Active(paused = true)) }
                session.updateServiceStatus()
            }
            snapshot.state == GatewayExerciseState.ACTIVE && current.isPaused -> {
                session.setRecording(current.resumed(now))
                mutableState.update { it.copy(phase = WorkoutPhase.Active(paused = false)) }
                session.updateServiceStatus()
            }
        }
    }

    companion object {
        /** How long to wait for Health Services to report the end before finishing anyway. */
        const val END_TIMEOUT_MILLIS = 20_000L

        /** Waits between attempts to ask Health Services who owns the exercise at launch. */
        val RESTORE_BACKOFF_MILLIS = listOf(1_000L, 2_000L, 4_000L, 8_000L)
    }
}
