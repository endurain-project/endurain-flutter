package com.endurain.endurain.wear

import android.util.Log
import com.endurain.endurain.watchlink.WatchRecordedPoint
import com.endurain.endurain.watchlink.WatchRecording
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

/**
 * Ends the workout and turns it into a handoff for the phone: the user's
 * end request, the timeout when Health Services never reports it, and the
 * hand-off of a recording whose exercise is gone.
 */
internal class WorkoutFinisher(
    private val session: WorkoutSession,
    private val gateway: ExerciseGateway,
    private val handoff: WorkoutHandoff,
    private val platform: WorkoutPlatform,
    private val subscription: ExerciseSubscription,
    private val scope: CoroutineScope,
    private val endTimeoutMillis: Long,
) {
    /** Finishes with what was recorded when Health Services never reports the end. */
    private var endTimeout: Job? = null

    fun end() {
        if (session.state.value.phase !is WorkoutPhase.Active) return
        session.state.update { it.copy(phase = WorkoutPhase.Ending) }
        scope.launch {
            try {
                gateway.end()
                // Normally the ENDED update has finished the workout by now. If it
                // never comes (the callback failed to register), do not wait forever.
                if (session.state.value.phase == WorkoutPhase.Ending) scheduleEndTimeout()
            } catch (error: CancellationException) {
                throw error
            } catch (error: Exception) {
                // The exercise is gone already: finish with what was recorded.
                Log.w(TAG, "Could not end the exercise", error)
                finish()
            }
        }
    }

    private fun scheduleEndTimeout() {
        endTimeout?.cancel()
        endTimeout =
            scope.launch {
                delay(endTimeoutMillis)
                // finish() cancels the pending timeout; this job must not cancel itself.
                endTimeout = null
                if (session.state.value.phase == WorkoutPhase.Ending) {
                    Log.w(TAG, "The exercise end was never reported")
                    finish()
                }
            }
    }

    /**
     * Saves the last points, queues the handoff and clears the saved
     * recording, all off the main thread; the screen shows "ending" meanwhile.
     * The recording is detached first, so a second call (or a late update)
     * finds nothing to finish.
     */
    suspend fun finish() {
        val current = session.recording ?: return
        endTimeout?.cancel()
        endTimeout = null
        val unsaved = session.track.drainUnsaved()
        subscription.unregister()
        platform.stopService()

        val end = platform.nowMillis()
        val elapsed = session.activeDurationMillis ?: current.elapsedMillis(end)
        val recorded = session.track.points()
        val distance = session.state.value.distanceMeters
        session.detach()
        session.state.update { it.copy(phase = WorkoutPhase.Ending) }

        val queued =
            try {
                session.writer.submit {
                    session.writer.appendInOrder(unsaved)
                    handoff.enqueue(current, recorded, end, elapsed)
                }
            } catch (error: CancellationException) {
                throw error
            } catch (error: Exception) {
                Log.w(TAG, "Could not queue the workout", error)
                false
            }
        val summary =
            WorkoutSummary(
                activityType = current.activityType,
                elapsedMillis = elapsed,
                distanceMeters = distance,
                hasRoute = recorded.isNotEmpty(),
            )
        session.state.update {
            WorkoutUiState(
                phase = WorkoutPhase.Finished(summary),
                errorMessage = if (queued) null else R.string.queue_failed,
            )
        }
    }

    /** Queues a saved recording whose exercise is gone. */
    suspend fun finishInterrupted(
        saved: WatchRecording,
        savedPoints: List<WatchRecordedPoint>,
    ) {
        // A sticky restart may have put the service back in the foreground
        // for a workout that no longer runs: drop its notification.
        platform.stopService()
        val queued =
            try {
                session.writer.submit { handoff.enqueueInterrupted(saved, savedPoints) }
            } catch (error: CancellationException) {
                throw error
            } catch (error: Exception) {
                Log.w(TAG, "Could not queue the interrupted workout", error)
                false
            }
        if (!queued) session.queueFailed()
    }
}
