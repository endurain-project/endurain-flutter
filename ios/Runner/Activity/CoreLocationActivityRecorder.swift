import Foundation
import CoreLocation

/// CoreLocation-backed recorder that persists points to the native active store
/// before notifying Flutter.
///
/// Mirrors the Android `ActivityRecorderService` collection loop. The manager is
/// configured for background fitness tracking: background updates enabled,
/// automatic pausing disabled, the system background indicator shown, and the
/// `.fitness` activity type. Segment policy matches the Dart recorder: a new
/// segment starts after a pause/resume boundary or a large time gap between
/// fixes. Coordinates are never written to diagnostics.
final class CoreLocationActivityRecorder: NSObject, CLLocationManagerDelegate {
    /// Minimum movement (meters) between delivered fixes.
    private static let distanceFilterMeters: CLLocationDistance = 3

    /// Time gap (ms) beyond which a new track segment is started.
    private static let maxTimeGapMillis: Int64 = 30_000

    private let store: ActiveActivityStore
    private let manager = CLLocationManager()

    private var lastPointEpochMillis: Int64?
    private var resumedFromPause = false
    private var isCollecting = false

    init(store: ActiveActivityStore) {
        self.store = store
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = CoreLocationActivityRecorder.distanceFilterMeters
        manager.activityType = .fitness
        manager.pausesLocationUpdatesAutomatically = false
    }

    /// Starts (or resumes) location collection. Restores the last persisted
    /// point timestamp so gap-based segmentation survives an app restart.
    /// Returns false and emits a typed failure when location use is denied.
    @discardableResult
    func startCollection() -> Bool {
        let status = currentAuthorizationStatus()
        switch status {
        case .denied, .restricted:
            ActivityRecorderCoordinator.shared.emitFailed(
                ActivityRecorderCoordinator.reasonPermissionLost
            )
            return false
        case .notDetermined:
            // Background recording needs Always; request it and let the user
            // retry once the permission upgrade is complete.
            manager.requestAlwaysAuthorization()
            ActivityRecorderCoordinator.shared.emitFailed(
                ActivityRecorderCoordinator.reasonPermissionLost
            )
            return false
        case .authorizedWhenInUse:
            // "When In Use" cannot record while backgrounded; surface the
            // missing Always grant and request an upgrade for the next attempt.
            manager.requestAlwaysAuthorization()
            ActivityRecorderCoordinator.shared.emitFailed(
                ActivityRecorderCoordinator.reasonPermissionLost
            )
            return false
        default:
            break
        }

        if status == .authorizedAlways {
            manager.allowsBackgroundLocationUpdates = true
            manager.showsBackgroundLocationIndicator = true
        }

        lastPointEpochMillis = IsoTime.toEpochMillis(store.lastPoint()?.timestamp)
        manager.startUpdatingLocation()
        isCollecting = true
        return true
    }

    func stopCollection() {
        manager.stopUpdatingLocation()
        manager.allowsBackgroundLocationUpdates = false
        isCollecting = false
    }

    /// Marks that collection is resuming from a pause so the next fix opens a
    /// new segment, matching the Dart segment policy.
    func markResumed() {
        resumedFromPause = true
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard isCollecting, !locations.isEmpty else {
            return
        }
        guard
            let session = store.loadSession(),
            session.status == ActiveActivitySessionData.statusRecording
        else {
            return
        }

        var segmentIndex = session.currentSegmentIndex
        var segmentChanged = false
        var produced: [RecordedActivityPointData] = []

        for location in locations {
            let rawMillis = Int64(location.timestamp.timeIntervalSince1970 * 1000)
            let effectiveMillis = rawMillis > 0
                ? rawMillis
                : Int64(Date().timeIntervalSince1970 * 1000)

            if resumedFromPause {
                if lastPointEpochMillis != nil {
                    segmentIndex += 1
                    segmentChanged = true
                }
                resumedFromPause = false
            } else if let previous = lastPointEpochMillis,
                effectiveMillis - previous > CoreLocationActivityRecorder.maxTimeGapMillis {
                segmentIndex += 1
                segmentChanged = true
            }

            lastPointEpochMillis = effectiveMillis
            produced.append(makePoint(location, millis: effectiveMillis, segmentIndex: segmentIndex))
        }

        if produced.isEmpty {
            return
        }

        do {
            try store.appendPoints(produced)
        } catch {
            ActivityRecorderCoordinator.shared.emitFailed(
                ActivityRecorderCoordinator.reasonPersistenceFailed
            )
            return
        }

        if segmentChanged {
            store.saveSession(session.copyWith(currentSegmentIndex: segmentIndex))
        }

        ActivityRecorderCoordinator.shared.emitPointBatch(produced)
    }

    func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        // CoreLocation transient failures (e.g. no fix yet) should not abort the
        // recording. Only a hard denial is surfaced; report stream trouble
        // without leaking error specifics.
        if let clError = error as? CLError, clError.code == .denied {
            ActivityRecorderCoordinator.shared.emitFailed(
                ActivityRecorderCoordinator.reasonPermissionLost
            )
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard isCollecting else {
            return
        }
        switch currentAuthorizationStatus() {
        case .denied, .restricted:
            stopCollection()
            ActivityRecorderCoordinator.shared.emitFailed(
                ActivityRecorderCoordinator.reasonPermissionLost
            )
        case .authorizedWhenInUse:
            stopCollection()
            ActivityRecorderCoordinator.shared.emitFailed(
                ActivityRecorderCoordinator.reasonPermissionLost
            )
        case .authorizedAlways:
            manager.allowsBackgroundLocationUpdates = true
            manager.showsBackgroundLocationIndicator = true
        default:
            break
        }
    }

    // MARK: - Helpers

    private func currentAuthorizationStatus() -> CLAuthorizationStatus {
        if #available(iOS 14.0, *) {
            return manager.authorizationStatus
        }
        return CLLocationManager.authorizationStatus()
    }

    private func makePoint(
        _ location: CLLocation,
        millis: Int64,
        segmentIndex: Int
    ) -> RecordedActivityPointData {
        let timestamp = IsoTime.format(Date(timeIntervalSince1970: Double(millis) / 1000))

        var headingAccuracy: Double?
        if #available(iOS 13.4, *), location.courseAccuracy >= 0 {
            headingAccuracy = location.courseAccuracy
        }

        return RecordedActivityPointData(
            timestamp: timestamp,
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
            headingAccuracyDegrees: headingAccuracy,
            speedMetersPerSecond: location.speed >= 0 ? location.speed : nil,
            speedAccuracyMetersPerSecond: location.speedAccuracy >= 0
                ? location.speedAccuracy
                : nil
        )
    }
}
