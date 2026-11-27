import CoreLocation
import Foundation
import HealthKit
import Observation
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
///
/// Crash and relaunch recovery lives in `WorkoutManager+Recovery.swift`,
/// finishing a workout in `WorkoutManager+Finishing.swift`, and the HealthKit
/// delegate callbacks in `WorkoutManager+Delegates.swift`. State they share
/// is internal rather than private for that reason.
@MainActor
@Observable
final class WorkoutManager: NSObject {
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

    nonisolated static let log = AppLogger.make(category: "WorkoutManager")

    private static let countdownSecondsKey = "startCountdownSeconds"

    /// Seconds counted down before a workout starts, saved on the watch.
    var countdownSeconds: Int {
        didSet {
            UserDefaults.standard.set(countdownSeconds, forKey: Self.countdownSecondsKey)
        }
    }

    var phase: Phase = .idle
    private(set) var activityType: WatchActivityType?
    var distanceMeters: Double?
    var heartRateBpm: Int?
    private(set) var locationAuthorization: CLAuthorizationStatus
    var errorMessage: String?

    @ObservationIgnored let healthStore = HKHealthStore()
    @ObservationIgnored let location = WorkoutLocationSource()
    @ObservationIgnored let store: WatchRecordingStore
    @ObservationIgnored let route: WorkoutRouteRecorder
    @ObservationIgnored var session: HKWorkoutSession?
    @ObservationIgnored var builder: HKLiveWorkoutBuilder?
    @ObservationIgnored var recording: WatchRecording?
    @ObservationIgnored private var pendingStart: (session: HKWorkoutSession, builder: HKLiveWorkoutBuilder, type: WatchActivityType)?
    @ObservationIgnored private var countdownTask: Task<Void, Never>?

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
        return WatchStorage.applicationSupportDirectory
            .appendingPathComponent("watch_recording", isDirectory: true)
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
        Self.log.error("Could not start a workout: \(error.localizedDescription, privacy: .private)")
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

    // MARK: - Session lifecycle

    func attach(
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

    func detach() {
        location.stop()
        session = nil
        builder = nil
        recording = nil
        route.reset()
    }

    func handle(state: HKWorkoutSessionState, date: Date) {
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

    // MARK: - Location

    private func record(_ locations: [CLLocation]) {
        guard phase == .running, let recording, !recording.isPaused else {
            return
        }
        route.record(locations, for: recording)
    }
}
