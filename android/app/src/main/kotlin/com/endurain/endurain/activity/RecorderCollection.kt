package com.endurain.endurain.activity

import android.location.Location

/**
 * The start/stop lifecycle of one session's location collection: it wires the
 * [RecorderLocationCollector] subscription to the [RecordingFixPipeline] and
 * the wake lock, and persists and reports why a start failed.
 *
 * Used only on the recorder thread (see [RecorderWorker]); the service
 * decides what a failed [begin] means for itself.
 */
internal class RecorderCollection(
    private val store: ActiveActivityStore,
    private val collector: RecorderLocationCollector,
    private val fixProcessor: LocationFixProcessor,
    private val fixPipeline: RecordingFixPipeline,
    private val wakeLock: RecordingWakeLock,
    private val announcements: RecorderAnnouncementDriver,
) {
    /** The session being collected, or `null`; read from other threads. */
    @Volatile
    var collectingSessionId: String? = null
        private set

    val isCollecting: Boolean
        get() = collectingSessionId != null

    /**
     * Subscribes to location updates for the active session. Returns false
     * when collection could not start; the failure is then already persisted
     * and emitted.
     */
    fun begin(onFix: (Location) -> Unit, onProviderToggled: () -> Unit): Boolean {
        stop()
        collector.unavailability()?.let {
            fail(it)
            return false
        }
        val session = store.loadSession()
        fixProcessor.lastPointEpochMillis =
            store.lastPoint()?.timestamp?.let(IsoTime::toEpochMillis)
        fixPipeline.begin(session, store.pointCount())
        val minUpdateDistanceMeters = if (session?.autoPauseEnabled == true) {
            0f
        } else {
            MIN_UPDATE_DISTANCE_METERS
        }
        val failure = collector.startActive(minUpdateDistanceMeters, onFix, onProviderToggled)
        if (failure != null) {
            fail(failure)
            return false
        }
        collectingSessionId = store.loadSession()?.localSessionId
        wakeLock.acquire()
        announcements.scheduleNextTimeAnnouncement()
        return true
    }

    fun stop() {
        collectingSessionId = null
        // Released first and unconditionally: the listener may already be null
        // (e.g. a start that never registered a provider), and the wake lock
        // must never outlive collection.
        announcements.cancelScheduled()
        wakeLock.release()
        // A manual pause reaches here and must stop monitoring movement
        // entirely, so a manually paused recording can never auto-resume;
        // `begin` always rebuilds a fresh detector for the next active period.
        fixPipeline.stopMonitoring()
        collector.stopActive()
    }

    /** Persists and reports why collection could not start. */
    fun fail(failure: RecorderLocationCollector.Failure) {
        SessionRecovery.persistFailure(store)
        ActivityRecorderCoordinator.emitFailed(
            when (failure) {
                RecorderLocationCollector.Failure.PERMISSION_LOST ->
                    ActivityRecorderCoordinator.REASON_PERMISSION_LOST
                RecorderLocationCollector.Failure.LOCATION_UNAVAILABLE ->
                    ActivityRecorderCoordinator.REASON_LOCATION_UNAVAILABLE
            },
        )
    }

    private companion object {
        // Mirrors the iOS LocationFixPolicy distance filter.
        const val MIN_UPDATE_DISTANCE_METERS = 3f
    }
}
