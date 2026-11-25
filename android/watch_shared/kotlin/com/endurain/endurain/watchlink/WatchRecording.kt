package com.endurain.endurain.watchlink

import org.json.JSONException
import org.json.JSONObject
import java.io.File
import java.io.IOException

/** Activity types the watch can record, by their Endurain API value. */
enum class WatchActivityType(val apiValue: String) {
    RUN("run"),
    RIDE("ride"),
    WALK("walk"),
    HIKE("hike"),
    ;

    companion object {
        fun fromApiValue(value: String?): WatchActivityType? = entries.firstOrNull { it.apiValue == value }
    }
}

/**
 * Timing state of a workout being recorded on the watch.
 *
 * Persisted on every pause and resume, so a session interrupted by a crash
 * can still be finished with the right duration. Each resume starts a new
 * segment, matching the phone recorders, so a pause shows as a track break.
 */
data class WatchRecording(
    val sessionId: String,
    val activityType: WatchActivityType,
    val startedAtMillis: Long,
    val segmentIndex: Int = 0,
    /** Active time accumulated before the current run of the clock. */
    val activeMillisBeforeCurrentRun: Long = 0,
    /** When the clock last started; null while paused. */
    val currentRunStartedAtMillis: Long? = startedAtMillis,
) {
    val isPaused: Boolean
        get() = currentRunStartedAtMillis == null

    /** Active (unpaused) milliseconds as of [nowMillis]. */
    fun elapsedMillis(nowMillis: Long): Long {
        val runStart = currentRunStartedAtMillis ?: return activeMillisBeforeCurrentRun
        return activeMillisBeforeCurrentRun + maxOf(0L, nowMillis - runStart)
    }

    fun paused(atMillis: Long): WatchRecording =
        if (isPaused) {
            this
        } else {
            copy(activeMillisBeforeCurrentRun = elapsedMillis(atMillis), currentRunStartedAtMillis = null)
        }

    fun resumed(atMillis: Long): WatchRecording =
        if (!isPaused) this else copy(currentRunStartedAtMillis = atMillis, segmentIndex = segmentIndex + 1)

    fun toJson(): JSONObject =
        JSONObject().apply {
            put("sessionId", sessionId)
            put("activityType", activityType.apiValue)
            put("startedAt", startedAtMillis)
            put("segmentIndex", segmentIndex)
            put("activeMillisBeforeCurrentRun", activeMillisBeforeCurrentRun)
            currentRunStartedAtMillis?.let { put("currentRunStartedAt", it) }
        }

    companion object {
        fun fromJson(json: JSONObject): WatchRecording? {
            val sessionId = json.optString("sessionId", "")
            val type = WatchActivityType.fromApiValue(json.optString("activityType", ""))
            if (sessionId.isEmpty() || type == null || !json.has("startedAt")) return null
            return WatchRecording(
                sessionId = sessionId,
                activityType = type,
                startedAtMillis = json.optLong("startedAt"),
                segmentIndex = json.optInt("segmentIndex", 0),
                activeMillisBeforeCurrentRun = json.optLong("activeMillisBeforeCurrentRun", 0),
                currentRunStartedAtMillis =
                    if (json.has("currentRunStartedAt")) json.optLong("currentRunStartedAt") else null,
            )
        }
    }
}

/**
 * One GPS fix recorded on the watch.
 *
 * Serializes with the short keys of the Dart `RecordedActivityPoint`, so the
 * phone can hand the points to Dart unchanged.
 */
