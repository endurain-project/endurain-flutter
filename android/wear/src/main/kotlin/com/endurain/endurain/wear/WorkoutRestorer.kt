package com.endurain.endurain.wear

import android.util.Log
import com.endurain.endurain.watchlink.WatchRecordingStore
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

/**
 * Called at launch: re-attaches to an exercise Health Services kept running
 * while the process was dead, or finishes and sends a recording whose
 * exercise is gone.
 *
 * A failure to ask Health Services is not "the exercise is gone": it is
 * retried with backoff, and when it keeps failing the saved recording is
 * left untouched and a message offers another try ([retry]).
 *
 * A recording that cannot be read at all is cleared by
 * [WatchRecordingStore.load] itself, so it does not linger as a phantom
 * workout; the restore then simply ends idle.
 */
internal class WorkoutRestorer(
    private val session: WorkoutSession,
    private val store: WatchRecordingStore,
    private val gateway: ExerciseGateway,
    private val finisher: WorkoutFinisher,
    private val subscription: ExerciseSubscription,
    private val scope: CoroutineScope,
    private val backoffMillis: List<Long>,
) {
    /** Set while a restore could not tell whether the exercise still runs; dismissing its message retries. */
    var failed = false
        private set

    fun restore() {
        if (!store.hasRecording()) return
        // Blocks starting a new workout, which would overwrite the saved one,
        // while the recording loads off the main thread.
        session.state.update { it.copy(phase = WorkoutPhase.Starting) }
        scope.launch {
            val loaded = session.writer.submit { store.load() }
            if (loaded == null) {
                Log.w(TAG, "The saved workout could not be read")
                session.state.update { it.copy(phase = WorkoutPhase.Idle) }
                return@launch
            }
            val (saved, savedPoints) = loaded
            when (gateway.readOwnership(backoffMillis)) {
                null -> {
                    failed = true
                    session.state.update { WorkoutUiState(errorMessage = R.string.restore_failed) }
                }
                false -> {
                    finisher.finishInterrupted(saved, savedPoints)
                    session.state.update { WorkoutUiState(errorMessage = it.errorMessage) }
                }
                true -> {
                    session.attach(saved, savedPoints)
                    subscription.register()
                    session.updateServiceStatus()
                    session.state.update { it.copy(phase = WorkoutPhase.Active(paused = saved.isPaused)) }
                }
            }
        }
    }

    /** Tries again after a failed restore, once its message was dismissed. */
    fun retry() {
        if (!failed) return
        failed = false
        restore()
    }
}
