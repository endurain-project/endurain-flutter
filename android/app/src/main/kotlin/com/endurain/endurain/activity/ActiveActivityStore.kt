package com.endurain.endurain.activity

import android.content.Context
import android.util.AtomicFile
import java.io.File
import java.io.FileNotFoundException
import org.json.JSONObject

/**
 * App-private, file-backed store for the single active recording.
 *
 * Mirrors the Dart `FileActiveActivityStore` layout so either recorder can
 * recover state written by the other:
 *
 * ```
 * <filesDir>/activity_records/active/session.json
 * <filesDir>/activity_records/active/points.jsonl
 * ```
 *
 * On Android `path_provider`'s application-support directory resolves to
 * `context.filesDir`, so this path matches the Dart store exactly. All files
 * live in app-private storage; nothing is written to shared/public storage.
 */
class ActiveActivityStore private constructor(appContext: Context) {
    private val rootDir = File(appContext.filesDir, ROOT_DIR)
    private val activeDir = File(rootDir, ACTIVE_DIR)
    private val sessionFile = File(activeDir, SESSION_FILE)
    private val atomicSessionFile = AtomicFile(sessionFile)
    private val pointsFile = File(activeDir, POINTS_FILE)
    private val lock = Any()

    fun saveSession(session: ActiveActivitySessionData) {
        synchronized(lock) {
            ensureDir()
            var output: java.io.FileOutputStream? = null
            try {
                output = atomicSessionFile.startWrite()
                output.write(session.toJson().toString().toByteArray(Charsets.UTF_8))
                output.fd.sync()
                atomicSessionFile.finishWrite(output)
            } catch (error: Exception) {
                output?.let { atomicSessionFile.failWrite(it) }
                throw error
            }
        }
    }

    fun loadSession(): ActiveActivitySessionData? {
        synchronized(lock) {
            return try {
                atomicSessionFile.openRead().bufferedReader().use { reader ->
                    ActiveActivitySessionData.fromJson(JSONObject(reader.readText()))
                } ?: orphanedSession()
            } catch (_: FileNotFoundException) {
                orphanedSession()
            } catch (_: Exception) {
                orphanedSession()
            }
        }
    }

    fun hasRecoverableData(): Boolean {
        synchronized(lock) {
            return activeDir.listFiles()?.isNotEmpty() == true
        }
    }

    fun appendPoints(points: List<RecordedActivityPointData>) {
        if (points.isEmpty()) {
            return
        }
        synchronized(lock) {
            ensureDir()
            val builder = StringBuilder()
            for (point in points) {
                builder.append(point.toJsonLine()).append('\n')
            }
            pointsFile.appendText(builder.toString())
        }
    }

    /**
     * Reads stored points, skipping the first [sinceOffset] valid points.
     *
     * Malformed lines are ignored and do not advance the offset, matching the
     * Dart store's drain semantics.
     */
    fun readPoints(sinceOffset: Int = 0): List<RecordedActivityPointData> {
        synchronized(lock) {
            if (!pointsFile.exists()) {
                return emptyList()
            }
            val result = ArrayList<RecordedActivityPointData>()
            var index = 0
            pointsFile.forEachLine { line ->
                val point = RecordedActivityPointData.tryParseLine(line)
                if (point != null) {
                    if (index >= sinceOffset) {
                        result.add(point)
                    }
                    index++
                }
            }
            return result
        }
    }

    /** Counts only valid, parseable points so callers can compute offsets. */
    fun pointCount(): Int {
        synchronized(lock) {
            if (!pointsFile.exists()) {
                return 0
            }
            var count = 0
            pointsFile.forEachLine { line ->
                if (RecordedActivityPointData.tryParseLine(line) != null) {
                    count++
                }
            }
            return count
        }
    }

    /** Returns the last valid point for segment-gap recovery after restart. */
    fun lastPoint(): RecordedActivityPointData? {
        synchronized(lock) {
            if (!pointsFile.exists()) {
                return null
            }
            var lastPoint: RecordedActivityPointData? = null
            pointsFile.forEachLine { line ->
                RecordedActivityPointData.tryParseLine(line)?.let {
                    lastPoint = it
                }
            }
            return lastPoint
        }
    }

    /** Removes all active-recording files. */
    fun clear() {
        synchronized(lock) {
            if (activeDir.exists()) {
                activeDir.deleteRecursively()
            }
        }
    }

    private fun ensureDir() {
        if (!activeDir.exists()) {
            activeDir.mkdirs()
        }
    }

    private fun orphanedSession(): ActiveActivitySessionData? {
        val points = readPoints()
        if (points.isEmpty()) return null
        val first = points.first()
        val last = points.last()
        val startedMillis = IsoTime.toEpochMillis(first.timestamp)
        val endedMillis = IsoTime.toEpochMillis(last.timestamp)
        val elapsedSeconds = if (startedMillis != null && endedMillis != null) {
            kotlin.math.max(0, ((endedMillis - startedMillis) / 1000L).toInt())
        } else {
            0
        }
        return ActiveActivitySessionData(
            localSessionId = "recovered_${pointsFile.lastModified()}",
            activityType = "other",
            status = ActiveActivitySessionData.STATUS_FAILED,
            startedAt = first.timestamp,
            endedAt = last.timestamp,
            elapsedDurationSeconds = elapsedSeconds,
            currentSegmentIndex = last.segmentIndex,
        )
    }

    companion object {
        const val ROOT_DIR = "activity_records"
        const val ACTIVE_DIR = "active"
        const val SESSION_FILE = "session.json"
        const val POINTS_FILE = "points.jsonl"

        @Volatile
        private var instance: ActiveActivityStore? = null

        /** Process-wide singleton so the service and channel share one lock. */
        fun of(context: Context): ActiveActivityStore {
            return instance ?: synchronized(this) {
                instance ?: ActiveActivityStore(context.applicationContext)
                    .also { instance = it }
            }
        }
    }
}
