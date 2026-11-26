package com.endurain.endurain.wear

import android.content.Context
import android.util.Log
import androidx.annotation.StringRes
import com.endurain.endurain.watchlink.WatchActivityType
import com.endurain.endurain.watchlink.WatchHandoffBuilder
import com.endurain.endurain.watchlink.WatchRecordedPoint
import com.endurain.endurain.watchlink.WatchRecording
import com.endurain.endurain.watchlink.WatchRecordingStore
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.io.File
import java.io.IOException
import java.util.UUID

sealed interface WorkoutPhase {
    data object Idle : WorkoutPhase

    data object Starting : WorkoutPhase

    /**
     * Counting down to the start. The exercise is prepared (sensors warming
     * up, [ExerciseService] keeping the app alive) but nothing records yet.
     */
    data class CountingDown(val endsAtMillis: Long) : WorkoutPhase

    data class Active(val paused: Boolean) : WorkoutPhase

    data object Ending : WorkoutPhase

    data class Finished(val summary: WorkoutSummary) : WorkoutPhase
}

data class WorkoutSummary(
    val activityType: WatchActivityType,
    val elapsedMillis: Long,
    val distanceMeters: Double?,
    val hasRoute: Boolean,
)

data class WorkoutUiState(
    val phase: WorkoutPhase = WorkoutPhase.Idle,
    val activityType: WatchActivityType? = null,
    val recording: WatchRecording? = null,
    val distanceMeters: Double? = null,
    val heartRateBpm: Int? = null,
    val locationStatus: SensorStatus = SensorStatus.UNKNOWN,
    val heartRateStatus: SensorStatus = SensorStatus.UNKNOWN,
    @StringRes val errorMessage: Int? = null,
)

/** Receives the finished workout's handoff envelope. */
fun interface HandoffSink {
    @Throws(IOException::class)
    fun enqueue(
        data: ByteArray,
        sessionId: String,
    )
}

/**
 * Records one outdoor workout through an [ExerciseGateway] (Health Services)
 * and hands it to the phone.
 *
 * Health Services owns the exercise (GPS, heart rate, distance) and keeps it
 * running even if this process dies; [ExerciseService] keeps the process in
 * the foreground meanwhile. GPS fixes are written to a durable
 * [WatchRecordingStore] as they arrive, so a crash costs at most a few
 * seconds of track. On finish the session is turned into a handoff envelope
 * and queued in the [HandoffSink] (the [PhoneLink] outbox).
 */
