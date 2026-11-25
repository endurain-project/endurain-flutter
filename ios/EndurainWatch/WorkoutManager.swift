import CoreLocation
import Foundation
import HealthKit
import WatchKit

/// Records one outdoor workout on the watch and hands it to the iPhone.
///
/// An `HKWorkoutSession` keeps the app running for the whole workout and its
/// live builder collects heart rate, distance and energy; the finished
/// workout and its route are saved to HealthKit like any watch workout. GPS
/// fixes come from Core Location and are written to a durable
/// [WatchRecordingStore] as they arrive, so a crash costs at most a few
/// seconds of track. On finish the session is turned into a handoff envelope
/// and queued in [PhoneLink]'s outbox.
@MainActor
final class WorkoutManager: NSObject, ObservableObject {
    static let shared = WorkoutManager()

    enum Phase: Equatable {
        case idle
        case starting
        /// Counting down to the start. The session is prepared (which keeps
        /// the app running and warms up the sensors) but nothing records yet.
        case countingDown(endsAt: Date)
        case running
        case paused
        case ending
        case finished(Summary)
    }

    struct Summary: Equatable {
        let activityType: WatchActivityType
        let elapsedSeconds: TimeInterval
        let distanceMeters: Double?
        let hasRoute: Bool
    }

    /// GPS fixes less accurate than this are not recorded.
    static let maxHorizontalAccuracyMeters: CLLocationAccuracy = 50

    /// A heart rate reading older than this is not attached to a point.
    static let heartRateFreshness: TimeInterval = 10

    /// Points are written to disk in batches of this size.
    static let pointFlushThreshold = 10

    /// Start countdown choices in seconds; 0 starts right away.
    static let countdownOptions = [0, 3, 5, 10]

    /// The last seconds of the countdown that tap the wrist.
    static let countdownCueSeconds = 3

    private static let countdownSecondsKey = "startCountdownSeconds"

    /// Seconds counted down before a workout starts, saved on the watch.
    @Published var countdownSeconds: Int {
        didSet {
            UserDefaults.standard.set(countdownSeconds, forKey: Self.countdownSecondsKey)
        }
    }

    @Published private(set) var phase: Phase = .idle
    @Published private(set) var activityType: WatchActivityType?
    @Published private(set) var distanceMeters: Double?
    @Published private(set) var heartRateBpm: Int?
    @Published private(set) var locationAuthorization: CLAuthorizationStatus
    @Published var errorMessage: String?

    private let healthStore = HKHealthStore()
    private let locationManager = CLLocationManager()
    private let store: WatchRecordingStore
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private var routeBuilder: HKWorkoutRouteBuilder?
    private var routeHasData = false
    private var recording: WatchRecording?
    private var points: [WatchRecordedPoint] = []
    private var unsavedPoints: [WatchRecordedPoint] = []
    private var lastHeartRate: (bpm: Int, at: Date)?
    private var isUpdatingLocation = false
    private var pendingStart: (session: HKWorkoutSession, builder: HKLiveWorkoutBuilder, type: WatchActivityType)?
    private var countdownTask: Task<Void, Never>?

    init(store: WatchRecordingStore = WatchRecordingStore(directory: WorkoutManager.defaultRecordingDirectory())) {
        self.store = store
        self.locationAuthorization = locationManager.authorizationStatus
        let savedCountdown = UserDefaults.standard.integer(forKey: Self.countdownSecondsKey)
        self.countdownSeconds = Self.countdownOptions.contains(savedCountdown) ? savedCountdown : 0
        super.init()
        locationManager.delegate = self
    }

    nonisolated static func defaultRecordingDirectory() -> URL {
        let support = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? FileManager.default.temporaryDirectory
        return support.appendingPathComponent("watch_recording", isDirectory: true)
    }

    /// Active (unpaused) seconds of the current workout as of [date].
    func elapsedSeconds(at date: Date) -> TimeInterval {
        return recording?.elapsedSeconds(at: date) ?? 0
    }

    var isLocationDenied: Bool {
        return locationAuthorization == .denied || locationAuthorization == .restricted
    }

    // MARK: - Controls

