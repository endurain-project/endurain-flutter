package com.endurain.endurain.watchlink

import org.json.JSONArray
import org.json.JSONObject
import kotlin.math.roundToLong

/**
 * Builds the handoff envelope for a finished watch workout.
 *
 * The result is exactly what the Dart `WatchSessionHandoff.fromJson` reads:
 * the session in the shape of `ActiveActivitySession` and the points in the
 * shape of `RecordedActivityPoint`.
 */
object WatchHandoffBuilder {
    fun envelope(
        recording: WatchRecording,
        points: List<WatchRecordedPoint>,
        endedAtMillis: Long,
        elapsedMillis: Long,
        healthWorkoutId: String? = null,
    ): JSONObject {
        val session =
            JSONObject().apply {
                put("schemaVersion", WatchProtocol.SESSION_SCHEMA_VERSION)
                put("localSessionId", recording.sessionId)
                put("activityType", recording.activityType.apiValue)
                put("status", "completed")
                put("startedAt", WatchProtocol.timestamp(recording.startedAtMillis))
                put("endedAt", WatchProtocol.timestamp(maxOf(endedAtMillis, recording.startedAtMillis)))
                put("elapsedDurationSeconds", maxOf(0L, (elapsedMillis / 1000.0).roundToLong()))
                put("currentSegmentIndex", recording.segmentIndex)
                put("autoPauseEnabled", false)
                put("autoPauseDelaySeconds", 5)
                put("pausedAutomatically", false)
            }
        return JSONObject().apply {
            put("version", WatchProtocol.PAYLOAD_VERSION)
            put("source", WatchProtocol.SOURCE)
            put("session", session)
            put(
                "points",
                JSONArray().apply {
                    points.sortedBy { it.timestampMillis }.forEach { put(it.toJson()) }
                },
            )
            if (!healthWorkoutId.isNullOrEmpty()) {
                put("healthWorkoutId", healthWorkoutId)
            }
        }
    }

    fun bytes(
        recording: WatchRecording,
        points: List<WatchRecordedPoint>,
        endedAtMillis: Long,
        elapsedMillis: Long,
        healthWorkoutId: String? = null,
    ): ByteArray =
        envelope(recording, points, endedAtMillis, elapsedMillis, healthWorkoutId)
            .toString()
            .toByteArray(Charsets.UTF_8)

    /** When a recording that was cut short ended: its last point, or its start. */
    fun endOfInterruptedRecording(
        recording: WatchRecording,
        points: List<WatchRecordedPoint>,
    ): Long = maxOf(points.maxOfOrNull { it.timestampMillis } ?: recording.startedAtMillis, recording.startedAtMillis)
}
