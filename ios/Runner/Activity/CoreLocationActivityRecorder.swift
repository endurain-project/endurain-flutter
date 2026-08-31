import Foundation
import CoreLocation
import Dispatch

/// CoreLocation-backed recorder that persists points to the native active store
/// before notifying Flutter.
///
/// Mirrors the Android `ActivityRecorderService` collection loop. The manager is
/// configured for background fitness tracking: background updates enabled,
/// automatic pausing disabled, the system background indicator shown, and the
/// `.fitness` activity type. Segment policy matches the Dart recorder: a new
/// segment starts after a pause/resume boundary or a large time gap between
/// fixes. Coordinates are never written to diagnostics.
///
/// **External sensors are owned by Dart on this platform.** Unlike Android —
/// where the foreground service takes over the BLE connection because a
/// backgrounded Dart isolate cannot hold one reliably — iOS keeps the
/// `universal_ble` connection alive through the `bluetooth-central` background
/// mode. `ActivityRecordingService` therefore streams readings in and stamps
/// them onto points itself, and `hrDeviceId`/`powerDeviceId`/`cadenceDeviceId`
/// are never sent to this recorder. Points written here leave the sensor fields
/// nil by design; do not add a second CoreBluetooth connection here without
/// first removing the Dart-side one, or the two will fight over the same
/// peripheral's notifications.
final class CoreLocationActivityRecorder: NSObject, CLLocationManagerDelegate {
    /// Minimum movement (meters) between delivered fixes.
    private static let distanceFilterMeters: CLLocationDistance = 3

    /// Time gap (ms) beyond which a new track segment is started.
    private static let maxTimeGapMillis: Int64 = 30_000
    private static let maxAccuracyMeters: CLLocationAccuracy = 100
    private static let maxSpeedMetersPerSecond: CLLocationSpeed = 90
    private static let minTimeAnnouncementIntervalSeconds = 60
    private static let maxTimeAnnouncementIntervalSeconds = 3600

    private let store: ActiveActivityStore
    private let manager = CLLocationManager()