data class WatchRecordedPoint(
    val timestampMillis: Long,
    val latitude: Double,
    val longitude: Double,
    val segmentIndex: Int,
    val elevationMeters: Double? = null,
    val horizontalAccuracyMeters: Double? = null,
    val verticalAccuracyMeters: Double? = null,
    val headingDegrees: Double? = null,
    val speedMetersPerSecond: Double? = null,
    val heartRateBpm: Int? = null,
) {
    fun toJson(): JSONObject =
        JSONObject().apply {
            put("t", WatchProtocol.timestamp(timestampMillis))
            put("lat", latitude)
            put("lon", longitude)
            put("seg", segmentIndex)
            elevationMeters?.let { put("ele", it) }
            horizontalAccuracyMeters?.let { put("hAcc", it) }
            verticalAccuracyMeters?.let { put("vAcc", it) }
            headingDegrees?.let { put("head", it) }
            speedMetersPerSecond?.let { put("spd", it) }
            heartRateBpm?.let { put("hr", it) }
        }

    companion object {
        fun fromJson(json: JSONObject): WatchRecordedPoint? {
            val time = WatchProtocol.parseTimestamp(json.optString("t", "")) ?: return null
            val latitude = json.finiteDouble("lat") ?: return null
            val longitude = json.finiteDouble("lon") ?: return null
            if (latitude !in -90.0..90.0 || longitude !in -180.0..180.0) return null
            return WatchRecordedPoint(
                timestampMillis = time,
                latitude = latitude,
                longitude = longitude,
                segmentIndex = json.optInt("seg", 0),
                elevationMeters = json.finiteDouble("ele"),
                horizontalAccuracyMeters = json.finiteDouble("hAcc"),
                verticalAccuracyMeters = json.finiteDouble("vAcc"),
                headingDegrees = json.finiteDouble("head"),
                speedMetersPerSecond = json.finiteDouble("spd"),
                heartRateBpm = if (json.has("hr")) json.optInt("hr") else null,
            )
        }

        private fun JSONObject.finiteDouble(key: String): Double? {
            if (!has(key)) return null
            val value = optDouble(key, Double.NaN)
            return value.takeIf { it.isFinite() }
        }
    }
}

/**
 * Durable copy of the workout being recorded on the watch: the timing state
 * in `recording.json` and the points appended to `points.jsonl`.
 *
 * Lets a workout interrupted by a crash or a killed process be resumed, or
 * at least finished and sent, instead of being lost.
 */
class WatchRecordingStore(val directory: File) {
    private val recordingFile = File(directory, "recording.json")
    private val pointsFile = File(directory, "points.jsonl")

    /** Starts a new recording, discarding any previous one. */
    @Throws(IOException::class)
    fun begin(recording: WatchRecording) {
        clear()
        if (!directory.mkdirs() && !directory.isDirectory) {
            throw IOException("Could not create ${directory.name}")
        }
        update(recording)
        pointsFile.writeBytes(ByteArray(0))
    }

    @Throws(IOException::class)
    fun update(recording: WatchRecording) {
        val temporary = File(directory, "recording.json.tmp")
        temporary.writeText(recording.toJson().toString())
        if (!temporary.renameTo(recordingFile)) {
            throw IOException("Could not save the recording state")
        }
    }

    @Throws(IOException::class)
    fun append(points: List<WatchRecordedPoint>) {
        if (points.isEmpty()) return
        val lines = points.joinToString(separator = "") { it.toJson().toString() + "\n" }
        pointsFile.appendText(lines)
    }

    /** Whether an unfinished recording is on disk, without reading its points. */
    fun hasRecording(): Boolean = recordingFile.isFile

    /** The unfinished recording and its points, or null when there is none. */
    fun load(): Pair<WatchRecording, List<WatchRecordedPoint>>? {
        val recording =
            try {
                WatchRecording.fromJson(JSONObject(recordingFile.readText()))
            } catch (_: IOException) {
                null
            } catch (_: JSONException) {
                null
            } ?: return null
        val points =
            try {
                pointsFile.readLines()
            } catch (_: IOException) {
                emptyList()
            }.mapNotNull { line ->
                // A line cut short by a crash is skipped.
                if (line.isBlank()) return@mapNotNull null
                try {
                    WatchRecordedPoint.fromJson(JSONObject(line))
                } catch (_: JSONException) {
                    null
                }
            }
        return recording to points
    }

    fun clear() {
        directory.deleteRecursively()
    }
}