    func start(_ type: WatchActivityType) async {
        guard phase == .idle else { return }
        guard HKHealthStore.isHealthDataAvailable() else {
            errorMessage = String(localized: "Health data is not available on this watch.")
            return
        }
        phase = .starting
        var startedSession: HKWorkoutSession?
        do {
            try await requestHealthAuthorization()
            if locationManager.authorizationStatus == .notDetermined {
                locationManager.requestWhenInUseAuthorization()
            }
            let configuration = Self.configuration(for: type)
            let session = try HKWorkoutSession(
                healthStore: healthStore,
                configuration: configuration
            )
            startedSession = session
            let builder = session.associatedWorkoutBuilder()
            builder.dataSource = HKLiveWorkoutDataSource(
                healthStore: healthStore,
                workoutConfiguration: configuration
            )
            if countdownSeconds > 0 {
                beginCountdown(session: session, builder: builder, type: type)
                return
            }
            try await begin(session: session, builder: builder, type: type)
        } catch {
            failStart(session: startedSession, error: error)
        }
    }

    /// Starts the workout now instead of waiting for the countdown.
    func skipCountdown() {
        guard case .countingDown = phase else { return }
        countdownTask?.cancel()
        countdownTask = nil
        Task { await finishCountdown() }
    }

    /// Stops the countdown without recording anything.
    func cancelCountdown() {
        guard case .countingDown = phase else { return }
        countdownTask?.cancel()
        countdownTask = nil
        pendingStart?.session.end()
        pendingStart = nil
        stopLocationUpdates()
        activityType = nil
        phase = .idle
    }

    // MARK: - Countdown

    private func beginCountdown(
        session: HKWorkoutSession,
        builder: HKLiveWorkoutBuilder,
        type: WatchActivityType
    ) {
        pendingStart = (session, builder, type)
        activityType = type
        // A prepared session keeps the app running when the wrist is lowered
        // and warms up the sensors; collection only begins at zero.
        session.prepare()
        // Warm up GPS too. `record` ignores fixes until the workout runs.
        startLocationUpdates()
        let endsAt = Date().addingTimeInterval(TimeInterval(countdownSeconds))
        phase = .countingDown(endsAt: endsAt)
        countdownTask = Task { [weak self] in
            await self?.runCountdown(until: endsAt)
        }
    }

    private func runCountdown(until endsAt: Date) async {
        var lastCue: Int?
        while !Task.isCancelled {
            let left = endsAt.timeIntervalSinceNow
            if left <= 0 {
                break
            }
            let seconds = Int(left.rounded(.up))
            if seconds <= Self.countdownCueSeconds, seconds != lastCue {
                lastCue = seconds
                WKInterfaceDevice.current().play(.click)
            }
            try? await Task.sleep(for: .milliseconds(200))
        }
        guard !Task.isCancelled else { return }
        countdownTask = nil
        await finishCountdown()
    }

    private func finishCountdown() async {
        guard case .countingDown = phase, let pending = pendingStart else { return }
        pendingStart = nil
        phase = .starting
        do {
            try await begin(session: pending.session, builder: pending.builder, type: pending.type)
            WKInterfaceDevice.current().play(.start)
        } catch {
            failStart(session: pending.session, error: error)
        }
    }

    // MARK: - Starting

    private func begin(
        session: HKWorkoutSession,
        builder: HKLiveWorkoutBuilder,
        type: WatchActivityType
    ) async throws {
        let start = Date()
        let recording = WatchRecording(
            sessionId: UUID().uuidString,
            activityType: type,
            startedAt: start
        )
        try store.begin(recording)
        attach(session: session, builder: builder, recording: recording, points: [])
        session.startActivity(with: start)
        try await builder.beginCollection(at: start)
        phase = .running
        startLocationUpdates()
    }

    private func failStart(session: HKWorkoutSession?, error: Error) {
        NSLog("Endurain watch: could not start a workout: %@", error.localizedDescription)
        session?.end()
        store.clear()
        detach()
        phase = .idle
        errorMessage = String(localized: "The workout could not be started.")
    }

    func pause() {
        session?.pause()
    }

    func resume() {
        session?.resume()
    }

    func end() {
        guard let session, phase == .running || phase == .paused else { return }
        phase = .ending
        session.end()
    }

    func dismissSummary() {
        if case .finished = phase {
            phase = .idle
        }
    }

    // MARK: - Recovery

    /// Called at launch: resumes a workout that was running when the app was
    /// killed, or finishes and sends it when HealthKit no longer has it.
    func restoreUnfinishedRecording() {
        guard session == nil, phase == .idle, let saved = store.load() else {
            return
        }
        healthStore.recoverActiveWorkoutSession { [weak self] recovered, _ in
            Task { @MainActor in
                guard let self, self.session == nil else { return }
                if let recovered {
                    self.adopt(recovered, saved: saved)
                } else {
                    self.finishInterrupted(saved.recording, points: saved.points)
                }
            }
        }
    }

