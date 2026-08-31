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
    private val pointsLog = ActivePointsLog(pointsFile)
    private val announcementFile = File(activeDir, ANNOUNCEMENT_FILE)
    private val atomicAnnouncementFile = AtomicFile(announcementFile)
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
                } ?: pointsLog.orphanedSession()
            } catch (_: FileNotFoundException) {
                pointsLog.orphanedSession()
            } catch (_: Exception) {
                pointsLog.orphanedSession()
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
            pointsLog.append(points)
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
            return pointsLog.read(sinceOffset)
        }
    }

    /** Counts only valid, parseable points so callers can compute offsets. */
    fun pointCount(): Int {
        synchronized(lock) {
            return pointsLog.count()
        }
    }

    /** Returns the last valid point for segment-gap recovery after restart. */
    fun lastPoint(): RecordedActivityPointData? {
        synchronized(lock) {
            return pointsLog.last()
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

    /**
     * Persists the audio-announcement config + progress for the active
     * recording. Lives inside the same active-recording directory as the
     * session/points files, so [clear] removes it too and [hasRecoverableData]
     * keeps working unchanged.
     */
    fun saveAnnouncementState(state: AnnouncementStateData) {
        synchronized(lock) {
            ensureDir()
            var output: java.io.FileOutputStream? = null
            try {
                output = atomicAnnouncementFile.startWrite()
                output.write(state.toJson().toString().toByteArray(Charsets.UTF_8))
                output.fd.sync()
                atomicAnnouncementFile.finishWrite(output)
            } catch (error: Exception) {
                output?.let { atomicAnnouncementFile.failWrite(it) }
                throw error
            }
        }
    }

    /** Returns the persisted announcement state, or `null` when absent/corrupt. */
    fun loadAnnouncementState(): AnnouncementStateData? {
        synchronized(lock) {
            return try {
                atomicAnnouncementFile.openRead().bufferedReader().use { reader ->
                    AnnouncementStateData.fromJson(JSONObject(reader.readText()))
                }
            } catch (_: FileNotFoundException) {
                null
            } catch (_: Exception) {
                null
            }
        }
    }

    private fun ensureDir() {
        if (!activeDir.exists()) {
            activeDir.mkdirs()
        }
    }

    companion object {
        const val ROOT_DIR = "activity_records"
        const val ACTIVE_DIR = "active"
        const val SESSION_FILE = "session.json"
        const val POINTS_FILE = "points.jsonl"
        const val ANNOUNCEMENT_FILE = "announcement.json"

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
