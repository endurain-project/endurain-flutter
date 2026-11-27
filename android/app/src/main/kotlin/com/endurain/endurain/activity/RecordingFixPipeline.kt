package com.endurain.endurain.activity

import java.util.Date

/**
 * Turns each location fix of an active recording into a stored, announced
 * point and drives the automatic pause/resume transitions.
 *
 * Every fix reads the session, appends to the points log (durable before the
 * event reaches Flutter) and may rewrite the session; all of it runs on the
 * recorder thread (see [RecorderWorker]), which owns this class's state
 * ([autoPauseDetector], [nextPointOffset]). Session rewrites go through
 * [ActiveActivityStore.updateSession] so a pause or stop issued from another
 * thread meanwhile is never overwritten. A failed point append calls
 * [onPersistenceFailure].
 */
internal class RecordingFixPipeline(
    private val store: ActiveActivityStore,
    private val fixProcessor: LocationFixProcessor,
    private val sensors: RecorderSensors,
    private val announcements: RecorderAnnouncementDriver,
    private val wakeLock: RecordingWakeLock,
    private val onPersistenceFailure: () -> Unit,
) {
    private var autoPauseDetector: MovementAutoPauseDetector? = null
    private var nextPointOffset = 0

    /**
     * Starts monitoring for a (re)started collection of [session], whose
     * points log already holds [pointCount] points. The stillness timer is
     * anchored to now, not the last stored point: that point can predate a
     * manual pause or provider restart, which would let the first slow fix
     * auto-pause immediately.
     */
    fun begin(session: ActiveActivitySessionData?, pointCount: Int) {
        autoPauseDetector = MovementAutoPauseDetector(
            MovementAutoPauseConfig(
                enabled = session?.autoPauseEnabled ?: false,
                pauseDelayMillis = (session?.autoPauseDelaySeconds ?: 5) * 1000L,
            ),
        ).also { it.reset(System.currentTimeMillis()) }
        nextPointOffset = pointCount
    }

    /**
     * Stops monitoring movement entirely, so a manually paused recording can
     * never auto-resume; [begin] builds a fresh detector for the next active
     * period.
     */
    fun stopMonitoring() {
        autoPauseDetector = null
    }

    fun onFix(fix: LocationFix) {
        wakeLock.renew()
        val session = store.loadSession() ?: return
        when (session.status) {
            ActiveActivitySessionData.STATUS_RECORDING -> onActiveLocationFix(session, fix)
            ActiveActivitySessionData.STATUS_PAUSED -> {
                // A manual pause stops collection entirely, so only an
                // auto-paused session can still be receiving fixes here. This
                // also guards a stray in-flight fix delivered just as a manual
                // pause took effect.
                if (session.pausedAutomatically) {
                    onAutoPausedLocationFix(fix)
                }
            }
            else -> Unit
        }
    }

    private fun onActiveLocationFix(session: ActiveActivitySessionData, fix: LocationFix) {
        // Feed the auto-pause detector before the accuracy/speed gates in
        // [fixProcessor], so stillness timing advances from wall-clock
        // progress on every fix (including noisy ones the detector itself
        // discounts as movement evidence), matching the iOS recorder.
        val transition = autoPauseDetector?.onActivePoint(fix.toMovementSample())
            ?: MovementAutoPauseTransition.NONE
        if (transition == MovementAutoPauseTransition.AUTO_PAUSE) {
            transitionToAutoPaused(fix.timeMillis)
            return
        }
        val outcome = fixProcessor.process(fix, session.currentSegmentIndex)
        if (outcome !is LocationFixProcessor.Outcome.Accepted) {
            return
        }
        if (outcome.segmentIndex != session.currentSegmentIndex) {
            store.updateSession { it.copy(currentSegmentIndex = outcome.segmentIndex) }
        }
        val point = fix.toPoint(
            segmentIndex = outcome.segmentIndex,
            heartRateBpm = sensors.heartRateBpm,
            powerWatts = sensors.powerWatts,
            cadenceRpm = sensors.cadenceRpm,
        )
        try {
            store.appendPoints(listOf(point))
        } catch (_: Exception) {
            onPersistenceFailure()
            return
        }
        ActivityRecorderCoordinator.emitPointBatch(
            listOf(point),
            session.localSessionId,
            nextPointOffset,
        )
        nextPointOffset += 1
        announcements.onFix(fix.timeMillis, fix.latitude, fix.longitude, outcome.isNewSegment)
    }

    /**
     * Feeds a fix received while auto-paused. Collection keeps running (the
     * location listener is never unregistered for an automatic pause) so
     * movement can resume the recording without user interaction, but no
     * point is persisted until hysteresis confirms movement has resumed.
     */
    private fun onAutoPausedLocationFix(fix: LocationFix) {
        val detector = autoPauseDetector ?: return
        val transition = detector.onAutoPausedPoint(fix.toMovementSample())
        if (transition != MovementAutoPauseTransition.AUTO_RESUME) {
            return
        }
        // Only an auto-pause may resume here: a manual pause or stop that
        // landed meanwhile must not be overwritten.
        val resumed = store.updateSession { current ->
            if (current.status != ActiveActivitySessionData.STATUS_PAUSED ||
                !current.pausedAutomatically
            ) {
                return@updateSession null
            }
            current.copy(
                status = ActiveActivitySessionData.STATUS_RECORDING,
                resumedAt = IsoTime.format(Date(fix.timeMillis)),
                pausedAt = null,
                pausedAutomatically = false,
            )
        } ?: return
        fixProcessor.resumedFromPause = true
        ActivityRecorderCoordinator.emitSession(
            ActivityRecorderCoordinator.TYPE_AUTO_RESUMED,
            resumed,
        )
        // Queue the state cue before this fix can enqueue a progress update.
        announcements.speakTransitionCue(autoPaused = false)
        // Persist this same triggering fix as the first point of the new
        // segment, matching the manual resume flow (`resumedFromPause` forces
        // a segment break in the fix processor).
        onActiveLocationFix(resumed, fix)
        announcements.scheduleNextTimeAnnouncement()
    }

    private fun transitionToAutoPaused(nowMillis: Long) {
        val paused = store.updateSession { session ->
            // A manual pause or stop that landed meanwhile wins.
            if (session.status != ActiveActivitySessionData.STATUS_RECORDING) {
                return@updateSession null
            }
            // Back-date the pause to when movement last stopped so the
            // stillness delay is not counted as recorded time.
            val anchorMillis = IsoTime.toEpochMillis(session.resumedAt ?: session.startedAt)
            val pausedAtMillis = (autoPauseDetector?.lastMovementAtMillis ?: nowMillis)
                .coerceAtLeast(anchorMillis ?: Long.MIN_VALUE)
                .coerceAtMost(nowMillis)
            session.copy(
                status = ActiveActivitySessionData.STATUS_PAUSED,
                pausedAt = IsoTime.format(Date(pausedAtMillis)),
                elapsedDurationSeconds = session.elapsedSecondsAt(pausedAtMillis),
                pausedAutomatically = true,
            )
        } ?: return
        ActivityRecorderCoordinator.emitSession(
            ActivityRecorderCoordinator.TYPE_AUTO_PAUSED,
            paused,
        )
        // Cancel queued progress speech before announcing the state change.
        AudioAnnouncer.stop()
        announcements.speakTransitionCue(autoPaused = true)
        announcements.flush()
        announcements.cancelScheduled()
        // Deliberately does not call `stopCollection()`: an automatic pause
        // must keep monitoring location so movement can resume the recording
        // without user interaction, unlike a manual pause which stops
        // collection entirely (see `stopCollection`).
    }
}
