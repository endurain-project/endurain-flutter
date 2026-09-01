import Foundation

/// Pure, stateless calculation of the latest threshold a cumulative value
/// (distance in meters, or elapsed time in seconds) crossed.
///
/// Mirrors the Android `AnnouncementThresholdCalculator` object exactly — see
/// its doc comment for the full rationale. Thresholds are multiples of
/// `intervalValue`: 1x, 2x, 3x, ... Callers persist `Crossing.thresholdIndex`
/// as the new `lastAnnouncedIndex` so a threshold is never announced twice,
/// even across a process restart. `Crossing.interpolationFraction` locates
/// where, between the previous and new cumulative samples, the threshold
/// actually falls, so callers can interpolate the paired metric (elapsed time
/// for a distance-based interval, or distance for a time-based one) instead of
/// reporting the value at the next arbitrary GPS fix. When a gap skips several
/// thresholds, only the latest is returned so stale milestones never queue.
enum AnnouncementThresholdCalculator {
    struct Crossing: Equatable {
        let thresholdIndex: Int
        let thresholdValue: Double
        let interpolationFraction: Double
    }

    static func latestCrossing(
        intervalValue: Double,
        previousCumulative: Double,
        newCumulative: Double,
        lastAnnouncedIndex: Int
    ) -> Crossing? {
        guard intervalValue > 0, intervalValue.isFinite else {
            return nil
        }
        guard newCumulative > previousCumulative else {
            return nil
        }
        guard previousCumulative.isFinite, newCumulative.isFinite else {
            return nil
        }

        let newIndex = Int(floor(newCumulative / intervalValue))
        let startIndex = max(lastAnnouncedIndex + 1, 1)
        guard newIndex >= startIndex else {
            return nil
        }

        let span = newCumulative - previousCumulative
        let thresholdValue = intervalValue * Double(newIndex)
        let fraction: Double
        if span > 0 {
            fraction = min(max((thresholdValue - previousCumulative) / span, 0), 1)
        } else {
            fraction = 0
        }
        return Crossing(
            thresholdIndex: newIndex,
            thresholdValue: thresholdValue,
            interpolationFraction: fraction
        )
    }
}
