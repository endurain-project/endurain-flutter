import Foundation

/// Pure, stateless calculation of which announcement thresholds a cumulative
/// value (distance in meters, or elapsed time in seconds) has newly crossed.
///
/// Mirrors the Android `AnnouncementThresholdCalculator` object exactly — see
/// its doc comment for the full rationale. Thresholds are multiples of
/// `intervalValue`: 1x, 2x, 3x, ... Callers persist `Crossing.thresholdIndex`
/// as the new `lastAnnouncedIndex` so a threshold is never announced twice,
/// even across a process restart. `Crossing.interpolationFraction` locates
/// where, between the previous and new cumulative samples, the threshold
/// actually falls, so callers can interpolate the paired metric (elapsed time
/// for a distance-based interval, or distance for a time-based one) instead of
/// reporting the value at the next arbitrary GPS fix.
enum AnnouncementThresholdCalculator {
    struct Crossing: Equatable {
        let thresholdIndex: Int
        let thresholdValue: Double
        let interpolationFraction: Double
    }

    static func crossedThresholds(
        intervalValue: Double,
        previousCumulative: Double,
        newCumulative: Double,
        lastAnnouncedIndex: Int,
        maxCrossingsPerUpdate: Int = 20
    ) -> [Crossing] {
        guard intervalValue > 0, intervalValue.isFinite else {
            return []
        }
        guard newCumulative > previousCumulative else {
            return []
        }
        guard previousCumulative.isFinite, newCumulative.isFinite else {
            return []
        }

        let newIndex = Int(floor(newCumulative / intervalValue))
        let startIndex = max(lastAnnouncedIndex + 1, 1)
        guard newIndex >= startIndex else {
            return []
        }

        var result: [Crossing] = []
        let span = newCumulative - previousCumulative
        var index = startIndex
        while index <= newIndex && result.count < maxCrossingsPerUpdate {
            let thresholdValue = intervalValue * Double(index)
            let fraction: Double
            if span > 0 {
                fraction = min(max((thresholdValue - previousCumulative) / span, 0), 1)
            } else {
                fraction = 0
            }
            result.append(Crossing(
                thresholdIndex: index,
                thresholdValue: thresholdValue,
                interpolationFraction: fraction
            ))
            index += 1
        }
        return result
    }
}
