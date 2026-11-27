package com.endurain.endurain.wear

import android.util.Log
import com.endurain.endurain.watchlink.WatchHandoffBuilder
import com.endurain.endurain.watchlink.WatchRecordedPoint
import com.endurain.endurain.watchlink.WatchRecording
import com.endurain.endurain.watchlink.WatchRecordingStore
import java.io.IOException

/** Turns a recorded workout into a handoff envelope and queues it for the phone. */
internal class WorkoutHandoff(
    private val store: WatchRecordingStore,
    private val handoffs: HandoffSink,
) {
    /** Queues the workout and clears its saved recording; false when it could not be queued. */
    fun enqueue(
        recording: WatchRecording,
        points: List<WatchRecordedPoint>,
        endedAtMillis: Long,
        elapsedMillis: Long,
    ): Boolean =
        try {
            val data = WatchHandoffBuilder.bytes(recording, points, endedAtMillis, elapsedMillis)
            handoffs.enqueue(data, recording.sessionId)
            store.clear()
            true
        } catch (error: IOException) {
            // The recording stays on disk; the next launch finishes it again.
            Log.w(TAG, "Could not queue the workout", error)
            false
        }

    /** Queues a recording whose exercise is gone; false when it could not be queued. */
    fun enqueueInterrupted(
        saved: WatchRecording,
        savedPoints: List<WatchRecordedPoint>,
    ): Boolean {
        val end = WatchHandoffBuilder.endOfInterruptedRecording(saved, savedPoints)
        val elapsed = saved.elapsedMillis(end)
        if (savedPoints.isEmpty() && elapsed < 1000) {
            store.clear()
            return true
        }
        return enqueue(saved, savedPoints, end, elapsed)
    }
}
