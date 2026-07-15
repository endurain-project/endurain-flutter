package com.endurain.endurain.activity

import java.io.File

/**
 * Append-only, file-backed log of recorded points for the active recording.
 *
 * Extracted from [ActiveActivityStore] so the durability-critical drain and
 * crash-recovery logic can be unit-tested on the JVM without Android's
 * `android.content.Context` or `android.util.AtomicFile`. It depends only on
 * [java.io.File] and the pure [RecordedActivityPointData] / [IsoTime] models,
 * so it runs in the standard `testDebugUnitTest` job.
 *
 * Malformed lines are skipped everywhere and never advance the drain offset,
 * matching the Dart `FileActiveActivityStore` semantics so either recorder can
 * recover state written by the other. A single corrupt entry must never drop a
 * real, still-pending point during draining.
 *
 * This type performs no locking; the owning [ActiveActivityStore] serializes
 * all access under its process-wide lock.
 */
internal class ActivePointsLog(private val pointsFile: File) {

    /** Appends [points] as one JSON line each. No-op for an empty list. */
    fun append(points: List<RecordedActivityPointData>) {
        if (points.isEmpty()) {
            return
        }
        pointsFile.parentFile?.let { parent ->
            if (!parent.exists()) {
                parent.mkdirs()
            }
        }
        val builder = StringBuilder()
        for (point in points) {
            builder.append(point.toJsonLine()).append('\n')
        }
        pointsFile.appendText(builder.toString())
    }

    /**
     * Reads stored points, skipping the first [sinceOffset] valid points.
     *
     * Malformed lines are ignored and do not advance the offset, so a corrupt
     * entry cannot cause a still-pending point to be skipped when draining.
     */
    fun read(sinceOffset: Int = 0): List<RecordedActivityPointData> {
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

    /** Counts only valid, parseable points so callers can compute offsets. */
    fun count(): Int {
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

    /** Returns the last valid point for segment-gap recovery after restart. */
    fun last(): RecordedActivityPointData? {
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

    /**
     * Reconstructs a recoverable session from orphaned points when the session
     * metadata file is missing or unreadable (e.g. the process was killed
     * before the session was persisted, but points were already flushed).
     *
     * Returns a [ActiveActivitySessionData.STATUS_FAILED] session spanning the
     * first and last valid points, or `null` when no valid points remain.
     */
    fun orphanedSession(): ActiveActivitySessionData? {
        val points = read()
        if (points.isEmpty()) {
            return null
        }
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
}
