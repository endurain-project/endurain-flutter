package com.endurain.endurain.activity

import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileInputStream

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
 * The point count, the last point and drain checkpoints are cached in memory
 * (built by one full scan, then extended on every [append]) so the recorder's
 * per-fix bookkeeping and offset drains do not re-parse the whole file. The
 * cache is tied to the file's length and modification time, so a write from
 * elsewhere (e.g. the Dart store) or a deletion makes it rebuild.
 *
 * This type performs no locking; the owning [ActiveActivityStore] serializes
 * all access under its process-wide lock.
 */
internal class ActivePointsLog(private val pointsFile: File) {

    /** What the file held when last scanned or appended to by this instance. */
    private class Index(
        var length: Long,
        var modified: Long,
        var count: Int,
        var last: RecordedActivityPointData?,
        var endsWithNewline: Boolean,
        /** Byte offset of the line holding valid point `i * CHECKPOINT_STRIDE`. */
        val checkpoints: MutableList<Long>,
    ) {
        fun add(point: RecordedActivityPointData, lineOffset: Long) {
            if (count % CHECKPOINT_STRIDE == 0) {
                checkpoints.add(lineOffset)
            }
            count++
            last = point
        }
    }

    private var index: Index? = null

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
        // A new file starts an empty cache, so a fresh recording never scans.
        val cached = if (pointsFile.exists()) currentIndex() else Index(0, 0, 0, null, true, ArrayList())
        index = null
        val lines = points.map { it.toJsonLine() }
        val builder = StringBuilder()
        for (line in lines) {
            builder.append(line).append('\n')
        }
        pointsFile.appendText(builder.toString())
        // A partial last line (a crash mid-write) merges with the first new
        // line, so only extend the cache when the file ended cleanly.
        if (cached == null || !cached.endsWithNewline) {
            return
        }
        var offset = cached.length
        for (line in lines) {
            RecordedActivityPointData.tryParseLine(line)?.let { cached.add(it, offset) }
            offset += line.toByteArray(Charsets.UTF_8).size + 1
        }
        if (pointsFile.length() != offset) {
            return
        }
        cached.length = offset
        cached.modified = pointsFile.lastModified()
        index = cached
    }

    /**
     * Reads stored points, skipping the first [sinceOffset] valid points.
     *
     * Malformed lines are ignored and do not advance the offset, so a corrupt
     * entry cannot cause a still-pending point to be skipped when draining.
     * Lines before the closest checkpoint at or below [sinceOffset] are not
     * parsed again.
     */
    fun read(sinceOffset: Int = 0): List<RecordedActivityPointData> {
        if (!pointsFile.exists()) {
            return emptyList()
        }
        val result = ArrayList<RecordedActivityPointData>()
        val cached = currentIndex()
        if (cached == null) {
            var validIndex = 0
            scan { point ->
                if (validIndex >= sinceOffset) {
                    result.add(point)
                }
                validIndex++
            }
            return result
        }
        if (cached.count == 0 || sinceOffset >= cached.count) {
            return result
        }
        val checkpoint = (maxOf(sinceOffset, 0) / CHECKPOINT_STRIDE)
            .coerceAtMost(cached.checkpoints.size - 1)
        var validIndex = checkpoint * CHECKPOINT_STRIDE
        forEachLine(cached.checkpoints[checkpoint]) { _, line ->
            RecordedActivityPointData.tryParseLine(line)?.let { point ->
                if (validIndex >= sinceOffset) {
                    result.add(point)
                }
                validIndex++
            }
            true
        }
        return result
    }

    /** Counts only valid, parseable points so callers can compute offsets. */
    fun count(): Int = indexOrScan()?.count ?: 0

    /** Returns the last valid point for segment-gap recovery after restart. */
    fun last(): RecordedActivityPointData? = indexOrScan()?.last

    private fun first(): RecordedActivityPointData? {
        val cached = indexOrScan() ?: return null
        val start = cached.checkpoints.firstOrNull() ?: return null
        var first: RecordedActivityPointData? = null
        forEachLine(start) { _, line ->
            first = RecordedActivityPointData.tryParseLine(line)
            first == null
        }
        return first
    }

    /** The cache, rebuilt by a full scan when missing or out of date; `null` without a file. */
    private fun indexOrScan(): Index? {
        if (!pointsFile.exists()) {
            index = null
            return null
        }
        return currentIndex() ?: scan {}
    }

    private fun currentIndex(): Index? {
        val cached = index ?: return null
        if (cached.length == pointsFile.length() && cached.modified == pointsFile.lastModified()) {
            return cached
        }
        index = null
        return null
    }

    /** Parses the whole file, rebuilding the cache and passing each valid point to [onPoint]. */
    private fun scan(onPoint: (RecordedActivityPointData) -> Unit): Index? {
        if (!pointsFile.exists()) {
            index = null
            return null
        }
        val rebuilt = Index(0, 0, 0, null, true, ArrayList())
        val endsWithNewline = forEachLine(0) { offset, line ->
            RecordedActivityPointData.tryParseLine(line)?.let { point ->
                rebuilt.add(point, offset)
                onPoint(point)
            }
            true
        }
        rebuilt.length = pointsFile.length()
        rebuilt.modified = pointsFile.lastModified()
        rebuilt.endsWithNewline = endsWithNewline
        index = rebuilt
        return rebuilt
    }

    /**
     * Calls [action] with each line from byte [startOffset] on, with the
     * line's starting offset, until it returns false. Lines are split on
     * `\n`; a trailing line without one is still passed. Returns whether
     * the file ends with a newline (or is empty).
     */
    private fun forEachLine(startOffset: Long, action: (Long, String) -> Boolean): Boolean {
        val line = ByteArrayOutputStream()
        var lineStart = startOffset
        var position = startOffset
        var endsWithNewline = true
        FileInputStream(pointsFile).use { stream ->
            if (startOffset > 0) {
                stream.channel.position(startOffset)
            }
            val chunk = ByteArray(READ_CHUNK_BYTES)
            while (true) {
                val read = stream.read(chunk)
                if (read < 0) {
                    break
                }
                var from = 0
                for (i in 0 until read) {
                    if (chunk[i] == NEWLINE) {
                        line.write(chunk, from, i - from)
                        if (!action(lineStart, line.toString(Charsets.UTF_8.name()))) {
                            return endsWithNewline
                        }
                        line.reset()
                        from = i + 1
                        lineStart = position + from
                    }
                }
                line.write(chunk, from, read - from)
                position += read
                if (read > 0) {
                    endsWithNewline = chunk[read - 1] == NEWLINE
                }
            }
        }
        if (line.size() > 0) {
            action(lineStart, line.toString(Charsets.UTF_8.name()))
        }
        return endsWithNewline
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
        val first = first() ?: return null
        val last = last() ?: return null
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

    private companion object {
        const val CHECKPOINT_STRIDE = 64
        const val READ_CHUNK_BYTES = 64 * 1024
        const val NEWLINE = '\n'.code.toByte()
    }
}
