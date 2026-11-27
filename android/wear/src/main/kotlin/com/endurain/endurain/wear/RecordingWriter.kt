package com.endurain.endurain.wear

import android.util.Log
import com.endurain.endurain.watchlink.WatchRecordedPoint
import com.endurain.endurain.watchlink.WatchRecording
import com.endurain.endurain.watchlink.WatchRecordingStore
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import java.io.IOException

/**
 * Runs everything that touches the [WatchRecordingStore] (and the handoff
 * serialisation) on [ioDispatcher], one operation at a time and in the order
 * they were requested, so the main thread never waits for the disk.
 *
 * The order holds because the [mutex] is fair and operations are requested
 * from the recorder's scope, which runs its coroutines up to their first
 * suspension in call order (`Dispatchers.Main.immediate`, or a single-threaded
 * test dispatcher).
 */
internal class RecordingWriter(
    private val store: WatchRecordingStore,
    private val scope: CoroutineScope,
    private val ioDispatcher: CoroutineDispatcher,
) {
    private val mutex = Mutex()

    /** Points whose write failed, retried ahead of the next batch; only touched under [mutex]. */
    private val unwritten = mutableListOf<WatchRecordedPoint>()

    /** Runs [block] after every earlier operation and returns its result; a failure is rethrown. */
    suspend fun <T> submit(block: () -> T): T = mutex.withLock { withContext(ioDispatcher) { block() } }

    /** Runs [block] in the background after every earlier operation, logging its failure. */
    fun post(
        what: String,
        block: () -> Unit,
    ) {
        scope.launch {
            try {
                submit(block)
            } catch (error: CancellationException) {
                throw error
            } catch (error: Exception) {
                Log.w(TAG, "Could not $what", error)
            }
        }
    }

    /**
     * Appends [points] after any that failed to save earlier, keeping the
     * file in order. Call it from an operation; false when the write failed
     * and the points are kept for the next batch.
     */
    fun appendInOrder(points: List<WatchRecordedPoint>): Boolean {
        unwritten += points
        if (unwritten.isEmpty()) return true
        return try {
            store.append(unwritten.toList())
            unwritten.clear()
            true
        } catch (error: IOException) {
            Log.w(TAG, "Could not save workout points", error)
            false
        }
    }

    /** Saves [points], then the recording with its new [distance] when that worked. */
    fun postPoints(
        points: List<WatchRecordedPoint>,
        recording: WatchRecording?,
    ) {
        post("save the workout points") {
            if (appendInOrder(points) && recording != null) {
                try {
                    store.update(recording)
                } catch (error: IOException) {
                    Log.w(TAG, "Could not save the workout distance", error)
                }
            }
        }
    }

    /** Saves the timing state. */
    fun postRecording(recording: WatchRecording) {
        post("save the workout state") { store.update(recording) }
    }

    /** Forgets the saved workout, and any points still waiting to be saved. */
    fun postClear() {
        post("clear the saved workout") {
            unwritten.clear()
            store.clear()
        }
    }
}
