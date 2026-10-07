import Foundation

/// Accumulated elapsed-recording-seconds for a session, shared by
/// `ActivityRecorderChannel` (pause/resume/stop/recover) and
/// `CoreLocationActivityRecorder` (GPS and timer scheduling) so the
/// two never drift apart.
///
/// Mirrors the Android `SessionTiming` object and the Dart geolocator
/// recorder: a paused session keeps its stored value; an active one adds the
/// current segment's running time measured from `resumedAt ?? startedAt`.
enum SessionTiming {
    static func elapsedSeconds(
        _ session: ActiveActivitySessionData,
        referenceMillis: Int64
    ) -> Int {
        if session.status != ActiveActivitySessionData.statusRecording {
            return session.elapsedDurationSeconds
        }
        guard let anchor = IsoTime.toEpochMillis(session.resumedAt ?? session.startedAt) else {
            return session.elapsedDurationSeconds
        }
        let segmentSeconds = Int((referenceMillis - anchor) / 1000)
        return session.elapsedDurationSeconds + max(0, segmentSeconds)
    }

    static func afterInterruption(
        _ session: ActiveActivitySessionData,
        lastPointMillis: Int64?,
        nowMillis: Int64
    ) -> ActiveActivitySessionData {
        guard session.status == ActiveActivitySessionData.statusRecording else {
            return session
        }
        let referenceMillis = lastPointMillis
            ?? IsoTime.toEpochMillis(session.resumedAt ?? session.startedAt)
            ?? nowMillis
        return session.copyWith(
            resumedAt: .some(IsoTime.format(Date(timeIntervalSince1970: Double(nowMillis) / 1000))),
            pausedAt: .some(nil),
            endedAt: .some(nil),
            elapsedDurationSeconds: elapsedSeconds(session, referenceMillis: referenceMillis)
        )
    }
}
