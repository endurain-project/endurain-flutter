package com.endurain.endurain.wear

import androidx.annotation.StringRes
import com.endurain.endurain.watchlink.WatchActivityType
import com.endurain.endurain.watchlink.WatchRecording
import java.io.IOException

sealed interface WorkoutPhase {
    data object Idle : WorkoutPhase

    data object Starting : WorkoutPhase

    /**
     * Another app is recording a workout, which starting ours ends. Waits for
     * the user to confirm ([WorkoutRecorder.confirmTakeover]) or back out.
     */
    data object ConfirmingTakeover : WorkoutPhase

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
