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
///
/// The track is kept by [WorkoutRouteRecorder], the GPS stream by
/// [WorkoutLocationSource], and the HealthKit mapping by [WorkoutHealthKit].
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
    private let location = WorkoutLocationSource()
    private let store: WatchRecordingStore
    private let route: WorkoutRouteRecorder
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private var recording: WatchRecording?
    private var pendingStart: (session: HKWorkoutSession, builder: HKLiveWorkoutBuilder, type: WatchActivityType)?
    private var countdownTask: Task<Void, Never>?

    init(store: WatchRecordingStore = WatchRecordingStore(directory: WorkoutManager.defaultRecordingDirectory())) {
        self.store = store
        self.route = WorkoutRouteRecorder(healthStore: healthStore, store: store)
        self.locationAuthorization = location.authorizationStatus
        let savedCountdown = UserDefaults.standard.integer(forKey: Self.countdownSecondsKey)
        self.countdownSeconds = WorkoutCountdown.options.contains(savedCountdown) ? savedCountdown : 0
        super.init()
        location.onLocations = { [weak self] locations in
            self?.record(locations)
        }
        location.onAuthorizationChange = { [weak self] status in
            self?.locationAuthorization = status
        }
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
            try await WorkoutHealthKit.requestAuthorization(healthStore)
            location.requestAuthorizationIfNeeded()
            let configuration = WorkoutHealthKit.configuration(for: type)
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
        guard case .countingDown = phase, let expected = pendingStart?.session else { return }
        countdownTask?.cancel()
        countdownTask = nil
        // Bound to this countdown: if it is cancelled and another one starts
        // before the task runs, the task must not start the new one early.
        Task { await finishCountdown(expecting: expected) }
    }

    /// Stops the countdown without recording anything.
    func cancelCountdown() {
        guard case .countingDown = phase else { return }
        countdownTask?.cancel()
        countdownTask = nil
        pendingStart?.session.end()
        pendingStart = nil
        location.stop()
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
        location.start()
        let endsAt = Date().addingTimeInterval(TimeInterval(countdownSeconds))
        phase = .countingDown(endsAt: endsAt)
        countdownTask = Task { [weak self] in
            await self?.runCountdown(until: endsAt)
        }
    }

    private func runCountdown(until endsAt: Date) async {
        await WorkoutCountdown.run(until: endsAt)
        guard !Task.isCancelled else { return }
        countdownTask = nil
        await finishCountdown()
    }

    private func finishCountdown(expecting expected: HKWorkoutSession? = nil) async {
        guard case .countingDown = phase, let pending = pendingStart else { return }
        if let expected, pending.session !== expected { return }
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
        location.start()
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
    ///
    /// A failed recovery query says nothing about whether HealthKit still
    /// runs the workout, and finishing it then could save a second,
    /// overlapping one. The stored recording is kept for the next launch.
    func restoreUnfinishedRecording() {
        guard session == nil, phase == .idle, let saved = store.load() else {
            return
        }
        healthStore.recoverActiveWorkoutSession { [weak self] recovered, error in
            Task { @MainActor in
                guard let self, self.session == nil else { return }
                if let recovered {
                    self.adopt(recovered, saved: saved)
                } else if let error {
                    NSLog(
                        "Endurain watch: could not check for a running workout: %@",
                        error.localizedDescription
                    )
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
                activityType: WorkoutHealthKit.activityType(for: session.workoutConfiguration),
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
            location.start()
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
        activityType = recording.activityType
        distanceMeters = nil
        heartRateBpm = nil
        route.begin(with: points)
    }

    private func detach() {
        location.stop()
        session = nil
        builder = nil
        recording = nil
        route.reset()
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
            location.start()
        case .paused:
            route.flush()
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
        location.stop()
        route.flush()

        var elapsed = recording.elapsedSeconds(at: endDate)
        var healthWorkoutId: String?
        if let builder {
            do {
                try await builder.endCollection(at: endDate)
                elapsed = builder.elapsedTime
                if let workout = try await builder.finishWorkout() {
                    healthWorkoutId = workout.uuid.uuidString
                    await route.finishRoute(with: workout)
                }
            } catch {
                // Saving to HealthKit is not required to keep the workout:
                // Endurain still gets it below.
                NSLog("Endurain watch: could not save the workout to Health: %@", error.localizedDescription)
            }
        }

        let recordedPoints = route.points
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

    private func record(_ locations: [CLLocation]) {
        guard phase == .running, let recording, !recording.isPaused else {
            return
        }
        route.record(locations, for: recording)
    }

    private func persistRecording() {
        guard let recording else { return }
        do {
            try store.update(recording)
        } catch {
            NSLog("Endurain watch: could not save the workout state")
        }
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
                self.route.noteHeartRate(bpm, at: now)
            }
            if let distance {
                self.distanceMeters = distance
            }
        }
    }
}