    /// Called by watchOS when it relaunched the app for a running workout.
    func recoverActiveWorkout() {
        guard session == nil else { return }
        healthStore.recoverActiveWorkoutSession { [weak self] recovered, _ in
            Task { @MainActor in
                guard let self, self.session == nil, let recovered else { return }
                self.adopt(recovered, saved: self.store.load())
            }
        }
    }

    private func adopt(
        _ session: HKWorkoutSession,
        saved: (recording: WatchRecording, points: [WatchRecordedPoint])?
    ) {
        if session.state == .prepared || session.state == .notStarted {
            // Left over from a countdown the app never finished: nothing was
            // recorded, so drop it rather than start a workout unasked.
            session.end()
            return
        }
        var recording: WatchRecording
        let savedPoints: [WatchRecordedPoint]
        if let saved {
            recording = saved.recording
            savedPoints = saved.points
        } else {
            // HealthKit kept a session the store never saw (a crash right
            // after it started): record it from here on.
            recording = WatchRecording(
                sessionId: UUID().uuidString,
                activityType: Self.activityType(for: session.workoutConfiguration),
                startedAt: session.startDate ?? Date()
            )
            try? store.begin(recording)
            savedPoints = []
        }
        let builder = session.associatedWorkoutBuilder()
        if builder.dataSource == nil {
            builder.dataSource = HKLiveWorkoutDataSource(
                healthStore: healthStore,
                workoutConfiguration: session.workoutConfiguration
            )
        }
        let now = Date()
        switch session.state {
        case .paused:
            recording.pause(at: now)
        case .running:
            recording.resume(at: now)
        default:
            break
        }
        try? store.update(recording)
        attach(session: session, builder: builder, recording: recording, points: savedPoints)

        switch session.state {
        case .paused:
            phase = .paused
        case .ended, .stopped:
            phase = .ending
            Task { await finish(at: session.endDate ?? now) }
        default:
            phase = .running
            startLocationUpdates()
        }
    }

    /// Sends a recording whose HealthKit session is gone. Its workout was
    /// never saved to HealthKit, so the handoff carries no health id.
    private func finishInterrupted(_ recording: WatchRecording, points: [WatchRecordedPoint]) {
        let end = WatchHandoffBuilder.endOfInterruptedRecording(recording, points: points)
        let elapsed = recording.elapsedSeconds(at: end)
        if points.isEmpty && elapsed < 1 {
            store.clear()
            return
        }
        enqueueHandoff(
            recording: recording,
            points: points,
            endedAt: end,
            elapsedSeconds: elapsed,
            healthWorkoutId: nil
        )
    }

    // MARK: - Session lifecycle

    private func attach(
        session: HKWorkoutSession,
        builder: HKLiveWorkoutBuilder,
        recording: WatchRecording,
        points: [WatchRecordedPoint]
    ) {
        self.session = session
        self.builder = builder
        session.delegate = self
        builder.delegate = self
        self.recording = recording
        self.points = points
        unsavedPoints = []
        activityType = recording.activityType
        distanceMeters = nil
        heartRateBpm = nil
        lastHeartRate = nil
        routeBuilder = HKWorkoutRouteBuilder(healthStore: healthStore, device: nil)
        routeHasData = false
        // A recovered workout starts a new route builder: re-insert the track
        // recorded before the relaunch so the saved route is complete.
        insertIntoRoute(points.map(Self.location(from:)))
    }

    private func detach() {
        stopLocationUpdates()
        session = nil
        builder = nil
        routeBuilder = nil
        routeHasData = false
        recording = nil
        points = []
        unsavedPoints = []
        lastHeartRate = nil
    }

    private func handle(state: HKWorkoutSessionState, date: Date) {
        switch state {
        case .running:
            if var recording, recording.isPaused {
                recording.resume(at: date)
                self.recording = recording
                persistRecording()
            }
            if phase == .paused || phase == .starting {
                phase = .running
            }
            startLocationUpdates()
        case .paused:
            flushPoints()
            if var recording {
                recording.pause(at: date)
                self.recording = recording
                persistRecording()
            }
            phase = .paused
        case .ended:
            Task { await finish(at: date) }
        default:
            break
        }
    }

