import Foundation

/// Advances the durable announcement state by one location fix and returns
/// any spoken announcements that fix triggered.
///
/// Mirrors the Android `AnnouncementScheduler` object exactly — see its doc
/// comment for the full rationale. Delegates crossing detection to
/// `AnnouncementThresholdCalculator` and rendering to
/// `AnnouncementSpeechBuilder`; this type only owns the sequencing.
enum AnnouncementScheduler {
    struct Result {
        let state: AnnouncementStateData
        let announcements: [String]
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

        let crossings: [AnnouncementThresholdCalculator.Crossing]
        if state.isTimeBased {
            crossings = AnnouncementThresholdCalculator.crossedThresholds(
                intervalValue: Double(state.timeIntervalSeconds),
                previousCumulative: Double(previousElapsed),
                newCumulative: Double(elapsedSeconds),
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
            lastElapsedSeconds: elapsedSeconds
        )
        guard !crossings.isEmpty else {
            return Result(state: updated, announcements: [])
        }

        var announcements: [String] = []
        let elapsedSpan = elapsedSeconds - previousElapsed
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
