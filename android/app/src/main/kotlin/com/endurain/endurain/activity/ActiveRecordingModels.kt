package com.endurain.endurain.activity

import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import org.json.JSONObject

/**
 * Native mirror of the Dart `ActiveActivitySession` model.
 *
 * The JSON schema must stay byte-compatible with
 * `lib/features/activity/models/active_activity_session.dart` so the Dart side
 * can recover sessions written by either recorder. Status values mirror the
 * Dart `ActiveActivityStatus` enum names.
 */
data class ActiveActivitySessionData(
    val localSessionId: String,
    val activityType: String,
    val status: String,
    val startedAt: String,
    val connectionOrigin: String? = null,
    val connectionProfileId: String? = null,
    val heartRateDeviceId: String? = null,
    val resumedAt: String? = null,
    val pausedAt: String? = null,
    val endedAt: String? = null,
    val elapsedDurationSeconds: Int = 0,
    val currentSegmentIndex: Int = 0,
    val schemaVersion: Int = SCHEMA_VERSION,
) {
    val isActive: Boolean
        get() = status == STATUS_RECORDING || status == STATUS_PAUSED

    fun toJson(): JSONObject {
        return JSONObject().apply {
            put("schemaVersion", schemaVersion)
            put("localSessionId", localSessionId)
            put("activityType", activityType)
            put("status", status)
            put("startedAt", startedAt)
            connectionOrigin?.let { put("connectionOrigin", it) }
            connectionProfileId?.let { put("connectionProfileId", it) }
            heartRateDeviceId?.let { put("hrDeviceId", it) }
            resumedAt?.let { put("resumedAt", it) }
            pausedAt?.let { put("pausedAt", it) }
            endedAt?.let { put("endedAt", it) }
            put("elapsedDurationSeconds", elapsedDurationSeconds)
            put("currentSegmentIndex", currentSegmentIndex)
        }
    }

    /** Builds a channel-safe map using the same keys the Dart model expects. */
    fun toMap(): Map<String, Any?> {
        val map = LinkedHashMap<String, Any?>()
        map["schemaVersion"] = schemaVersion
        map["localSessionId"] = localSessionId
        map["activityType"] = activityType
        map["status"] = status
        map["startedAt"] = startedAt
        connectionOrigin?.let { map["connectionOrigin"] = it }
        connectionProfileId?.let { map["connectionProfileId"] = it }
        heartRateDeviceId?.let { map["hrDeviceId"] = it }
        resumedAt?.let { map["resumedAt"] = it }
        pausedAt?.let { map["pausedAt"] = it }
        endedAt?.let { map["endedAt"] = it }
        map["elapsedDurationSeconds"] = elapsedDurationSeconds
        map["currentSegmentIndex"] = currentSegmentIndex
        return map
    }

    companion object {
        const val SCHEMA_VERSION = 2

        const val STATUS_RECORDING = "recording"
        const val STATUS_PAUSED = "paused"
        const val STATUS_STOPPING = "stopping"
        const val STATUS_COMPLETED = "completed"
        const val STATUS_FAILED = "failed"

        fun fromJson(json: JSONObject): ActiveActivitySessionData? {
            val localSessionId = json.optString("localSessionId", "")
            val startedAt = json.optString("startedAt", "")
            if (localSessionId.isEmpty() || startedAt.isEmpty()) {
                return null
            }
            return ActiveActivitySessionData(
                localSessionId = localSessionId,
                activityType = json.optString("activityType", ""),
                status = json.optString("status", STATUS_FAILED),
                startedAt = startedAt,
                connectionOrigin = json.optStringOrNull("connectionOrigin"),
                connectionProfileId = json.optStringOrNull("connectionProfileId"),
                heartRateDeviceId = json.optStringOrNull("hrDeviceId"),
                resumedAt = json.optStringOrNull("resumedAt"),
                pausedAt = json.optStringOrNull("pausedAt"),
                endedAt = json.optStringOrNull("endedAt"),
                elapsedDurationSeconds = json.optInt("elapsedDurationSeconds", 0),
                currentSegmentIndex = json.optInt("currentSegmentIndex", 0),
                schemaVersion = json.optInt("schemaVersion", SCHEMA_VERSION),
            )
        }
    }
}

/**
 * Native mirror of the Dart `RecordedActivityPoint` model.
 *
 * Uses the same short JSON keys (`t`, `lat`, `lon`, `seg`, ...) so points
 * written here can be drained directly by the Dart channel parser.
 */