    private func finish(at endDate: Date) async {
        guard let recording else {
            detach()
            phase = .idle
            return
        }
        stopLocationUpdates()
        flushPoints()

        var elapsed = recording.elapsedSeconds(at: endDate)
        var healthWorkoutId: String?
        if let builder {
            do {
                try await builder.endCollection(at: endDate)
                elapsed = builder.elapsedTime
                if let workout = try await builder.finishWorkout() {
                    healthWorkoutId = workout.uuid.uuidString
                    if routeHasData, let routeBuilder {
                        _ = try? await routeBuilder.finishRoute(with: workout, metadata: nil)
                    }
                }
            } catch {
                // Saving to HealthKit is not required to keep the workout:
                // Endurain still gets it below.
                NSLog("Endurain watch: could not save the workout to Health: %@", error.localizedDescription)
            }
        }

        let recordedPoints = points
        enqueueHandoff(
            recording: recording,
            points: recordedPoints,
            endedAt: endDate,
            elapsedSeconds: elapsed,
            healthWorkoutId: healthWorkoutId
        )
        let summary = Summary(
            activityType: recording.activityType,
            elapsedSeconds: elapsed,
            distanceMeters: distanceMeters,
            hasRoute: !recordedPoints.isEmpty
        )
        detach()
        phase = .finished(summary)
    }

    private func enqueueHandoff(
        recording: WatchRecording,
        points: [WatchRecordedPoint],
        endedAt: Date,
        elapsedSeconds: TimeInterval,
        healthWorkoutId: String?
    ) {
        do {
            let data = try WatchHandoffBuilder.data(
                recording: recording,
                points: points,
                endedAt: endedAt,
                elapsedSeconds: elapsedSeconds,
                healthWorkoutId: healthWorkoutId
            )
            try PhoneLink.shared.enqueue(data, sessionId: recording.sessionId)
            store.clear()
        } catch {
            // The recording stays on disk; the next launch finishes it again.
            NSLog("Endurain watch: could not queue the workout: %@", error.localizedDescription)
            errorMessage = String(localized: "The workout could not be queued for your iPhone. It will be retried.")
        }
    }

    // MARK: - Location

    private func startLocationUpdates() {
        guard !isUpdatingLocation else { return }
        isUpdatingLocation = true
        locationManager.activityType = .fitness
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.startUpdatingLocation()
    }

    private func stopLocationUpdates() {
        guard isUpdatingLocation else { return }
        isUpdatingLocation = false
        locationManager.stopUpdatingLocation()
    }

    private func record(_ locations: [CLLocation]) {
        guard phase == .running, let recording, !recording.isPaused else {
            return
        }
        let accepted = locations.filter { location in
            location.horizontalAccuracy >= 0
                && location.horizontalAccuracy <= Self.maxHorizontalAccuracyMeters
                && location.timestamp >= recording.startedAt
        }
        guard !accepted.isEmpty else { return }
        let newPoints = accepted.map { location in
            Self.point(
                from: location,
                segmentIndex: recording.segmentIndex,
                heartRateBpm: freshHeartRate(at: location.timestamp)
            )
        }
        points.append(contentsOf: newPoints)
        unsavedPoints.append(contentsOf: newPoints)
        insertIntoRoute(accepted)
        if unsavedPoints.count >= Self.pointFlushThreshold {
            flushPoints()
        }
    }

    private func freshHeartRate(at date: Date) -> Int? {
        guard let lastHeartRate,
              abs(date.timeIntervalSince(lastHeartRate.at)) <= Self.heartRateFreshness
        else {
            return nil
        }
        return lastHeartRate.bpm
    }

    private func insertIntoRoute(_ locations: [CLLocation]) {
        guard !locations.isEmpty, let routeBuilder else { return }
        routeHasData = true
        routeBuilder.insertRouteData(locations) { _, error in
            if let error {
                NSLog("Endurain watch: could not add to the workout route: %@", error.localizedDescription)
            }
        }
    }

    private func flushPoints() {
        guard !unsavedPoints.isEmpty else { return }
        do {
            try store.append(unsavedPoints)
            unsavedPoints = []
        } catch {
            // Kept in memory and retried with the next batch.
            NSLog("Endurain watch: could not save workout points")
        }
    }

    private func persistRecording() {
        guard let recording else { return }
        do {
            try store.update(recording)
        } catch {
            NSLog("Endurain watch: could not save the workout state")
        }
    }

    // MARK: - HealthKit

