import Foundation

/// Advances durable distance and elapsed-time announcement state.
///
/// Mirrors the Android `AnnouncementScheduler` object exactly — see its doc
/// comment for the full rationale. Delegates crossing detection to
/// `AnnouncementThresholdCalculator` and rendering to
/// `AnnouncementSpeechBuilder`. `onFix` accumulates accepted GPS distance;
/// `onElapsedTime` advances time milestones independently while stationary.
enum AnnouncementScheduler {
    struct Result {
        let state: AnnouncementStateData
        let announcements: [String]
    }

    /// Advances a time-based schedule without requiring a location fix.
    /// Paused time is excluded by the caller through `SessionTiming`; distance
    /// remains at the latest value accumulated by `onFix`.
    static func onElapsedTime(
        state: AnnouncementStateData,
        elapsedSeconds: Int
    ) -> Result {
        guard state.enabled, state.isTimeBased else {
            return Result(state: state, announcements: [])
        }
        let monotonicElapsedSeconds = max(state.lastElapsedSeconds, elapsedSeconds)
        let crossings = AnnouncementThresholdCalculator.crossedThresholds(
            intervalValue: Double(state.timeIntervalSeconds),
            // The durable index is authoritative. Elapsed state may already
            // have advanced past an unannounced threshold on a resumed GPS fix.
            previousCumulative: 0,
            newCumulative: Double(monotonicElapsedSeconds),
            lastAnnouncedIndex: state.lastAnnouncedTimeIndex
        )
        var updated = state.copyWith(lastElapsedSeconds: monotonicElapsedSeconds)
        guard !crossings.isEmpty else {
            return Result(state: updated, announcements: [])
        }

        var announcements: [String] = []
        for crossing in crossings {
            let crossingElapsedSeconds = Int(crossing.thresholdValue.rounded())
            updated = updated.copyWith(lastAnnouncedTimeIndex: crossing.thresholdIndex)
            announcements.append(
                AnnouncementSpeechBuilder.build(
                    state: state,
                    distanceMeters: state.cumulativeDistanceMeters,
                    elapsedSeconds: crossingElapsedSeconds
                )
            )
        }
        return Result(state: updated, announcements: announcements)
    }

    /// - Parameter isNewSegment: true when this fix starts a new track
    ///   segment (a pause/resume boundary or a large time gap). The
    ///   distance/time seed is reset without computing a delta so a segment
    ///   break can never be mistaken for real distance covered.
    static func onFix(
        state: AnnouncementStateData,
        latitude: Double,
        longitude: Double,
        elapsedSeconds: Int,
        isNewSegment: Bool
    ) -> Result {
        guard state.enabled else {
            return Result(state: state, announcements: [])
        }
        guard
            !isNewSegment,
            let lastLatitude = state.lastLatitude,
            let lastLongitude = state.lastLongitude
        else {
            let seeded = state.copyWith(
                lastLatitude: .some(latitude),
                lastLongitude: .some(longitude),
                lastElapsedSeconds: elapsedSeconds
            )
            return Result(state: seeded, announcements: [])
        }

        let deltaMeters = GeoDistance.haversineMeters(
            lat1: lastLatitude,
            lon1: lastLongitude,
            lat2: latitude,
            lon2: longitude
        )
        let newCumulativeDistance = state.cumulativeDistanceMeters + deltaMeters
        let previousElapsed = state.lastElapsedSeconds
        let monotonicElapsedSeconds = max(previousElapsed, elapsedSeconds)

        let crossings: [AnnouncementThresholdCalculator.Crossing]
        if state.isTimeBased {
            crossings = AnnouncementThresholdCalculator.crossedThresholds(
                intervalValue: Double(state.timeIntervalSeconds),
                previousCumulative: Double(previousElapsed),
                newCumulative: Double(monotonicElapsedSeconds),
                lastAnnouncedIndex: state.lastAnnouncedTimeIndex
            )
        } else {
            crossings = AnnouncementThresholdCalculator.crossedThresholds(
                intervalValue: state.distanceIntervalMeters,
                previousCumulative: state.cumulativeDistanceMeters,
                newCumulative: newCumulativeDistance,
                lastAnnouncedIndex: state.lastAnnouncedDistanceIndex
            )
        }

        var updated = state.copyWith(
            cumulativeDistanceMeters: newCumulativeDistance,
            lastLatitude: .some(latitude),
            lastLongitude: .some(longitude),
            lastElapsedSeconds: monotonicElapsedSeconds
        )
        guard !crossings.isEmpty else {
            return Result(state: updated, announcements: [])
        }

        var announcements: [String] = []
        let elapsedSpan = monotonicElapsedSeconds - previousElapsed
        for crossing in crossings {
            let interpolatedDistanceMeters: Double
            let interpolatedElapsedSeconds: Int
            if state.isTimeBased {
                interpolatedElapsedSeconds = Int(crossing.thresholdValue.rounded())
                interpolatedDistanceMeters = state.cumulativeDistanceMeters
                    + crossing.interpolationFraction * deltaMeters
                updated = updated.copyWith(lastAnnouncedTimeIndex: crossing.thresholdIndex)
            } else {
                interpolatedDistanceMeters = crossing.thresholdValue
                interpolatedElapsedSeconds = Int(
                    (Double(previousElapsed) + crossing.interpolationFraction * Double(elapsedSpan))
                        .rounded()
                )
                updated = updated.copyWith(lastAnnouncedDistanceIndex: crossing.thresholdIndex)
            }
            announcements.append(
                AnnouncementSpeechBuilder.build(
                    state: state,
                    distanceMeters: interpolatedDistanceMeters,
                    elapsedSeconds: interpolatedElapsedSeconds
                )
            )
        }
        return Result(state: updated, announcements: announcements)
    }
}
