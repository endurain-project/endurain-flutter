package com.endurain.endurain.wear

import com.endurain.endurain.watchlink.WatchRecordedPoint
import com.endurain.endurain.watchlink.WatchRecording

/**
 * The GPS track of the workout being recorded: the points received so far,
 * and those not yet handed to the [RecordingWriter] for the durable store.
 * Only used from the main thread.
 */
internal class WorkoutTrack {
    private val points = mutableListOf<WatchRecordedPoint>()
    private val unsavedPoints = mutableListOf<WatchRecordedPoint>()
    private var lastHeartRate: Pair<Int, Long>? = null

    /** Starts over with the [saved] points, or an empty track. */
    fun reset(saved: List<WatchRecordedPoint> = emptyList()) {
        points.clear()
        points += saved
        unsavedPoints.clear()
        lastHeartRate = null
    }

    fun points(): List<WatchRecordedPoint> = points.toList()

    /** The heart rate attached to the points that follow. */
    fun noteHeartRate(
        bpm: Int,
        atMillis: Long,
    ) {
        lastHeartRate = bpm to atMillis
    }

    /** Adds the usable [fixes] of [recording]; true when enough are unsaved to [drainUnsaved]. */
    fun add(
        fixes: List<GatewayLocation>,
        recording: WatchRecording,
    ): Boolean {
        val newPoints =
            fixes.mapNotNull { fix ->
                LocationSampleMapper.point(
                    timestampMillis = fix.timestampMillis,
                    latitude = fix.latitude,
                    longitude = fix.longitude,
                    altitude = fix.altitude,
                    bearing = fix.bearing,
                    horizontalErrorMeters = fix.horizontalErrorMeters,
                    verticalErrorMeters = fix.verticalErrorMeters,
                    segmentIndex = recording.segmentIndex,
                    lastHeartRate = lastHeartRate,
                )
            }.filter { it.timestampMillis >= recording.startedAtMillis }
        points += newPoints
        unsavedPoints += newPoints
        return unsavedPoints.size >= POINT_FLUSH_THRESHOLD
    }

    /** Takes the points not yet handed to the writer, leaving none unsaved. */
    fun drainUnsaved(): List<WatchRecordedPoint> {
        val batch = unsavedPoints.toList()
        unsavedPoints.clear()
        return batch
    }

    private companion object {
        const val POINT_FLUSH_THRESHOLD = 10
    }
}
