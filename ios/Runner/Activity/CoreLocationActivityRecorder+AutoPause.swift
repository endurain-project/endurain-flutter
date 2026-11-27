import Foundation
import CoreLocation

/// Automatic pause and resume of a recording, driven by the fixes
/// `CoreLocationActivityRecorder` receives.
extension CoreLocationActivityRecorder {
    /// Feeds a fix received while auto-paused. Core Location keeps running
    /// (never stopped for an automatic pause) so movement can resume the
    /// recording without user interaction, but no point is persisted until
    /// hysteresis confirms movement has resumed.
    func handleAutoPausedLocationFix(
        _ session: ActiveActivitySessionData,
        _ location: CLLocation
    ) {
        guard let detector = autoPauseDetector else {
            return
        }
        let effectiveMillis = LocationFixPolicy.effectiveMillis(location)
        let transition = detector.onAutoPausedPoint(
            LocationFixPolicy.movementSample(location, millis: effectiveMillis)
        )
        guard case .autoResume = transition else {
            return
        }
        let resumed = session.copyWith(
            status: ActiveActivitySessionData.statusRecording,
            resumedAt: .some(IsoTime.format(Date(timeIntervalSince1970: Double(effectiveMillis) / 1000))),
            pausedAt: .some(nil),
            pausedAutomatically: false
        )
        guard store.saveSession(resumed) else {
            stopAfterPersistenceFailure()
            return
        }
        segmenter.resumedFromPause = true
        ActivityRecorderCoordinator.shared.emitSession(
            type: ActivityRecorderCoordinator.eventAutoResumed,
            session: resumed
        )
        // Queue the state cue before this fix can enqueue a progress update.
        announcements.speakTransitionCue(autoPaused: false)
        // Persist this same triggering fix as the first point of the new
        // segment, matching the manual resume flow (`resumedFromPause` forces
        // a segment break above).
        handleActiveLocationFix(resumed, location)
        announcements.scheduleNextTimeAnnouncement()
    }

    /// Auto-pauses once the stillness reaches the pause delay while the
    /// device stays stationary.
    ///
    /// Core Location stops delivering fixes while the device is stationary,
    /// so no further fix would reach the detector to time the stillness.
    /// Does nothing when one is already pending, auto-pause is off, or the
    /// recording is not active.
    func scheduleStationaryAutoPause() {
        guard stationaryAutoPauseTask == nil,
              let dueAtMillis = autoPauseDetector?.autoPauseDueAtMillis,
              store.loadSession()?.status == ActiveActivitySessionData.statusRecording else {
            return
        }
        let delayMillis = max(0, dueAtMillis - LocationFixPolicy.nowMillis())
        stationaryAutoPauseTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(delayMillis) * 1_000_000)
            guard !Task.isCancelled, let self else {
                return
            }
            self.stationaryAutoPauseTask = nil
            self.autoPauseWhileStationary()
        }
    }

    /// Drops the pending stationary auto-pause, for a fix that shows the
    /// device moving again or a stop, pause or resume.
    func cancelStationaryAutoPause() {
        stationaryAutoPauseTask?.cancel()
        stationaryAutoPauseTask = nil
    }

    private func autoPauseWhileStationary() {
        guard let detector = autoPauseDetector,
              let session = store.loadSession(),
              session.status == ActiveActivitySessionData.statusRecording else {
            return
        }
        let nowMillis = LocationFixPolicy.nowMillis()
        if case .autoPause = detector.onStationary(atMillis: nowMillis) {
            transitionToAutoPaused(session, nowMillis: nowMillis)
        }
    }

    func transitionToAutoPaused(_ session: ActiveActivitySessionData, nowMillis: Int64) {
        cancelStationaryAutoPause()
        // Back-date the pause to when movement last stopped so the stillness
        // delay is not counted as recorded time.
        let anchorMillis = IsoTime.toEpochMillis(session.resumedAt ?? session.startedAt)
        var pausedAtMillis = min(autoPauseDetector?.lastMovementAtMillis ?? nowMillis, nowMillis)
        if let anchorMillis = anchorMillis {
            pausedAtMillis = max(pausedAtMillis, min(anchorMillis, nowMillis))
        }
        let paused = session.copyWith(
            status: ActiveActivitySessionData.statusPaused,
            pausedAt: .some(IsoTime.format(Date(timeIntervalSince1970: Double(pausedAtMillis) / 1000))),
            elapsedDurationSeconds: session.elapsedSecondsAt(pausedAtMillis),
            pausedAutomatically: true
        )
        guard store.saveSession(paused) else {
            stopAfterPersistenceFailure()
            return
        }
        ActivityRecorderCoordinator.shared.emitSession(
            type: ActivityRecorderCoordinator.eventAutoPaused,
            session: paused
        )
        // Cancel queued progress speech before announcing the state change.
        AudioAnnouncer.shared.stop()
        announcements.speakTransitionCue(autoPaused: true)
        announcements.flush()
        announcements.cancelTimeAnnouncement()
        // Deliberately does not call `stopCollection()`: an automatic pause
        // must keep monitoring location so movement can resume the recording
        // without user interaction, unlike a manual pause which stops
        // collection entirely (see `stopCollection`).
    }
}
