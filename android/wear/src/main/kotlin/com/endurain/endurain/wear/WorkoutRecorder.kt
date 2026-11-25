package com.endurain.endurain.wear

import android.annotation.SuppressLint
import android.content.Context
import android.os.Build
import android.os.SystemClock
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.util.Log
import androidx.annotation.StringRes
import androidx.health.services.client.ExerciseClient
import androidx.health.services.client.ExerciseUpdateCallback
import androidx.health.services.client.HealthServices
import androidx.health.services.client.data.Availability
import androidx.health.services.client.data.DataType
import androidx.health.services.client.data.DeltaDataType
import androidx.health.services.client.data.ExerciseConfig
import androidx.health.services.client.data.ExerciseLapSummary
import androidx.health.services.client.data.ExerciseState
import androidx.health.services.client.data.ExerciseTrackedStatus
import androidx.health.services.client.data.ExerciseType
import androidx.health.services.client.data.ExerciseUpdate
import androidx.health.services.client.data.LocationAccuracy
import androidx.health.services.client.data.LocationData
import androidx.health.services.client.data.WarmUpConfig
import com.endurain.endurain.watchlink.WatchActivityType
import com.endurain.endurain.watchlink.WatchHandoffBuilder
import com.endurain.endurain.watchlink.WatchRecordedPoint
import com.endurain.endurain.watchlink.WatchRecording
import com.endurain.endurain.watchlink.WatchRecordingStore
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.guava.await
import kotlinx.coroutines.launch
import java.io.File
import java.io.IOException
import java.time.Instant
import java.util.UUID
import kotlin.math.roundToInt

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
    @StringRes val errorMessage: Int? = null,
)

/**
 * Records one outdoor workout with Health Services and hands it to the phone.
 *
 * Health Services owns the exercise (GPS, heart rate, distance) and keeps it
 * running even if this process dies; [ExerciseService] keeps the process in
 * the foreground meanwhile. GPS fixes are written to a durable
 * [WatchRecordingStore] as they arrive, so a crash costs at most a few
 * seconds of track. On finish the session is turned into a handoff envelope
 * and queued in [PhoneLink]'s outbox.
 */
