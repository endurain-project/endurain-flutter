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
///
/// **External sensors are owned by Dart on this platform.** Unlike Android —
/// where the foreground service takes over the BLE connection because a
/// backgrounded Dart isolate cannot hold one reliably — iOS keeps the
/// `universal_ble` connection alive through the `bluetooth-central` background
/// mode. `ActivityRecordingService` persists readings in the native sensor log
/// and stamps them onto points when draining, and `hrDeviceId`/`powerDeviceId`/`cadenceDeviceId`
/// are never sent to this recorder. Points written here leave power and
/// cadence nil by design; do not add a second CoreBluetooth connection here
/// without first removing the Dart-side one, or the two will fight over the
/// same peripheral's notifications.
///
/// Heart rate is the exception: on iOS 26+ `HealthKitHeartRateMonitor` fills
/// it from HealthKit (e.g. AirPods Pro 3), and a BLE reading stamped by Dart
/// still takes priority.
///
/// The fix rules live in `LocationFixPolicy` and `TrackSegmenter`, and spoken
/// progress in `ActivityAnnouncementController`.
@MainActor
final class CoreLocationActivityRecorder:
    NSObject,
    @preconcurrency CLLocationManagerDelegate {
    /// Minimum movement (meters) between delivered fixes.
    private static let distanceFilterMeters: CLLocationDistance = 3

    private let store: ActiveActivityStore
    private let manager: CLLocationManager
    private let announcements: ActivityAnnouncementController
    private let heartRateMonitor: HealthKitHeartRateMonitor

    private var segmenter = TrackSegmenter()
    private var isCollecting = false
    /// When the current active period started collecting; fixes older than
    /// this are cached positions, not part of the recording.
    private var collectionStartedAtMillis: Int64 = 0
    /// Whether no fix has been accepted since the collection (re)started.
    private var awaitingFirstFix = true
    private var autoPauseDetector: MovementAutoPauseDetector?
    private var nextPointOffset = 0

    init(
        store: ActiveActivityStore,
        manager: CLLocationManager = CLLocationManager(),
        heartRateMonitor: HealthKitHeartRateMonitor? = nil
    ) {
        self.store = store
        self.manager = manager
        self.announcements = ActivityAnnouncementController(store: store)
        self.heartRateMonitor = heartRateMonitor ?? HealthKitHeartRateMonitor()
        super.init()
        announcements.isCollecting = { [weak self] in self?.isCollecting ?? false }
        // HealthKit readings join the sensor log so Dart matches the nearest
        // reading to each point and can show it live while standing still.
        self.heartRateMonitor.onSample = { [weak self] bpm, date in
            guard let self,
                  let sessionId = self.store.loadSession()?.localSessionId else {
                return
            }
            try? self.store.appendSensorSample(
                RecordedSensorSampleData(
                    kind: "heartRate",
                    timestamp: IsoTime.format(date),
                    value: bpm
                ),
                localSessionId: sessionId
            )
        }
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
        if isCollecting {
            return true
        }
        let status = currentAuthorizationStatus()
        switch status {
        case .denied, .restricted:
            ActivityRecorderCoordinator.shared.emitFailed(
                ActivityRecorderCoordinator.reasonPermissionLost
            )
            return false
        case .notDetermined:
            // Request Always and let the user retry once it is answered.
            manager.requestAlwaysAuthorization()
            ActivityRecorderCoordinator.shared.emitFailed(
                ActivityRecorderCoordinator.reasonPermissionLost
            )
            return false
        default:
            break
        }

        // Both grants keep recording in the background: with the `location`
        // background mode, updates started in the foreground continue after
        // the app is backgrounded even under When In Use. Only the relaunch
        // after termination needs Always (see `startTerminationRecovery`).
        manager.allowsBackgroundLocationUpdates = true
        manager.showsBackgroundLocationIndicator = true

        announcements.restore()
        segmenter.lastPointEpochMillis = IsoTime.toEpochMillis(store.lastPoint()?.timestamp)
        let session = store.loadSession()
        manager.distanceFilter = session?.autoPauseEnabled == true
            ? kCLDistanceFilterNone
            : CoreLocationActivityRecorder.distanceFilterMeters
        let nowMillis = LocationFixPolicy.nowMillis()
        autoPauseDetector = MovementAutoPauseDetector(config: MovementAutoPauseConfig(
            enabled: session?.autoPauseEnabled ?? false,
            pauseDelayMillis: Int64((session?.autoPauseDelaySeconds ?? 5)) * 1000
        ))
        // Anchor stillness to this collection (re)start, not the last stored
        // point: that point can predate a manual pause, which would let the
        // first slow fix auto-pause immediately.
        autoPauseDetector?.reset(movementAtMillis: nowMillis)
        markCollectionStarted(atMillis: nowMillis)
        nextPointOffset = store.pointCount()
        manager.startUpdatingLocation()
        startTerminationRecovery()
        heartRateMonitor.start(activityType: session?.activityType ?? "other")
        isCollecting = true
        announcements.scheduleNextTimeAnnouncement()
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
    /// Requires Always authorization: under When In Use the recording
    /// continues in the background but cannot be relaunched after
    /// termination, so the monitoring is not armed.
    private func startTerminationRecovery() {
        guard currentAuthorizationStatus() == .authorizedAlways,
              CLLocationManager.significantLocationChangeMonitoringAvailable() else {
            return
        }
        manager.startMonitoringSignificantLocationChanges()
    }

    /// Re-arms collection after the process was relaunched (for example by
    /// iOS for a significant location change) while a recording session that
    /// needs location monitoring is still active on disk.
    ///
    /// Returns `true` when a recording was resumed. Called from `AppDelegate`
    /// on every launch, independent of the Flutter engine: scene-based apps
    /// cannot rely on the `.location` launch option. Idempotent, and a no-op
    /// without such a session or while already collecting; a later Dart
    /// `recover` then reports the live session without restarting it.
    @discardableResult
    func resumeAfterRelaunch() -> Bool {
        guard !isCollecting else {
            return false
        }
        guard
            let session = store.loadSession(),
            session.requiresLocationMonitoring
        else {
            return false
        }
        return recoverActiveSession()?.requiresLocationMonitoring == true
            && isCollecting
    }

    func recoverActiveSession() -> ActiveActivitySessionData? {
        guard let session = store.loadSession() else {
            return nil
        }
        if session.status == ActiveActivitySessionData.statusFailed {
            let paused = session.copyWith(
                status: ActiveActivitySessionData.statusPaused,
                pausedAt: .some(IsoTime.nowUtc()),
                endedAt: .some(nil)
            )
            guard store.saveSession(paused) else {
                return session
            }
            stopCollection()
            return paused
        }
        guard session.requiresLocationMonitoring, !isCollecting else {
            return session
        }
        let recovered = SessionTiming.afterInterruption(
            session,
            lastPointMillis: IsoTime.toEpochMillis(store.lastPoint()?.timestamp),
            nowMillis: LocationFixPolicy.nowMillis()
        )
        guard store.saveSession(recovered) else {
            return session.copyWith(status: ActiveActivitySessionData.statusFailed)
        }
        segmenter.resumedFromPause = recovered.status == ActiveActivitySessionData.statusRecording
            && store.lastPoint() != nil
        if !startCollection() {
            let paused = recovered.copyWith(
                status: ActiveActivitySessionData.statusPaused,
                pausedAt: .some(IsoTime.nowUtc())
            )
            store.saveSession(paused)
            return paused
        }
        return recovered
    }

    func stopCollection() {
        announcements.flush()
        announcements.cancelTimeAnnouncement()
        manager.stopUpdatingLocation()
        manager.stopMonitoringSignificantLocationChanges()
        manager.allowsBackgroundLocationUpdates = false
        heartRateMonitor.stop()
        AudioAnnouncer.shared.stop()
        isCollecting = false
        // A manual pause reaches here and must stop monitoring movement
        // entirely, so a manually paused recording can never auto-resume;
        // `startCollection` always rebuilds a fresh detector for the next
        // active period.
        autoPauseDetector = nil
    }

    func stopAfterPersistenceFailure() {
        stopCollection()
        persistFailure()
        ActivityRecorderCoordinator.shared.emitFailed(
            ActivityRecorderCoordinator.reasonPersistenceFailed
        )
    }

    /// Whether a time-based announcement is scheduled. Exposed for tests.
    var isTimeAnnouncementScheduled: Bool {
        return announcements.isTimeAnnouncementScheduled
    }

    /// Resumes collection after a manual resume, from either a manual pause
    /// (collection stopped) or an automatic one (still collecting). The next
    /// fix opens a new segment, matching the Dart segment policy.
    ///
    /// While auto-paused, Core Location never stopped, so `startCollection`
    /// alone would be a no-op: the detector would keep its pre-pause movement
    /// history and auto-pause again on the next fix, and the time
    /// announcements cancelled by the auto-pause would never be rescheduled.
    @discardableResult
    func resumeCollection(nowMillis: Int64) -> Bool {
        segmenter.resumedFromPause = true
        guard isCollecting else {
            return startCollection()
        }
        autoPauseDetector?.reset(movementAtMillis: nowMillis)
        markCollectionStarted(atMillis: nowMillis)
        announcements.scheduleNextTimeAnnouncement()
        return true
    }

    private func markCollectionStarted(atMillis millis: Int64) {
        collectionStartedAtMillis = millis
        awaitingFirstFix = true
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard isCollecting, !locations.isEmpty else {
            return
        }
        for location in locations {
            guard isCollecting else {
                // A failure earlier in this batch already stopped collection.
                return
            }
            handleLocationFix(location)
        }
    }

    private func handleLocationFix(_ location: CLLocation) {
        let nowMillis = LocationFixPolicy.nowMillis()
        let rawMillis = LocationFixPolicy.timestampMillis(location)
        // Checked before the auto-pause detector too: a stale position fed
        // to it would read as displacement against the next real fix.
        guard rawMillis <= 0 || LocationFixPolicy.isFreshFix(
            timestampMillis: rawMillis,
            nowMillis: nowMillis,
            collectionStartedAtMillis: collectionStartedAtMillis,
            isFirstFix: awaitingFirstFix
        ) else {
            return
        }
        awaitingFirstFix = false
        guard let session = store.loadSession() else {
            return
        }
        if session.status == ActiveActivitySessionData.statusRecording {
            handleActiveLocationFix(session, location)
        } else if session.status == ActiveActivitySessionData.statusPaused,
            session.pausedAutomatically {
            // A manual pause stops Core Location entirely (see
            // `stopCollection`), so only an auto-paused session can still be
            // receiving fixes here.
            handleAutoPausedLocationFix(session, location)
        }
    }

    private func handleActiveLocationFix(
        _ session: ActiveActivitySessionData,
        _ location: CLLocation
    ) {
        let effectiveMillis = LocationFixPolicy.effectiveMillis(location)

        // Feed the auto-pause detector before the accuracy/speed gates below,
        // so stillness timing advances from wall-clock progress on every fix
        // (including noisy ones the detector itself discounts as movement
        // evidence), matching the Android/Dart recorders.
        let sample = LocationFixPolicy.movementSample(location, millis: effectiveMillis)
        let transition: MovementAutoPauseTransition
        if let detector = autoPauseDetector {
            transition = detector.onActivePoint(sample)
        } else {
            transition = .none
        }
        if case .autoPause = transition {
            transitionToAutoPaused(session, nowMillis: effectiveMillis)
            return
        }

        guard LocationFixPolicy.hasUsableAccuracy(location.horizontalAccuracy),
              !segmenter.isImplausible(millis: effectiveMillis, speed: location.speed)
        else {
            return
        }

        let (segmentIndex, isNewSegment) = segmenter.segment(
            forPointAt: effectiveMillis,
            currentSegmentIndex: session.currentSegmentIndex
        )
        let point = LocationFixPolicy.makePoint(
            location,
            millis: effectiveMillis,
            segmentIndex: segmentIndex,
            heartRateBpm: heartRateMonitor.heartRateBpm(
                at: Date(timeIntervalSince1970: Double(effectiveMillis) / 1000)
            )
        )

        // Persist the advanced segment index before the point so session
        // metadata is never behind the stored points across a crash/restart
        // boundary. A crash between the two only leaves the session one
        // segment ahead of an unwritten point, which recovery continues
        // cleanly.
        if isNewSegment {
            guard store.saveSession(session.copyWith(currentSegmentIndex: segmentIndex)) else {
                stopCollection()
                return
            }
        }

        do {
            try store.appendPoints([point])
        } catch {
            stopAfterPersistenceFailure()
            return
        }

        ActivityRecorderCoordinator.shared.emitPointBatch(
            [point],
            localSessionId: session.localSessionId,
            pointOffset: nextPointOffset
        )
        nextPointOffset += 1
        announcements.announce([point], isNewSegmentFlags: [isNewSegment], session: session)
    }

    /// Feeds a fix received while auto-paused. Core Location keeps running
    /// (never stopped for an automatic pause) so movement can resume the
    /// recording without user interaction, but no point is persisted until
    /// hysteresis confirms movement has resumed.
    private func handleAutoPausedLocationFix(
        _ session: ActiveActivitySessionData,
        _ location: CLLocation
    ) {
        guard let detector = autoPauseDetector else {
            return
        }
        let effectiveMillis = LocationFixPolicy.effectiveMillis(location)
        let transition = detector.onAutoPausedPoint(
            LocationFixPolicy.movementSample(location, millis: effectiveMillis)
        )
        guard case .autoResume = transition else {
            return
        }
        let resumed = session.copyWith(
            status: ActiveActivitySessionData.statusRecording,
            resumedAt: .some(IsoTime.format(Date(timeIntervalSince1970: Double(effectiveMillis) / 1000))),
            pausedAt: .some(nil),
            pausedAutomatically: false
        )
        guard store.saveSession(resumed) else {
            stopAfterPersistenceFailure()
            return
        }
        segmenter.resumedFromPause = true
        ActivityRecorderCoordinator.shared.emitSession(
            type: ActivityRecorderCoordinator.eventAutoResumed,
            session: resumed
        )
        // Queue the state cue before this fix can enqueue a progress update.
        announcements.speakTransitionCue(autoPaused: false)
        // Persist this same triggering fix as the first point of the new
        // segment, matching the manual resume flow (`resumedFromPause` forces
        // a segment break above).
        handleActiveLocationFix(resumed, location)
        announcements.scheduleNextTimeAnnouncement()
    }

    private func transitionToAutoPaused(_ session: ActiveActivitySessionData, nowMillis: Int64) {
        // Back-date the pause to when movement last stopped so the stillness
        // delay is not counted as recorded time.
        let anchorMillis = IsoTime.toEpochMillis(session.resumedAt ?? session.startedAt)
        var pausedAtMillis = min(autoPauseDetector?.lastMovementAtMillis ?? nowMillis, nowMillis)
        if let anchorMillis = anchorMillis {
            pausedAtMillis = max(pausedAtMillis, min(anchorMillis, nowMillis))
        }
        let paused = session.copyWith(
            status: ActiveActivitySessionData.statusPaused,
            pausedAt: .some(IsoTime.format(Date(timeIntervalSince1970: Double(pausedAtMillis) / 1000))),
            elapsedDurationSeconds: session.elapsedSecondsAt(pausedAtMillis),
            pausedAutomatically: true
        )
        guard store.saveSession(paused) else {
            stopAfterPersistenceFailure()
            return
        }
        ActivityRecorderCoordinator.shared.emitSession(
            type: ActivityRecorderCoordinator.eventAutoPaused,
            session: paused
        )
        // Cancel queued progress speech before announcing the state change.
        AudioAnnouncer.shared.stop()
        announcements.speakTransitionCue(autoPaused: true)
        announcements.flush()
        announcements.cancelTimeAnnouncement()
        // Deliberately does not call `stopCollection()`: an automatic pause
        // must keep monitoring location so movement can resume the recording
        // without user interaction, unlike a manual pause which stops
        // collection entirely (see `stopCollection`).
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
            // A downgrade from Always keeps the running updates, including in
            // the background; only the relaunch after termination is lost.
            manager.stopMonitoringSignificantLocationChanges()
        case .authorizedAlways:
            manager.allowsBackgroundLocationUpdates = true
            manager.showsBackgroundLocationIndicator = true
            startTerminationRecovery()
        default:
            break
        }
    }

    // MARK: - Helpers

    /// Persists `statusFailed` so recovery requires explicit user action even
    /// if the failure event was dropped while Flutter was suspended.
    private func persistFailure() {
        guard let session = store.loadSession(), session.isActive else {
            return
        }
        let nowMillis = LocationFixPolicy.nowMillis()
        store.saveSession(session.copyWith(
            status: ActiveActivitySessionData.statusFailed,
            pausedAt: .some(IsoTime.nowUtc()),
            elapsedDurationSeconds: SessionTiming.elapsedSeconds(session, referenceMillis: nowMillis)
        ))
    }

    private func currentAuthorizationStatus() -> CLAuthorizationStatus {
        return manager.authorizationStatus
    }
}
