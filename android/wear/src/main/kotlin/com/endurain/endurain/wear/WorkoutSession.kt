package com.endurain.endurain.wear

import android.util.Log
import androidx.annotation.StringRes
import com.endurain.endurain.watchlink.WatchRecordedPoint
import com.endurain.endurain.watchlink.WatchRecording
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.update

/**
 * The state of the workout being recorded, shared by the recorder's
 * collaborators ([WorkoutStarter], [WorkoutFinisher], [WorkoutRestorer]):
 * the UI state, the timing [recording] and the GPS [track].
 *
 * Everything here is touched from the main thread only; the disk is reached
 * through the [writer], which performs the I/O on its own dispatcher and in
 * the order requested.
 */
internal class WorkoutSession(
    private val platform: WorkoutPlatform,
    val writer: RecordingWriter,
) {
    val state = MutableStateFlow(WorkoutUiState())
    val track = WorkoutTrack()

    var recording: WatchRecording? = null
        private set
    var activeDurationMillis: Long? = null

    /** The distance last handed to the writer, so an unchanged one is not saved again. */
    private var persistedDistance: Double? = null

    /** Makes [newRecording], with its already saved [savedPoints], the workout being recorded. */
    fun attach(
        newRecording: WatchRecording,
        savedPoints: List<WatchRecordedPoint>,
    ) {
        recording = newRecording
        track.reset(savedPoints)
        activeDurationMillis = null
        persistedDistance = newRecording.lastDistanceMeters
        state.update {
            WorkoutUiState(
                phase = it.phase,
                activityType = newRecording.activityType,
                // The warm-up may already have reported the sensors' availability.
                locationStatus = it.locationStatus,
                heartRateStatus = it.heartRateStatus,
                recording = newRecording,
                // Health Services only sends the total when it changes, so
                // keep the last one known instead of showing 0.
                distanceMeters = newRecording.lastDistanceMeters,
            )
        }
    }

    fun detach() {
        recording = null
        track.reset()
        activeDurationMillis = null
        persistedDistance = null
    }

    /** Replaces the timing state (a pause or resume) and saves it. */
    fun setRecording(updated: WatchRecording) {
        val withDistance = updated.copy(lastDistanceMeters = state.value.distanceMeters)
        recording = withDistance
        persistedDistance = withDistance.lastDistanceMeters
        state.update { it.copy(recording = withDistance) }
        writer.postRecording(withDistance)
    }

    /**
     * Hands the unsaved points to the writer, with the distance when it
     * changed so a crash keeps it as well.
     */
    fun flushPoints() {
        val batch = track.drainUnsaved()
        if (batch.isEmpty()) return
        val current = recording
        val distance = state.value.distanceMeters
        var updated: WatchRecording? = null
        if (current != null && distance != null && distance != persistedDistance) {
            updated = current.copy(lastDistanceMeters = distance)
            recording = updated
            persistedDistance = distance
        }
        writer.postPoints(batch, updated)
    }

    /** Shows the active time and paused state in the ongoing activity. */
    fun updateServiceStatus() {
        val current = recording ?: return
        try {
            platform.startService(
                activeMillis = current.elapsedMillis(platform.nowMillis()),
                paused = current.isPaused,
            )
        } catch (error: Exception) {
            // Android can refuse this from the background; the workout goes on.
            Log.w(TAG, "Could not update the workout foreground service", error)
        }
    }

    fun queueFailed() {
        state.update { it.copy(errorMessage = R.string.queue_failed) }
    }

    fun fail(@StringRes message: Int) {
        state.update { WorkoutUiState(errorMessage = message) }
    }
}