class WorkoutRecorder(
    context: Context,
    private val phoneLink: PhoneLink,
) {
    private val appContext = context.applicationContext
    private val exerciseClient: ExerciseClient by lazy { HealthServices.getClient(appContext).exerciseClient }
    private val store = WatchRecordingStore(File(appContext.noBackupFilesDir, "watch_recording"))
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)

    private val mutableState = MutableStateFlow(WorkoutUiState())
    val state: StateFlow<WorkoutUiState> = mutableState.asStateFlow()

    private val countdownSettings = StartCountdownSettings(appContext)
    private val mutableCountdownSeconds = MutableStateFlow(countdownSettings.seconds)

    /** Seconds counted down before a workout starts, saved on the watch. */
    val countdownSeconds: StateFlow<Int> = mutableCountdownSeconds.asStateFlow()

    private val vibrator: Vibrator? by lazy {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            appContext.getSystemService(VibratorManager::class.java)?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            appContext.getSystemService(Vibrator::class.java)
        }
    }

    private var pendingStart: Pair<WatchActivityType, ExerciseConfig>? = null
    private var countdownJob: Job? = null

    private var recording: WatchRecording? = null
    private val points = mutableListOf<WatchRecordedPoint>()
    private val unsavedPoints = mutableListOf<WatchRecordedPoint>()
    private var lastHeartRate: Pair<Int, Long>? = null
    private var activeDurationMillis: Long? = null
    private var callbackRegistered = false
    private var finishing = false

    fun start(type: WatchActivityType) {
        if (mutableState.value.phase != WorkoutPhase.Idle) return
        mutableState.update { it.copy(phase = WorkoutPhase.Starting, errorMessage = null) }
        scope.launch {
            try {
                val exerciseType = exerciseType(type)
                val capabilities = exerciseClient.getCapabilitiesAsync().await()
                if (exerciseType !in capabilities.supportedExerciseTypes) {
                    fail(R.string.exercise_unsupported)
                    return@launch
                }
                val supported = capabilities.getExerciseTypeCapabilities(exerciseType).supportedDataTypes
                val dataTypes =
                    setOf(DataType.HEART_RATE_BPM, DataType.LOCATION, DataType.DISTANCE_TOTAL)
                        .filter { it in supported }
                        .toSet()
                val config =
                    ExerciseConfig.builder(exerciseType)
                        .setDataTypes(dataTypes)
                        .setIsAutoPauseAndResumeEnabled(false)
                        .setIsGpsEnabled(DataType.LOCATION in dataTypes)
                        .build()

                val seconds = countdownSeconds.value
                if (seconds > 0) {
                    beginCountdown(type, exerciseType, dataTypes, config, seconds)
                    return@launch
                }
                beginExercise(type, config)
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
        countdownSettings.seconds = next
        mutableCountdownSeconds.value = next
    }

    /** Starts the workout now instead of waiting for the countdown. */
    fun skipCountdown() {
        if (mutableState.value.phase !is WorkoutPhase.CountingDown) return
        countdownJob?.cancel()
        countdownJob = null
        scope.launch { finishCountdown() }
    }

    /** Stops the countdown without recording anything. */
    fun cancelCountdown() {
        if (mutableState.value.phase !is WorkoutPhase.CountingDown) return
        countdownJob?.cancel()
        countdownJob = null
        pendingStart = null
        mutableState.update { WorkoutUiState() }
        ExerciseService.stop(appContext)
        // Ends the prepared exercise so the sensors stop warming up.
        scope.launch { runCatching { exerciseClient.endExerciseAsync().await() } }
    }

    // MARK: - Countdown

    private suspend fun beginCountdown(
        type: WatchActivityType,
        exerciseType: ExerciseType,
        dataTypes: Set<DataType<*, *>>,
        config: ExerciseConfig,
        seconds: Int,
    ) {
        val warmUpTypes = dataTypes.filterIsInstance<DeltaDataType<*, *>>().toSet()
        try {
            exerciseClient.prepareExerciseAsync(WarmUpConfig(exerciseType, warmUpTypes)).await()
        } catch (error: Exception) {
            // Only the warm-up is lost: the countdown and the workout still run.
            Log.w(TAG, "Could not prepare the exercise", error)
        }
        // Keeps the app alive while the wrist is down during the countdown.
        ExerciseService.start(appContext, countingDown = true)
        pendingStart = type to config
        val endsAt = System.currentTimeMillis() + seconds * 1000L
        mutableState.update {
            it.copy(phase = WorkoutPhase.CountingDown(endsAt), activityType = type)
        }
        countdownJob = scope.launch { runCountdown(endsAt) }
    }

    private suspend fun runCountdown(endsAtMillis: Long) {
        var lastCue: Int? = null
        while (true) {
            val seconds = StartCountdown.remainingSeconds(endsAtMillis, System.currentTimeMillis())
            if (seconds <= 0) break
            if (seconds <= StartCountdown.CUE_SECONDS && seconds != lastCue) {
                lastCue = seconds
                vibrate(VibrationEffect.createPredefined(VibrationEffect.EFFECT_TICK))
            }
            delay(COUNTDOWN_TICK_MILLIS)
        }
        countdownJob = null
        finishCountdown()
    }

    private suspend fun finishCountdown() {
        if (mutableState.value.phase !is WorkoutPhase.CountingDown) return
        val (type, config) = pendingStart ?: return
        pendingStart = null
        mutableState.update { it.copy(phase = WorkoutPhase.Starting) }
        try {
            beginExercise(type, config)
            vibrate(VibrationEffect.createOneShot(START_VIBRATION_MILLIS, VibrationEffect.DEFAULT_AMPLITUDE))
        } catch (error: Exception) {
            failStart(error)
        }
    }

    private fun vibrate(effect: VibrationEffect) {
        runCatching { vibrator?.vibrate(effect) }
    }

    // MARK: - Starting

    private suspend fun beginExercise(
        type: WatchActivityType,
        config: ExerciseConfig,
    ) {
        val newRecording = WatchRecording(UUID.randomUUID().toString(), type, System.currentTimeMillis())
        store.begin(newRecording)
        attach(newRecording, emptyList())
        registerCallback()
        exerciseClient.startExerciseAsync(config).await()
        ExerciseService.start(appContext)
        mutableState.update { it.copy(phase = WorkoutPhase.Active(paused = false)) }
    }

    private fun failStart(error: Exception) {
        Log.w(TAG, "Could not start a workout", error)
        ExerciseService.stop(appContext)
        store.clear()
        detach()
        fail(R.string.start_failed)
    }

    fun pause() {
        scope.launch { runCatching { exerciseClient.pauseExerciseAsync().await() } }
    }

    fun resume() {
        scope.launch { runCatching { exerciseClient.resumeExerciseAsync().await() } }
    }

    fun end() {
        val phase = mutableState.value.phase
        if (phase !is WorkoutPhase.Active) return
        mutableState.update { it.copy(phase = WorkoutPhase.Ending) }
        scope.launch {
            try {
                exerciseClient.endExerciseAsync().await()
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
    }

    /**
     * Called at launch: re-attaches to an exercise Health Services kept
     * running while the process was dead, or finishes and sends a recording
     * whose exercise is gone.
     */
    // The ExerciseTrackedStatus constants are public API; lint misreads the
    // library's restriction on their companion object.
    @SuppressLint("RestrictedApi")
    fun restoreUnfinishedRecording() {
        val (saved, savedPoints) = store.load() ?: return
        scope.launch {
            val owned =
                try {
                    exerciseClient.getCurrentExerciseInfoAsync().await().exerciseTrackedStatus ==
                        ExerciseTrackedStatus.OWNED_EXERCISE_IN_PROGRESS
                } catch (error: Exception) {
                    Log.w(TAG, "Could not read the current exercise", error)
                    false
                }
            if (!owned) {
                finishInterrupted(saved, savedPoints)
                return@launch
            }
            attach(saved, savedPoints)
            registerCallback()
            runCatching { ExerciseService.start(appContext) }
            mutableState.update { it.copy(phase = WorkoutPhase.Active(paused = saved.isPaused)) }
        }
    }

    // MARK: - Exercise updates

    private val callback =
        object : ExerciseUpdateCallback {
            override fun onExerciseUpdateReceived(update: ExerciseUpdate) {
                handle(update)
            }

            override fun onLapSummaryReceived(lapSummary: ExerciseLapSummary) {}

            override fun onRegistered() {}

            override fun onRegistrationFailed(throwable: Throwable) {
                Log.w(TAG, "Could not receive exercise updates", throwable)
            }

            override fun onAvailabilityChanged(dataType: DataType<*, *>, availability: Availability) {}
        }

    private fun registerCallback() {
        if (callbackRegistered) return
        exerciseClient.setUpdateCallback(callback)
        callbackRegistered = true
    }

    private fun unregisterCallback() {
        if (!callbackRegistered) return
        callbackRegistered = false
        scope.launch { runCatching { exerciseClient.clearUpdateCallbackAsync(callback).await() } }
    }

    private fun handle(update: ExerciseUpdate) {
        val current = recording ?: return
        val bootInstant = Instant.ofEpochMilli(System.currentTimeMillis() - SystemClock.elapsedRealtime())
        val metrics = update.latestMetrics

        metrics.getData(DataType.HEART_RATE_BPM).lastOrNull()?.let { sample ->
            val bpm = sample.value.roundToInt()
            lastHeartRate = bpm to sample.getTimeInstant(bootInstant).toEpochMilli()
            mutableState.update { it.copy(heartRateBpm = bpm) }
        }
        metrics.getData(DataType.DISTANCE_TOTAL)?.let { total ->
            mutableState.update { it.copy(distanceMeters = total.total) }
        }
        update.activeDurationCheckpoint?.let { activeDurationMillis = it.activeDuration.toMillis() }

        val state = update.exerciseStateInfo.state
        if (!current.isPaused && state == ExerciseState.ACTIVE) {
            val newPoints =
                metrics.getData(DataType.LOCATION).mapNotNull { sample ->
                    val location: LocationData = sample.value
                    val accuracy = sample.accuracy as? LocationAccuracy
                    LocationSampleMapper.point(
                        timestampMillis = sample.getTimeInstant(bootInstant).toEpochMilli(),
                        latitude = location.latitude,
                        longitude = location.longitude,
                        // Unavailable values are NaN, which the mapper drops.
                        altitude = location.altitude,
                        bearing = location.bearing,
                        horizontalErrorMeters = accuracy?.horizontalPositionErrorMeters,
                        verticalErrorMeters = accuracy?.verticalPositionErrorMeters,
                        segmentIndex = current.segmentIndex,
                        lastHeartRate = lastHeartRate,
                    )
                }.filter { it.timestampMillis >= current.startedAtMillis }
            points += newPoints
            unsavedPoints += newPoints
            if (unsavedPoints.size >= POINT_FLUSH_THRESHOLD) flushPoints()
        }

        val now = System.currentTimeMillis()
        when {
            state.isEnded -> scope.launch { finish() }
            state.isPaused && !current.isPaused -> {
                flushPoints()
                setRecording(current.paused(now))
                mutableState.update { it.copy(phase = WorkoutPhase.Active(paused = true)) }
            }
            state == ExerciseState.ACTIVE && current.isPaused -> {
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
        ExerciseService.stop(appContext)

        val end = System.currentTimeMillis()
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

    private fun finishInterrupted(saved: WatchRecording, savedPoints: List<WatchRecordedPoint>) {
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
            phoneLink.enqueue(data, recording.sessionId)
            store.clear()
        } catch (error: IOException) {
            // The recording stays on disk; the next launch finishes it again.
            Log.w(TAG, "Could not queue the workout", error)
            mutableState.update { it.copy(errorMessage = R.string.queue_failed) }
        }
    }

    // MARK: - State

    private fun attach(newRecording: WatchRecording, savedPoints: List<WatchRecordedPoint>) {
        recording = newRecording
        points.clear()
        points += savedPoints
        unsavedPoints.clear()
        lastHeartRate = null
        activeDurationMillis = null
        mutableState.update {
            WorkoutUiState(
                phase = it.phase,
                activityType = newRecording.activityType,
                recording = newRecording,
            )
        }
    }

    private fun detach() {
        recording = null
        points.clear()
        unsavedPoints.clear()
        lastHeartRate = null
        activeDurationMillis = null
    }

    private fun setRecording(updated: WatchRecording) {
        recording = updated
        mutableState.update { it.copy(recording = updated) }
        try {
            store.update(updated)
        } catch (error: IOException) {
            Log.w(TAG, "Could not save the workout state", error)
        }
    }

    private fun flushPoints() {
        if (unsavedPoints.isEmpty()) return
        try {
            store.append(unsavedPoints.toList())
            unsavedPoints.clear()
        } catch (error: IOException) {
            // Kept in memory and retried with the next batch.
            Log.w(TAG, "Could not save workout points", error)
        }
    }

    private fun fail(@StringRes message: Int) {
        mutableState.update { WorkoutUiState(errorMessage = message) }
    }

    companion object {
        private const val TAG = "EndurainWear"
        private const val POINT_FLUSH_THRESHOLD = 10
        private const val COUNTDOWN_TICK_MILLIS = 200L
        private const val START_VIBRATION_MILLIS = 400L

        fun exerciseType(type: WatchActivityType): ExerciseType =
            when (type) {
                WatchActivityType.RUN -> ExerciseType.RUNNING
                WatchActivityType.RIDE -> ExerciseType.BIKING
                WatchActivityType.WALK -> ExerciseType.WALKING
                WatchActivityType.HIKE -> ExerciseType.HIKING
            }
    }
}