    private func requestHealthAuthorization() async throws {
        let share: Set<HKSampleType> = [
            HKObjectType.workoutType(),
            HKSeriesType.workoutRoute(),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.distanceWalkingRunning),
            HKQuantityType(.distanceCycling),
        ]
        let read: Set<HKObjectType> = [
            HKObjectType.workoutType(),
            HKQuantityType(.heartRate),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.distanceWalkingRunning),
            HKQuantityType(.distanceCycling),
        ]
        try await healthStore.requestAuthorization(toShare: share, read: read)
    }

    static func configuration(for type: WatchActivityType) -> HKWorkoutConfiguration {
        let configuration = HKWorkoutConfiguration()
        switch type {
        case .run:
            configuration.activityType = .running
        case .ride:
            configuration.activityType = .cycling
        case .walk:
            configuration.activityType = .walking
        case .hike:
            configuration.activityType = .hiking
        }
        configuration.locationType = .outdoor
        return configuration
    }

    static func activityType(for configuration: HKWorkoutConfiguration) -> WatchActivityType {
        switch configuration.activityType {
        case .cycling:
            return .ride
        case .walking:
            return .walk
        case .hiking:
            return .hike
        default:
            return .run
        }
    }

    static func point(
        from location: CLLocation,
        segmentIndex: Int,
        heartRateBpm: Int?
    ) -> WatchRecordedPoint {
        let hasAltitude = location.verticalAccuracy >= 0
        return WatchRecordedPoint(
            timestamp: location.timestamp,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            segmentIndex: segmentIndex,
            elevationMeters: hasAltitude ? location.altitude : nil,
            horizontalAccuracyMeters: location.horizontalAccuracy,
            verticalAccuracyMeters: hasAltitude ? location.verticalAccuracy : nil,
            headingDegrees: location.course >= 0 ? location.course : nil,
            speedMetersPerSecond: location.speed >= 0 ? location.speed : nil,
            speedAccuracyMetersPerSecond: location.speedAccuracy >= 0 ? location.speedAccuracy : nil,
            heartRateBpm: heartRateBpm
        )
    }

    static func location(from point: WatchRecordedPoint) -> CLLocation {
        return CLLocation(
            coordinate: CLLocationCoordinate2D(
                latitude: point.latitude,
                longitude: point.longitude
            ),
            altitude: point.elevationMeters ?? 0,
            horizontalAccuracy: point.horizontalAccuracyMeters ?? 10,
            verticalAccuracy: point.elevationMeters == nil ? -1 : (point.verticalAccuracyMeters ?? 10),
            course: point.headingDegrees ?? -1,
            speed: point.speedMetersPerSecond ?? -1,
            timestamp: point.timestamp
        )
    }
}

// MARK: - HKWorkoutSessionDelegate

extension WorkoutManager: HKWorkoutSessionDelegate {
    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {
        Task { @MainActor in
            self.handle(state: toState, date: date)
        }
    }

    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didFailWithError error: Error
    ) {
        NSLog("Endurain watch: the workout session failed: %@", error.localizedDescription)
        Task { @MainActor in
            self.errorMessage = String(localized: "The workout session stopped unexpectedly.")
        }
    }
}

// MARK: - HKLiveWorkoutBuilderDelegate

extension WorkoutManager: HKLiveWorkoutBuilderDelegate {
    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

    nonisolated func workoutBuilder(
        _ workoutBuilder: HKLiveWorkoutBuilder,
        didCollectDataOf collectedTypes: Set<HKSampleType>
    ) {
        let bpmUnit = HKUnit.count().unitDivided(by: .minute())
        let heartRate = workoutBuilder
            .statistics(for: HKQuantityType(.heartRate))?
            .mostRecentQuantity()?
            .doubleValue(for: bpmUnit)
        let distance = [HKQuantityType(.distanceWalkingRunning), HKQuantityType(.distanceCycling)]
            .compactMap { workoutBuilder.statistics(for: $0)?.sumQuantity()?.doubleValue(for: .meter()) }
            .max()
        let now = Date()
        Task { @MainActor in
            if let heartRate {
                let bpm = Int(heartRate.rounded())
                self.heartRateBpm = bpm
                self.lastHeartRate = (bpm, now)
            }
            if let distance {
                self.distanceMeters = distance
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension WorkoutManager: CLLocationManagerDelegate {
    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        Task { @MainActor in
            self.record(locations)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        NSLog("Endurain watch: location update failed: %@", error.localizedDescription)
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.locationAuthorization = status
        }
    }
}
