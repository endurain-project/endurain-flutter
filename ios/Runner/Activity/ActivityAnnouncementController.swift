import Foundation

/// Spoken progress announcements for the recording `CoreLocationActivityRecorder`
/// collects.
///
/// Advances the announcement schedule on every stored point and on a one-shot
/// timer for time-based announcements, keeps progress in memory between
/// durable checkpoints, and speaks through the shared `AudioAnnouncer`.
/// Checkpoints are timed with `systemUptime`, so a wall-clock change cannot
/// trigger or skip one.
@MainActor
final class ActivityAnnouncementController {
    private static let minTimeAnnouncementIntervalSeconds = 60
    private static let maxTimeAnnouncementIntervalSeconds = 3600

    private let store: ActiveActivityStore
    private let stateCache = AnnouncementStateCache()
    private var timeAnnouncementTask: Task<Void, Never>?

    /// Whether the recorder is collecting; time announcements only run then.
    var isCollecting: () -> Bool = { false }

    init(store: ActiveActivityStore) {
        self.store = store
    }

    /// Whether a time-based announcement is scheduled. Exposed for tests.
    var isTimeAnnouncementScheduled: Bool {
        return timeAnnouncementTask != nil
    }

    /// Reloads the durable progress, for a collection (re)start.
    func restore() {
        stateCache.reset()
        guard let state = store.loadAnnouncementState() else {
            return
        }
        stateCache.restore(state, uptime: Self.uptime())
    }

    /// Schedules one main-actor callback at the next elapsed-time threshold.
    /// One-shot scheduling avoids polling and serializes state with GPS fixes.
    func scheduleNextTimeAnnouncement() {
        cancelTimeAnnouncement()
        guard isCollecting(),
              let announcementState = currentState(),
              announcementState.enabled,
              announcementState.isTimeBased,
              announcementState.timeIntervalSeconds >= Self.minTimeAnnouncementIntervalSeconds,
              announcementState.timeIntervalSeconds <= Self.maxTimeAnnouncementIntervalSeconds,
              announcementState.lastAnnouncedTimeIndex >= 0,
              announcementState.lastAnnouncedTimeIndex < Int.max,
              let session = store.loadSession(),
              session.status == ActiveActivitySessionData.statusRecording else {
            return
        }
        let elapsedSeconds = SessionTiming.elapsedSeconds(
            session,
            referenceMillis: LocationFixPolicy.nowMillis()
        )
        let nextIndex = max(1, Int64(announcementState.lastAnnouncedTimeIndex) + 1)
        let thresholdResult = nextIndex.multipliedReportingOverflow(
            by: Int64(announcementState.timeIntervalSeconds)
        )
        guard !thresholdResult.overflow else {
            return
        }
        let remainingResult = thresholdResult.partialValue.subtractingReportingOverflow(
            Int64(elapsedSeconds)
        )
        guard !remainingResult.overflow else {
            return
        }
        let delay = Self.nanoseconds(seconds: max(1, remainingResult.partialValue))
        timeAnnouncementTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: delay)
            guard !Task.isCancelled, let self else {
                return
            }
            self.timeAnnouncementTask = nil
            self.announceTimeIfDue()
            self.scheduleNextTimeAnnouncement()
        }
    }

    func cancelTimeAnnouncement() {
        timeAnnouncementTask?.cancel()
        timeAnnouncementTask = nil
    }

    /// Advances announcement progress for the stored points and speaks
    /// crossings.
    func announce(
        _ points: [RecordedActivityPointData],
        isNewSegmentFlags: [Bool],
        session: ActiveActivitySessionData
    ) {
        guard
            var announcementState = currentState(),
            announcementState.enabled
        else {
            return
        }
        var announcements: [String] = []
        for (index, point) in points.enumerated() {
            guard let millis = IsoTime.toEpochMillis(point.timestamp) else {
                continue
            }
            let elapsedSeconds = SessionTiming.elapsedSeconds(session, referenceMillis: millis)
            let result = AnnouncementScheduler.onFix(
                state: announcementState,
                latitude: point.latitude,
                longitude: point.longitude,
                elapsedSeconds: elapsedSeconds,
                isNewSegment: isNewSegmentFlags[index]
            )
            announcementState = result.state
            announcements.append(contentsOf: result.announcements)
        }
        guard checkpoint(announcementState, persistBeforeSpeech: !announcements.isEmpty) else {
            return
        }
        speak(announcements, state: announcementState)
    }

    /// Speaks the auto-pause or auto-resume cue, when configured.
    func speakTransitionCue(autoPaused: Bool) {
        guard
            let announcementState = currentState(),
            let message = announcementState.transitionMessage(autoPaused: autoPaused)
        else {
            return
        }
        speak([message], state: announcementState)
    }

    /// Makes in-memory progress durable, for a collection stop or pause.
    func flush() {
        let uptime = Self.uptime()
        guard let state = stateCache.stateToPersist(uptime: uptime, force: true),
              store.saveAnnouncementState(state) else {
            return
        }
        stateCache.markPersisted(uptime: uptime)
    }

    // MARK: - Private

    /// Advances a time-based schedule without waiting for another GPS fix.
    private func announceTimeIfDue() {
        guard isCollecting(),
              let announcementState = currentState(),
              announcementState.enabled,
              announcementState.isTimeBased,
              let session = store.loadSession(),
              session.status == ActiveActivitySessionData.statusRecording else {
            return
        }
        let result = AnnouncementScheduler.onElapsedTime(
            state: announcementState,
            elapsedSeconds: SessionTiming.elapsedSeconds(
                session,
                referenceMillis: LocationFixPolicy.nowMillis()
            )
        )
        guard result.state != announcementState else {
            return
        }
        guard checkpoint(result.state, persistBeforeSpeech: !result.announcements.isEmpty) else {
            return
        }
        speak(result.announcements, state: announcementState)
    }

    private func speak(_ texts: [String], state: AnnouncementStateData) {
        for text in texts {
            AudioAnnouncer.shared.speak(
                text,
                duck: state.duckOtherAudio,
                languageTag: state.languageTag
            )
        }
    }

    private func currentState() -> AnnouncementStateData? {
        if let state = stateCache.state {
            return state
        }
        guard let state = store.loadAnnouncementState() else {
            return nil
        }
        stateCache.restore(state, uptime: Self.uptime())
        return state
    }

    /// Keeps normal GPS progress in memory, checkpoints it periodically, and
    /// makes threshold progress durable before the corresponding speech.
    private func checkpoint(
        _ state: AnnouncementStateData,
        persistBeforeSpeech: Bool
    ) -> Bool {
        let previousState = stateCache.state
        stateCache.update(state)
        let uptime = Self.uptime()
        guard let stateToPersist = stateCache.stateToPersist(
            uptime: uptime,
            force: persistBeforeSpeech
        ) else {
            return true
        }
        guard store.saveAnnouncementState(stateToPersist) else {
            if persistBeforeSpeech, let previousState {
                stateCache.update(previousState)
            }
            return !persistBeforeSpeech
        }
        stateCache.markPersisted(uptime: uptime)
        return true
    }

    private static func uptime() -> TimeInterval {
        return ProcessInfo.processInfo.systemUptime
    }

    private static func nanoseconds(seconds: Int64) -> UInt64 {
        let result = UInt64(clamping: seconds).multipliedReportingOverflow(by: 1_000_000_000)
        return result.overflow ? UInt64.max : result.partialValue
    }
}