    private var lastPointEpochMillis: Int64?
    private var resumedFromPause = false
    private var isCollecting = false
    private var timeAnnouncementTimer: DispatchSourceTimer?

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
        startTerminationRecovery()
        isCollecting = true
        scheduleNextTimeAnnouncement()
        return true
    }

    /// Arms significant-location-change monitoring for the duration of a
    /// recording.
    ///
    /// `startUpdatingLocation` alone does not survive the app being terminated
    /// under memory pressure: the process dies, updates stop, and the rest of
    /// the ride is lost silently. Significant-location-change is the only
    /// CoreLocation API that relaunches a terminated app in the background, so
    /// it is armed alongside the high-accuracy stream purely as a wake-up
    /// trigger. Its own coarse fixes are ignored for the track — see
    /// `AppDelegate` and `resumeAfterRelaunch()`, which re-arm the accurate
    /// stream once the process is back.
    ///
    /// Requires Always authorization, which `startCollection` has verified.
    private func startTerminationRecovery() {
        guard CLLocationManager.significantLocationChangeMonitoringAvailable() else {
            return
        }
        manager.startMonitoringSignificantLocationChanges()
    }

    /// Re-arms collection after iOS relaunched the app for a significant
    /// location change, when a recording session is still active on disk.
    ///
    /// Returns `true` when a recording was resumed. Called from `AppDelegate`
    /// on a location-triggered launch; a no-op for a normal user launch, where
    /// the Dart layer drives recovery through `recover`/`drain` instead.
    @discardableResult
    func resumeAfterRelaunch() -> Bool {
        guard !isCollecting else {
            return false
        }
        guard
            let session = store.loadSession(),
            session.status == ActiveActivitySessionData.statusRecording
        else {
            return false
        }
        return startCollection()
    }

    func stopCollection() {
        stopTimeAnnouncementTimer()
        manager.stopUpdatingLocation()
        manager.stopMonitoringSignificantLocationChanges()
        manager.allowsBackgroundLocationUpdates = false
        AudioAnnouncer.shared.stop()
        isCollecting = false
    }

    /// Schedules one main-queue callback at the next elapsed-time threshold.
    /// One-shot scheduling avoids polling and serializes state with GPS fixes.
    private func scheduleNextTimeAnnouncement() {
        stopTimeAnnouncementTimer()
        guard isCollecting,
              let announcementState = store.loadAnnouncementState(),
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
        let nowMillis = Int64(Date().timeIntervalSince1970 * 1000)
        let elapsedSeconds = SessionTiming.elapsedSeconds(
            session,
            referenceMillis: nowMillis
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
        let remainingSeconds = remainingResult.partialValue
        let delaySeconds = max(1, remainingSeconds)

        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + .seconds(Int(delaySeconds)))
        timer.setEventHandler { [weak self] in
            guard let self else {
                return
            }
            self.stopTimeAnnouncementTimer()
            self.announceTimeIfDue()
            self.scheduleNextTimeAnnouncement()
        }
        timeAnnouncementTimer = timer
        timer.resume()
    }

    private func stopTimeAnnouncementTimer() {
        timeAnnouncementTimer?.setEventHandler {}
        timeAnnouncementTimer?.cancel()
        timeAnnouncementTimer = nil
    }

    /// Advances a time-based schedule without waiting for another GPS fix.
    private func announceTimeIfDue() {
        guard isCollecting,
              let announcementState = store.loadAnnouncementState(),
              announcementState.enabled,
              announcementState.isTimeBased,
              let session = store.loadSession(),
              session.status == ActiveActivitySessionData.statusRecording else {
            return
        }
        let nowMillis = Int64(Date().timeIntervalSince1970 * 1000)
        let result = AnnouncementScheduler.onElapsedTime(
            state: announcementState,
            elapsedSeconds: SessionTiming.elapsedSeconds(
                session,
                referenceMillis: nowMillis
            )
        )
        guard result.state != announcementState else {
            return
        }
        guard store.saveAnnouncementState(result.state) else {
            return
        }
        for text in result.announcements {
            AudioAnnouncer.shared.speak(
                text,
                duck: announcementState.duckOtherAudio,
                languageTag: announcementState.languageTag
            )
        }
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
        var producedIsNewSegment: [Bool] = []

        for location in locations {
            guard location.horizontalAccuracy < 0 ||
                location.horizontalAccuracy <= CoreLocationActivityRecorder.maxAccuracyMeters
            else {
                continue
            }
            let rawMillis = Int64(location.timestamp.timeIntervalSince1970 * 1000)
            let effectiveMillis = rawMillis > 0
                ? rawMillis
                : Int64(Date().timeIntervalSince1970 * 1000)
            if let previous = lastPointEpochMillis,
                effectiveMillis > previous,
                location.speed >= 0,
                location.speed > CoreLocationActivityRecorder.maxSpeedMetersPerSecond {
                continue
            }

            var isNewSegment = false
            if resumedFromPause {
                if lastPointEpochMillis != nil {
                    segmentIndex += 1
                    segmentChanged = true
                    isNewSegment = true
                }
                resumedFromPause = false
            } else if let previous = lastPointEpochMillis,
                effectiveMillis - previous > CoreLocationActivityRecorder.maxTimeGapMillis {
                segmentIndex += 1
                segmentChanged = true
                isNewSegment = true
            }

            lastPointEpochMillis = effectiveMillis
            produced.append(makePoint(location, millis: effectiveMillis, segmentIndex: segmentIndex))
            producedIsNewSegment.append(isNewSegment)
        }

        if produced.isEmpty {
            return
        }

        // Persist the advanced segment index before the point batch so session
        // metadata is never behind the stored points across a crash/restart
        // boundary. A crash between the two only leaves the session one segment
        // ahead of an unwritten point, which recovery continues cleanly.
        if segmentChanged {
            store.saveSession(session.copyWith(currentSegmentIndex: segmentIndex))
        }

        do {
            try store.appendPoints(produced)
        } catch {
            stopCollection()
            persistFailure()
            ActivityRecorderCoordinator.shared.emitFailed(
                ActivityRecorderCoordinator.reasonPersistenceFailed
            )
            return
        }

        ActivityRecorderCoordinator.shared.emitPointBatch(produced)
        announceForBatch(produced, isNewSegmentFlags: producedIsNewSegment, session: session)
    }

    /// Advances the durable announcement scheduler by every point in this
    /// batch and speaks any threshold crossings triggered. Runs after the
    /// points are durably persisted, so a crash here can never lose recorded
    /// track data; a missing/unreadable announcement state (announcements
    /// never enabled, or the file could not be read) is a silent no-op.
    private func announceForBatch(
        _ points: [RecordedActivityPointData],
        isNewSegmentFlags: [Bool],
        session: ActiveActivitySessionData
    ) {
        guard var announcementState = store.loadAnnouncementState(), announcementState.enabled else {
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
        guard store.saveAnnouncementState(announcementState) else {
            return
        }
        for text in announcements {
            AudioAnnouncer.shared.speak(
                text,
                duck: announcementState.duckOtherAudio,
                languageTag: announcementState.languageTag
            )
        }
    }

    func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        // CoreLocation transient failures (e.g. no fix yet) should not abort the
        // recording. Only a hard denial is surfaced; report stream trouble
        // without leaking error specifics.
        if let clError = error as? CLError, clError.code == .denied {
            persistFailure()
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
            persistFailure()
            ActivityRecorderCoordinator.shared.emitFailed(
                ActivityRecorderCoordinator.reasonPermissionLost
            )
        case .authorizedWhenInUse:
            stopCollection()
            persistFailure()
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

    /// Persists `statusFailed` for any active session so Flutter sees a
    /// non-recoverable state on re-attach even if the failure event was dropped
    /// while Flutter was suspended.
    private func persistFailure() {
        guard let session = store.loadSession(), session.isActive else {
            return
        }
        store.saveSession(session.copyWith(status: ActiveActivitySessionData.statusFailed))
    }

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
                : nil,
            // Sensor values are stamped by the Dart layer on this platform
            // (see the type doc), so they are intentionally nil here.
            heartRateBpm: nil,
            powerWatts: nil,
            cadenceRpm: nil
        )
    }
}
