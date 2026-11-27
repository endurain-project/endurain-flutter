import CoreLocation
import Foundation

/// Which Core Location fixes join the track, and how a fix becomes a stored
/// point.
///
/// Pure functions of the fix and the recorder's timing, kept apart from
/// `CoreLocationActivityRecorder` so the rules can be tested without a
/// location manager.
enum LocationFixPolicy {
    /// Time gap (ms) beyond which a new track segment is started.
    static let maxTimeGapMillis: Int64 = 30_000
    static let maxAccuracyMeters: CLLocationAccuracy = 100
    static let maxSpeedMetersPerSecond: CLLocationSpeed = 90

    /// Minimum movement (meters) between the points the recorder stores while
    /// auto-pause is off. The live update stream delivers every fix; this
    /// keeps a slow or standing recording from storing near-duplicate points.
    /// With auto-pause on, every usable fix is stored, because the auto-pause
    /// detector needs a steady flow of fixes to time stillness.
    static let distanceFilterMeters: CLLocationDistance = 3

    /// Slack (ms) allowed between a fix's timestamp and the collection
    /// (re)start it must not predate, for clock rounding between the fix and
    /// `Date()`.
    static let staleFixToleranceMillis: Int64 = 2_000

    /// Maximum age (ms) of the first fix accepted after a collection
    /// (re)start. Core Location can hand over a cached location first, whose
    /// stale position would otherwise add distance that was never covered.
    static let maxFirstFixAgeMillis: Int64 = 10_000

    /// Whether a fix belongs to the current active period rather than being
    /// a cached position Core Location delivered on (re)start.
    static func isFreshFix(
        timestampMillis: Int64,
        nowMillis: Int64,
        collectionStartedAtMillis: Int64,
        isFirstFix: Bool
    ) -> Bool {
        if timestampMillis < collectionStartedAtMillis - staleFixToleranceMillis {
            return false
        }
        if isFirstFix && nowMillis - timestampMillis > maxFirstFixAgeMillis {
            return false
        }
        return true
    }

    /// Whether [location] is closer than `distanceFilterMeters` to
    /// [previous], the fix of the last stored point.
    static func isWithinDistanceFilter(_ location: CLLocation, of previous: CLLocation?) -> Bool {
        guard let previous else {
            return false
        }
        return location.distance(from: previous) < distanceFilterMeters
    }

    /// Whether a fix's horizontal accuracy is valid and good enough for the
    /// track. A negative accuracy means the coordinate is invalid.
    static func hasUsableAccuracy(_ horizontalAccuracy: CLLocationAccuracy) -> Bool {
        return horizontalAccuracy >= 0 && horizontalAccuracy <= maxAccuracyMeters
    }

    /// The fix's timestamp in epoch milliseconds, or 0 when it has none.
    static func timestampMillis(_ location: CLLocation) -> Int64 {
        return Int64(location.timestamp.timeIntervalSince1970 * 1000)
    }

    /// The time a fix is recorded at: its own timestamp, or now when it has
    /// none.
    static func effectiveMillis(_ location: CLLocation) -> Int64 {
        let rawMillis = timestampMillis(location)
        return rawMillis > 0 ? rawMillis : nowMillis()
    }

    static func nowMillis() -> Int64 {
        return Int64(Date().timeIntervalSince1970 * 1000)
    }

    static func movementSample(_ location: CLLocation, millis: Int64) -> MovementSample {
        return MovementSample(
            timestampMillis: millis,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            speedMetersPerSecond: location.speed >= 0 ? location.speed : nil,
            horizontalAccuracyMeters: location.horizontalAccuracy >= 0
                ? location.horizontalAccuracy
                : nil
        )
    }

    static func makePoint(
        _ location: CLLocation,
        millis: Int64,
        segmentIndex: Int,
        heartRateBpm: Int?
    ) -> RecordedActivityPointData {
        let date = Date(timeIntervalSince1970: Double(millis) / 1000)
        return RecordedActivityPointData(
            timestamp: IsoTime.format(date),
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            segmentIndex: segmentIndex,
            elevationMeters: location.verticalAccuracy >= 0 ? location.altitude : nil,
            horizontalAccuracyMeters: location.horizontalAccuracy >= 0
                ? location.horizontalAccuracy
                : nil,
            verticalAccuracyMeters: location.verticalAccuracy >= 0
                ? location.verticalAccuracy
                : nil,
            headingDegrees: location.course >= 0 ? location.course : nil,
            headingAccuracyDegrees: location.courseAccuracy >= 0 ? location.courseAccuracy : nil,
            speedMetersPerSecond: location.speed >= 0 ? location.speed : nil,
            speedAccuracyMetersPerSecond: location.speedAccuracy >= 0
                ? location.speedAccuracy
                : nil,
            // Power and cadence are stamped by the Dart layer on this platform
            // (see `CoreLocationActivityRecorder`), so they are nil here.
            heartRateBpm: heartRateBpm,
            powerWatts: nil,
            cadenceRpm: nil
        )
    }
}

/// Decides which segment each accepted fix belongs to: a new one after a
/// pause/resume boundary or a long gap between fixes, matching the Dart
/// recorder's segment policy.
struct TrackSegmenter {
    /// When the last stored point was recorded, restored from the store on
    /// every collection start so segmentation survives an app restart.
    var lastPointEpochMillis: Int64?

    /// Whether the next stored point follows a pause and so opens a segment.
    var resumedFromPause = false

    /// Whether a fix implies an impossible speed since the last point.
    func isImplausible(millis: Int64, speed: CLLocationSpeed) -> Bool {
        guard let previous = lastPointEpochMillis, millis > previous else {
            return false
        }
        return speed >= 0 && speed > LocationFixPolicy.maxSpeedMetersPerSecond
    }

    /// The segment of a point recorded at [millis], given the session's
    /// current segment, and whether it opens a new one.
    mutating func segment(
        forPointAt millis: Int64,
        currentSegmentIndex: Int
    ) -> (index: Int, isNew: Bool) {
        var index = currentSegmentIndex
        var isNew = false
        if resumedFromPause {
            if lastPointEpochMillis != nil {
                index += 1
                isNew = true
            }
            resumedFromPause = false
        } else if let previous = lastPointEpochMillis,
                  millis - previous > LocationFixPolicy.maxTimeGapMillis {
            index += 1
            isNew = true
        }
        lastPointEpochMillis = millis
        return (index, isNew)
    }
}