data class RecordedActivityPointData(
    val timestamp: String,
    val latitude: Double,
    val longitude: Double,
    val segmentIndex: Int,
    val elevationMeters: Double? = null,
    val horizontalAccuracyMeters: Double? = null,
    val verticalAccuracyMeters: Double? = null,
    val headingDegrees: Double? = null,
    val headingAccuracyDegrees: Double? = null,
    val speedMetersPerSecond: Double? = null,
    val speedAccuracyMetersPerSecond: Double? = null,
    val heartRateBpm: Int? = null,
) {
    fun toJson(): JSONObject {
        return JSONObject().apply {
            put("t", timestamp)
            put("lat", latitude)
            put("lon", longitude)
            put("seg", segmentIndex)
            elevationMeters?.let { put("ele", it) }
            horizontalAccuracyMeters?.let { put("hAcc", it) }
            verticalAccuracyMeters?.let { put("vAcc", it) }
            headingDegrees?.let { put("head", it) }
            headingAccuracyDegrees?.let { put("headAcc", it) }
            speedMetersPerSecond?.let { put("spd", it) }
            speedAccuracyMetersPerSecond?.let { put("spdAcc", it) }
            heartRateBpm?.let { put("hr", it) }
        }
    }

    /** Single JSON line for append-only `points.jsonl` storage. */
    fun toJsonLine(): String = toJson().toString()

    /** Channel-safe map using the same keys the Dart parser expects. */
    fun toMap(): Map<String, Any?> {
        val map = LinkedHashMap<String, Any?>()
        map["t"] = timestamp
        map["lat"] = latitude
        map["lon"] = longitude
        map["seg"] = segmentIndex
        elevationMeters?.let { map["ele"] = it }
        horizontalAccuracyMeters?.let { map["hAcc"] = it }
        verticalAccuracyMeters?.let { map["vAcc"] = it }
        headingDegrees?.let { map["head"] = it }
        headingAccuracyDegrees?.let { map["headAcc"] = it }
        speedMetersPerSecond?.let { map["spd"] = it }
        speedAccuracyMetersPerSecond?.let { map["spdAcc"] = it }
        heartRateBpm?.let { map["hr"] = it }
        return map
    }

    companion object {
        fun fromJson(json: JSONObject): RecordedActivityPointData? {
            val timestamp = json.optStringOrNull("t") ?: return null
            if (!json.has("lat") || !json.has("lon")) {
                return null
            }
            val latitude = json.optDouble("lat", Double.NaN)
            val longitude = json.optDouble("lon", Double.NaN)
            if (latitude.isNaN() || longitude.isNaN()) {
                return null
            }
            if (latitude < -90 || latitude > 90 ||
                longitude < -180 || longitude > 180
            ) {
                return null
            }
            return RecordedActivityPointData(
                timestamp = timestamp,
                latitude = latitude,
                longitude = longitude,
                segmentIndex = json.optInt("seg", 0),
                elevationMeters = json.optDoubleOrNull("ele"),
                horizontalAccuracyMeters = json.optDoubleOrNull("hAcc"),
                verticalAccuracyMeters = json.optDoubleOrNull("vAcc"),
                headingDegrees = json.optDoubleOrNull("head"),
                headingAccuracyDegrees = json.optDoubleOrNull("headAcc"),
                speedMetersPerSecond = json.optDoubleOrNull("spd"),
                speedAccuracyMetersPerSecond = json.optDoubleOrNull("spdAcc"),
                heartRateBpm = json.optIntOrNull("hr"),
            )
        }

        /**
         * Parses a single stored JSONL line, returning `null` for blank or
         * malformed lines so a single corrupt entry never aborts recovery.
         */
        fun tryParseLine(line: String): RecordedActivityPointData? {
            val trimmed = line.trim()
            if (trimmed.isEmpty()) {
                return null
            }
            return try {
                fromJson(JSONObject(trimmed))
            } catch (_: Exception) {
                null
            }
        }
    }
}

/** UTC ISO-8601 helpers compatible with Dart `DateTime.toIso8601String()`. */
object IsoTime {
    fun nowUtc(): String = format(Date())

    fun format(date: Date): String {
        val formatter = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US)
        formatter.timeZone = TimeZone.getTimeZone("UTC")
        return formatter.format(date)
    }

    /**
     * Parses an ISO-8601 UTC timestamp to epoch millis at second precision.
     *
     * The Dart side always emits `...Z` UTC strings, so fractional seconds and
     * the trailing `Z` are stripped before parsing. Returns `null` on any
     * malformed input.
     */
    fun toEpochMillis(iso: String?): Long? {
        if (iso.isNullOrEmpty()) {
            return null
        }
        return try {
            val core = iso.substringBefore('.').removeSuffix("Z")
            val formatter = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.US)
            formatter.timeZone = TimeZone.getTimeZone("UTC")
            formatter.parse(core)?.time
        } catch (_: Exception) {
            null
        }
    }
}

internal fun JSONObject.optStringOrNull(key: String): String? {
    if (!has(key) || isNull(key)) {
        return null
    }
    val value = optString(key, "")
    return value.ifEmpty { null }
}

internal fun JSONObject.optDoubleOrNull(key: String): Double? {
    if (!has(key) || isNull(key)) {
        return null
    }
    val value = optDouble(key, Double.NaN)
    return if (value.isNaN()) null else value
}

internal fun JSONObject.optIntOrNull(key: String): Int? {
    if (!has(key) || isNull(key)) {
        return null
    }
    return optInt(key)
}