class WorkoutRecorder(
    private val gateway: ExerciseGateway,
    private val store: WatchRecordingStore,
    private val handoffs: HandoffSink,
    private val platform: WorkoutPlatform,
    private val countdownSetting: CountdownSetting,
    private val scope: CoroutineScope,
    private val restoreBackoffMillis: List<Long> = RESTORE_BACKOFF_MILLIS,
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

    private val mutableState = MutableStateFlow(WorkoutUiState())
    val state: StateFlow<WorkoutUiState> = mutableState.asStateFlow()

    private val mutableCountdownSeconds = MutableStateFlow(countdownSetting.seconds)

    /** Seconds counted down before a workout starts, saved on the watch. */
    val countdownSeconds: StateFlow<Int> = mutableCountdownSeconds.asStateFlow()

    private val countdown =
        CountdownController(
            scope = scope,
            nowMillis = platform::nowMillis,
            onCue = platform::vibrateTick,
            onFinished = ::finishCountdown,
            tickMillis = countdownTickMillis,
        )

    private var pendingStart: Pair<WatchActivityType, Set<WorkoutMetric>>? = null

    private var recording: WatchRecording? = null
    private val points = mutableListOf<WatchRecordedPoint>()
    private val unsavedPoints = mutableListOf<WatchRecordedPoint>()
    private var lastHeartRate: Pair<Int, Long>? = null
    private var activeDurationMillis: Long? = null
    private var persistedDistance: Double? = null
    private var callbackRegistered = false
    private var finishing = false

    /** Set while a restore could not tell whether the exercise still runs; dismissing its message retries. */
    private var restoreFailed = false

    /** Whether the start flow prepared or started an exercise that [failStart] must end. */
    private var exerciseNeedsEnding = false

    fun start(type: WatchActivityType) {
        if (mutableState.value.phase != WorkoutPhase.Idle) return
        // A saved recording whose restore failed is still on disk; a new
        // workout would overwrite it. Dismissing the error retries the restore.
        if (restoreFailed) return
        mutableState.update { it.copy(phase = WorkoutPhase.Starting, errorMessage = null) }
        exerciseNeedsEnding = false
        scope.launch {
            try {
                val supported = gateway.supportedMetrics(type)
                if (supported == null) {
                    fail(R.string.exercise_unsupported)
                    return@launch
                }
                // Only location is required to start, so leave out what the
                // user declined: Health Services rejects the whole exercise
                // when a requested data type lacks its permission. The warm-up
                // types derive from these, so they are filtered too.
                val metrics =
                    ExercisePermissions.permitted(platform.sdkInt, platform::isGranted)
                        .filter { it in supported }
                        .toSet()

                val seconds = countdownSeconds.value
                if (seconds > 0) {
                    beginCountdown(type, metrics, seconds)
                    return@launch
                }
                beginExercise(type, metrics)
            } catch (error: CancellationException) {
                throw error
            } catch (error: Exception) {
                failStart(error)
            }
        }
    }

    /** Whether a workout is saved on disk (recording, or waiting to be finished). */
    fun hasSavedRecording(): Boolean = store.hasRecording()

    /** Cycles the countdown through [StartCountdown.OPTIONS]. */
    fun cycleCountdown() {
        val next = StartCountdown.next(countdownSeconds.value)
        countdownSetting.seconds = next
        mutableCountdownSeconds.value = next
    }

    /** Starts the workout now instead of waiting for the countdown. */
    fun skipCountdown() {
        if (mutableState.value.phase !is WorkoutPhase.CountingDown) return
        countdown.cancel()
        scope.launch { finishCountdown() }
    }

    /** Stops the countdown without recording anything. */
    fun cancelCountdown() {
        if (mutableState.value.phase !is WorkoutPhase.CountingDown) return
        countdown.cancel()
        pendingStart = null
        mutableState.update { WorkoutUiState() }
        platform.stopService()
        // Ends the prepared exercise so the sensors stop warming up.
        scope.launch { runCatching { gateway.end() } }
    }

    // MARK: - Countdown

    private suspend fun beginCountdown(
        type: WatchActivityType,
        metrics: Set<WorkoutMetric>,
        seconds: Int,
    ) {
        try {
            gateway.prepare(type, metrics)
            exerciseNeedsEnding = true
        } catch (error: CancellationException) {
            throw error
        } catch (error: Exception) {
            // Only the warm-up is lost: the countdown and the workout still run.
            Log.w(TAG, "Could not prepare the exercise", error)
        }
        // Keeps the app alive while the wrist is down during the countdown.
        platform.startService(countingDown = true)
        pendingStart = type to metrics
        val endsAt = platform.nowMillis() + seconds * 1000L
        mutableState.update {
            it.copy(phase = WorkoutPhase.CountingDown(endsAt), activityType = type)
        }
        countdown.start(endsAt)
    }

    private suspend fun finishCountdown() {
        if (mutableState.value.phase !is WorkoutPhase.CountingDown) return
        val (type, metrics) = pendingStart ?: return
        pendingStart = null
        mutableState.update { it.copy(phase = WorkoutPhase.Starting) }
        try {
            beginExercise(type, metrics)
            platform.vibrateStart()
        } catch (error: CancellationException) {
            throw error
        } catch (error: Exception) {
            failStart(error)
        }
    }

    // MARK: - Starting

    private suspend fun beginExercise(
        type: WatchActivityType,
        metrics: Set<WorkoutMetric>,
    ) {
        val newRecording = WatchRecording(UUID.randomUUID().toString(), type, platform.nowMillis())
        store.begin(newRecording)
        attach(newRecording, emptyList())
        registerCallback()
        gateway.start(type, metrics)
        exerciseNeedsEnding = true
        // After a countdown the service is already in the foreground; this
        // only switches its notification to "recording". Android can refuse
        // the call when the countdown ended with the app in the background,
        // which must not fail a workout Health Services is already recording.
        runCatching { platform.startService() }
            .onFailure { Log.w(TAG, "Could not update the workout foreground service", it) }
        exerciseNeedsEnding = false
        mutableState.update { it.copy(phase = WorkoutPhase.Active(paused = false)) }
    }

    private fun failStart(error: Exception) {
        Log.w(TAG, "Could not start a workout", error)
        platform.stopService()
        store.clear()
        detach()
        if (exerciseNeedsEnding) {
            // Nothing records it any more: end the prepared or started
            // exercise so Health Services does not keep the sensors on.
            exerciseNeedsEnding = false
            unregisterCallback()
            scope.launch { runCatching { gateway.end() } }
        }
        fail(R.string.start_failed)
    }

    fun pause() {
        scope.launch { runCatching { gateway.pause() } }
    }

    fun resume() {
        scope.launch { runCatching { gateway.resume() } }
    }

    fun end() {
        val phase = mutableState.value.phase
        if (phase !is WorkoutPhase.Active) return
        mutableState.update { it.copy(phase = WorkoutPhase.Ending) }
        scope.launch {
            try {
                gateway.end()
            } catch (error: CancellationException) {
                throw error
            } catch (error: Exception) {
                // The exercise is gone already: finish with what was recorded.
                Log.w(TAG, "Could not end the exercise", error)
                finish()
            }
        }
    }

    fun dismissSummary() {
        if (mutableState.value.phase is WorkoutPhase.Finished) {
            mutableState.update { WorkoutUiState() }
        }
    }

    fun dismissError() {
        mutableState.update { it.copy(errorMessage = null) }
        if (restoreFailed) {
            restoreFailed = false
            restoreUnfinishedRecording()
        }
    }

    /**
     * Called at launch: re-attaches to an exercise Health Services kept
     * running while the process was dead, or finishes and sends a recording
     * whose exercise is gone.
     *
     * A failure to ask Health Services is not "the exercise is gone": it is
     * retried with backoff, and when it keeps failing the saved recording is
     * left untouched and a message offers another try.
     */
    fun restoreUnfinishedRecording() {
        val (saved, savedPoints) = store.load() ?: return
        // Blocks starting a new workout, which would overwrite the saved one.
        mutableState.update { it.copy(phase = WorkoutPhase.Starting) }
        scope.launch {
            val owned = readOwnership()
            when (owned) {
                null -> {
                    restoreFailed = true
                    mutableState.update { WorkoutUiState(errorMessage = R.string.restore_failed) }
                }
                false -> {
                    finishInterrupted(saved, savedPoints)
                    mutableState.update { WorkoutUiState(errorMessage = it.errorMessage) }
                }
                true -> {
                    attach(saved, savedPoints)
                    registerCallback()
                    runCatching { platform.startService() }
                    mutableState.update { it.copy(phase = WorkoutPhase.Active(paused = saved.isPaused)) }
                }
            }
        }
    }

    /** Whether Health Services runs our exercise, or null when it could not be asked. */
    private suspend fun readOwnership(): Boolean? {
        var attempt = 0
        while (true) {
            try {
                return gateway.ownsRunningExercise()
            } catch (error: CancellationException) {
                throw error
            } catch (error: Exception) {
                Log.w(TAG, "Could not read the current exercise", error)
            }
            if (attempt >= restoreBackoffMillis.size) return null
            delay(restoreBackoffMillis[attempt++])
        }
    }

    // MARK: - Exercise updates

    private val listener =
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
        }

    private fun registerCallback() {
        if (callbackRegistered) return
        gateway.setListener(listener)
        callbackRegistered = true
    }

    private fun unregisterCallback() {
        if (!callbackRegistered) return
        callbackRegistered = false
        scope.launch { runCatching { gateway.clearListener() } }
    }

    private fun handle(snapshot: ExerciseSnapshot) {
        val current = recording ?: return

        snapshot.heartRateBpm?.let { bpm ->
            snapshot.heartRateAtMillis?.let { lastHeartRate = bpm to it }
            mutableState.update { it.copy(heartRateBpm = bpm) }
        }
        snapshot.distanceTotalMeters?.let { total ->
            mutableState.update { it.copy(distanceMeters = total) }
        }
        snapshot.activeDurationMillis?.let { activeDurationMillis = it }

        if (!current.isPaused && snapshot.state == GatewayExerciseState.ACTIVE) {
            val newPoints =
                snapshot.locations.mapNotNull { fix ->
                    LocationSampleMapper.point(
                        timestampMillis = fix.timestampMillis,
                        latitude = fix.latitude,
                        longitude = fix.longitude,
                        altitude = fix.altitude,
                        bearing = fix.bearing,
                        horizontalErrorMeters = fix.horizontalErrorMeters,
                        verticalErrorMeters = fix.verticalErrorMeters,
                        segmentIndex = current.segmentIndex,
                        lastHeartRate = lastHeartRate,
                    )
                }.filter { it.timestampMillis >= current.startedAtMillis }
            points += newPoints
            unsavedPoints += newPoints
            if (unsavedPoints.size >= POINT_FLUSH_THRESHOLD) flushPoints()
        }

        val now = platform.nowMillis()
        when {
            snapshot.state == GatewayExerciseState.ENDED -> scope.launch { finish() }
            snapshot.state == GatewayExerciseState.PAUSED && !current.isPaused -> {
                flushPoints()
                setRecording(current.paused(now))
                mutableState.update { it.copy(phase = WorkoutPhase.Active(paused = true)) }
            }
            snapshot.state == GatewayExerciseState.ACTIVE && current.isPaused -> {
                setRecording(current.resumed(now))
                mutableState.update { it.copy(phase = WorkoutPhase.Active(paused = false)) }
            }
        }
    }

    // MARK: - Finishing

    private fun finish() {
        if (finishing) return
        val current = recording ?: return
        finishing = true
        flushPoints()
        unregisterCallback()
        platform.stopService()

        val end = platform.nowMillis()
        val elapsed = activeDurationMillis ?: current.elapsedMillis(end)
        val recorded = points.toList()
        enqueueHandoff(current, recorded, end, elapsed)
        val summary =
            WorkoutSummary(
                activityType = current.activityType,
                elapsedMillis = elapsed,
                distanceMeters = mutableState.value.distanceMeters,
                hasRoute = recorded.isNotEmpty(),
            )
        detach()
        mutableState.update { WorkoutUiState(phase = WorkoutPhase.Finished(summary)) }
        finishing = false
    }

    private fun finishInterrupted(
        saved: WatchRecording,
        savedPoints: List<WatchRecordedPoint>,
    ) {
        // A sticky restart may have put the service back in the foreground
        // for a workout that no longer runs: drop its notification.
        platform.stopService()
        val end = WatchHandoffBuilder.endOfInterruptedRecording(saved, savedPoints)
        val elapsed = saved.elapsedMillis(end)
        if (savedPoints.isEmpty() && elapsed < 1000) {
            store.clear()
            return
        }
        enqueueHandoff(saved, savedPoints, end, elapsed)
    }

    private fun enqueueHandoff(
        recording: WatchRecording,
        points: List<WatchRecordedPoint>,
        endedAtMillis: Long,
        elapsedMillis: Long,
    ) {
        try {
            val data = WatchHandoffBuilder.bytes(recording, points, endedAtMillis, elapsedMillis)
            handoffs.enqueue(data, recording.sessionId)
            store.clear()
        } catch (error: IOException) {
            // The recording stays on disk; the next launch finishes it again.
            Log.w(TAG, "Could not queue the workout", error)
            mutableState.update { it.copy(errorMessage = R.string.queue_failed) }
        }
    }

    // MARK: - State

    private fun attach(
        newRecording: WatchRecording,
        savedPoints: List<WatchRecordedPoint>,
    ) {
        recording = newRecording
        points.clear()
        points += savedPoints
        unsavedPoints.clear()
        lastHeartRate = null
        activeDurationMillis = null
        persistedDistance = newRecording.lastDistanceMeters
        mutableState.update {
            WorkoutUiState(
                phase = it.phase,
                activityType = newRecording.activityType,
                recording = newRecording,
                // Health Services only sends the total when it changes, so
                // keep the last one known instead of showing 0.
                distanceMeters = newRecording.lastDistanceMeters,
            )
        }
    }

    private fun detach() {
        recording = null
        points.clear()
        unsavedPoints.clear()
        lastHeartRate = null
        activeDurationMillis = null
        persistedDistance = null
    }

    private fun setRecording(updated: WatchRecording) {
        val withDistance = updated.copy(lastDistanceMeters = mutableState.value.distanceMeters)
        recording = withDistance
        persistedDistance = withDistance.lastDistanceMeters
        mutableState.update { it.copy(recording = withDistance) }
        try {
            store.update(withDistance)
        } catch (error: IOException) {
            Log.w(TAG, "Could not save the workout state", error)
        }
    }

    private fun flushPoints() {
        if (unsavedPoints.isEmpty()) return
        try {
            store.append(unsavedPoints.toList())
            unsavedPoints.clear()
            persistDistance()
        } catch (error: IOException) {
            // Kept in memory and retried with the next batch.
            Log.w(TAG, "Could not save workout points", error)
        }
    }

    /** Saves the distance with the points, so a crash keeps it as well. */
    private fun persistDistance() {
        val current = recording ?: return
        val distance = mutableState.value.distanceMeters
        if (distance == null || distance == persistedDistance) return
        val updated = current.copy(lastDistanceMeters = distance)
        try {
            store.update(updated)
            recording = updated
            persistedDistance = distance
        } catch (error: IOException) {
            Log.w(TAG, "Could not save the workout distance", error)
        }
    }

    private fun fail(@StringRes message: Int) {
        mutableState.update { WorkoutUiState(errorMessage = message) }
    }

    companion object {
        private const val TAG = "EndurainWear"
        private const val POINT_FLUSH_THRESHOLD = 10

        /** Waits between attempts to ask Health Services who owns the exercise at launch. */
        val RESTORE_BACKOFF_MILLIS = listOf(1_000L, 2_000L, 4_000L, 8_000L)
    }
}
