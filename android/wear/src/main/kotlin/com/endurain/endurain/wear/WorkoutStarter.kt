package com.endurain.endurain.wear

import android.util.Log
import com.endurain.endurain.watchlink.WatchActivityType
import com.endurain.endurain.watchlink.WatchRecording
import com.endurain.endurain.watchlink.WatchRecordingStore
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.util.UUID

/**
 * Starts a workout: checks what the watch can record, asks before taking
 * over another app's workout, runs the optional countdown and begins the
 * exercise.
 */
internal class WorkoutStarter(
    private val session: WorkoutSession,
    private val store: WatchRecordingStore,
    private val gateway: ExerciseGateway,
    private val platform: WorkoutPlatform,
    private val subscription: ExerciseSubscription,
    private val countdownSeconds: StateFlow<Int>,
    private val scope: CoroutineScope,
    countdownTickMillis: Long,
) {
    private val countdown =
        CountdownController(
            scope = scope,
            nowMillis = platform::nowMillis,
            onCue = platform::vibrateTick,
            onFinished = ::finishCountdown,
            tickMillis = countdownTickMillis,
        )

    private var pendingStart: Pair<WatchActivityType, Set<WorkoutMetric>>? = null

    /** Whether the start flow prepared or started an exercise that [failStart] must end. */
    private var exerciseNeedsEnding = false

    fun start(type: WatchActivityType) {
        session.state.update { it.copy(phase = WorkoutPhase.Starting, errorMessage = null) }
        exerciseNeedsEnding = false
        scope.launch {
            try {
                val supported = gateway.supportedMetrics(type)
                if (supported == null) {
                    session.fail(R.string.exercise_unsupported)
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

                if (gateway.otherAppHasExerciseOrFalse()) {
                    // Starting would end that workout: ask first.
                    pendingStart = type to metrics
                    session.state.update { it.copy(phase = WorkoutPhase.ConfirmingTakeover, activityType = type) }
                    return@launch
                }
                proceedStart(type, metrics)
            } catch (error: CancellationException) {
                throw error
            } catch (error: Exception) {
                failStart(error)
            }
        }
    }

    /** Starts the workout that [start] held back until the user agreed to end the other app's. */
    fun confirmTakeover() {
        if (session.state.value.phase != WorkoutPhase.ConfirmingTakeover) return
        val (type, metrics) = pendingStart ?: return
        pendingStart = null
        session.state.update { it.copy(phase = WorkoutPhase.Starting) }
        scope.launch {
            try {
                proceedStart(type, metrics)
            } catch (error: CancellationException) {
                throw error
            } catch (error: Exception) {
                failStart(error)
            }
        }
    }

    /** Backs out of starting while another app's workout runs. */
    fun cancelTakeover() {
        if (session.state.value.phase != WorkoutPhase.ConfirmingTakeover) return
        pendingStart = null
        session.state.update { WorkoutUiState() }
    }

    private suspend fun proceedStart(
        type: WatchActivityType,
        metrics: Set<WorkoutMetric>,
    ) {
        val seconds = countdownSeconds.value
        if (seconds > 0) {
            beginCountdown(type, metrics, seconds)
        } else {
            beginExercise(type, metrics)
        }
    }

    // MARK: - Countdown

    /** Starts the workout now instead of waiting for the countdown. */
    fun skipCountdown() {
        if (session.state.value.phase !is WorkoutPhase.CountingDown) return
        countdown.cancel()
        scope.launch { finishCountdown() }
    }

    /** Stops the countdown without recording anything. */
    fun cancelCountdown() {
        if (session.state.value.phase !is WorkoutPhase.CountingDown) return
        countdown.cancel()
        pendingStart = null
        session.state.update { WorkoutUiState() }
        platform.stopService()
        // Ends the prepared exercise so the sensors stop warming up.
        subscription.unregister()
        scope.launchLogged("end the prepared exercise") { gateway.end() }
    }

    private suspend fun beginCountdown(
        type: WatchActivityType,
        metrics: Set<WorkoutMetric>,
        seconds: Int,
    ) {
        // Registered first so the warm-up's GPS availability reaches the screen.
        subscription.register()
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
        session.state.update {
            it.copy(phase = WorkoutPhase.CountingDown(endsAt), activityType = type)
        }
        countdown.start(endsAt)
    }

    private suspend fun finishCountdown() {
        if (session.state.value.phase !is WorkoutPhase.CountingDown) return
        val (type, metrics) = pendingStart ?: return
        pendingStart = null
        session.state.update { it.copy(phase = WorkoutPhase.Starting) }
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
        session.writer.submit { store.begin(newRecording) }
        session.attach(newRecording, emptyList())
        subscription.register()
        gateway.start(type, metrics)
        exerciseNeedsEnding = true
        // After a countdown the service is already in the foreground; this
        // only switches its notification to "recording". Android can refuse
        // the call when the countdown ended with the app in the background,
        // which must not fail a workout Health Services is already recording.
        session.updateServiceStatus()
        exerciseNeedsEnding = false
        session.state.update { it.copy(phase = WorkoutPhase.Active(paused = false)) }
    }

    private fun failStart(error: Exception) {
        Log.w(TAG, "Could not start a workout", error)
        platform.stopService()
        session.writer.postClear()
        session.detach()
        subscription.unregister()
        if (exerciseNeedsEnding) {
            // Nothing records it any more: end the prepared or started
            // exercise so Health Services does not keep the sensors on.
            exerciseNeedsEnding = false
            scope.launchLogged("end the exercise") { gateway.end() }
        }
        session.fail(R.string.start_failed)
    }
}
