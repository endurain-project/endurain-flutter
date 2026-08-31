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
        if session.status == ActiveActivitySessionData.statusPaused {
            return session.elapsedDurationSeconds
        }
        guard let anchor = IsoTime.toEpochMillis(session.resumedAt ?? session.startedAt) else {
            return session.elapsedDurationSeconds
        }
        let segmentSeconds = Int((referenceMillis - anchor) / 1000)
        return session.elapsedDurationSeconds + max(0, segmentSeconds)
    }
}
