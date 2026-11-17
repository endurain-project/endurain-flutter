import Foundation
import HealthKit
import os

/// Live heart rate from HealthKit while a recording collects points.
///
/// iOS 26 lets an iPhone app run its own `HKWorkoutSession`. While one is
/// running, HealthKit delivers live heart rate from sources that never appear
/// as Bluetooth sensors, such as AirPods Pro 3. The session exists only to
/// receive those samples: the workout is always discarded, never saved, so it
/// does not come back through Health sync as a duplicate of the recording.
///
/// Best effort by design: on iOS < 26, without HealthKit, or when the user
/// declines workout access, the monitor stays idle and points keep a nil heart
/// rate, as before. A connected BLE sensor still wins, because the Dart layer
/// overlays its readings onto drained points.
@MainActor
final class HealthKitHeartRateMonitor: NSObject {
    /// Maximum distance between a point and the nearest sample, matching the
    /// Dart sensor buffer freshness.
    static let freshnessSeconds: TimeInterval = 10
    /// Samples kept for nearest-reading matching of batched location fixes.
    static let maxSamples = 120
    /// Consecutive failed or lost sessions tolerated before giving up.
    static let maxRestarts = 3

    typealias Sample = (bpm: Int, date: Date)

    private static let log = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "endurain",
        category: "HealthKitHeartRate"
    )

    /// Called on the main actor for every accepted sample, so the owner can
    /// persist it to the sensor log.
    var onSample: ((Int, Date) -> Void)?

    private let healthStore = HKHealthStore()
    /// A `LiveWorkout`; typed loosely because it only exists on iOS 26+.
    private var liveWorkout: AnyObject?
    private var samples: [Sample] = []
    private var activityType = "other"
    private var restartCount = 0
    /// Bumped on every start/stop so a late authorization or recovery callback
    /// cannot start a session after collection already stopped.
    private var generation = 0

    func start(activityType: String) {
        guard #available(iOS 26.0, *),
              liveWorkout == nil,
              HKHealthStore.isHealthDataAvailable() else {
            return
        }
        self.activityType = activityType
        restartCount = 0
        generation += 1
        let startGeneration = generation
        healthStore.requestAuthorization(
            toShare: [HKObjectType.workoutType()],
            read: [HKQuantityType(.heartRate)]
        ) { [weak self] success, error in
            Task { @MainActor in
                guard let self, self.generation == startGeneration else {
                    return
                }
                guard success else {
                    if let error {
                        Self.log.error("authorization failed: \(error.localizedDescription, privacy: .public)")
                    }
                    return
                }
                self.recoverThenBegin(generation: startGeneration)
            }
        }
    }

    func stop() {
        generation += 1
        samples.removeAll()
        guard #available(iOS 26.0, *), let workout = liveWorkout as? LiveWorkout else {
            return
        }
        liveWorkout = nil
        workout.end()
    }

    /// The sample nearest to `date`, if within the freshness window.
    func heartRateBpm(at date: Date) -> Int? {
        Self.nearestBpm(samples, at: date)
    }

    static func nearestBpm(_ samples: [Sample], at date: Date) -> Int? {
        var best: Sample?
        var bestDistance = TimeInterval.infinity
        for sample in samples {
            let distance = abs(sample.date.timeIntervalSince(date))
            if distance < bestDistance {
                best = sample
                bestDistance = distance
            }
        }
        return freshBpm(best, at: date)
    }

    static func appending(_ sample: Sample, to samples: [Sample]) -> [Sample] {
        var result = samples
        result.append(sample)
        if result.count > maxSamples {
            result.removeFirst(result.count - maxSamples)
        }
        return result
    }

    static func freshBpm(_ sample: Sample?, at date: Date) -> Int? {
        guard let sample,
              abs(sample.date.timeIntervalSince(date)) <= freshnessSeconds else {
            return nil
        }
        return sample.bpm
    }

    static func workoutActivityType(for activityType: String) -> HKWorkoutActivityType {
        switch activityType {
        case "run":
            return .running
        case "ride":
            return .cycling
        case "walk":
            return .walking
        case "hike":
            return .hiking
        default:
            return .other
        }
    }

    /// After the app was terminated mid-recording, HealthKit may still hold
    /// the old session. End and discard it first, otherwise creating a new one
    /// can fail silently.
    @available(iOS 26.0, *)
    private func recoverThenBegin(generation startGeneration: Int) {
        healthStore.recoverActiveWorkoutSession { [weak self] session, error in
            Task { @MainActor in
                guard let self, self.generation == startGeneration else {
                    return
                }
                if let error {
                    Self.log.error("recovery failed: \(error.localizedDescription, privacy: .public)")
                }
                if let session {
                    Self.log.info("ending orphaned workout session")
                    session.end()
                    session.associatedWorkoutBuilder().discardWorkout()
                }
                self.beginSession()
            }
        }
    }

    @available(iOS 26.0, *)
    private func beginSession() {
        guard liveWorkout == nil,
              healthStore.authorizationStatus(for: HKObjectType.workoutType()) == .sharingAuthorized
        else {
            return
        }
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = Self.workoutActivityType(for: activityType)
        configuration.locationType = .outdoor
        let session: HKWorkoutSession
        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
        } catch {
            Self.log.error("session creation failed: \(error.localizedDescription, privacy: .public)")
            scheduleRestart()
            return
        }
        let builder = session.associatedWorkoutBuilder()
        builder.dataSource = HKLiveWorkoutDataSource(
            healthStore: healthStore,
            workoutConfiguration: configuration
        )
        builder.delegate = self
        session.delegate = self
        let workout = LiveWorkout(session: session, builder: builder)
        liveWorkout = workout
        let startDate = Date()
        session.startActivity(with: startDate)
        let startGeneration = generation
        let builderId = ObjectIdentifier(builder)
        builder.beginCollection(withStart: startDate) { [weak self] success, error in
            guard !success else {
                return
            }
            let message = error?.localizedDescription ?? "unknown error"
            Task { @MainActor in
                Self.log.error("beginCollection failed: \(message, privacy: .public)")
                guard let self, self.generation == startGeneration else {
                    return
                }
                self.handleSessionLost(builderId: builderId)
            }
        }
    }

    /// Drops the current session (e.g. taken over by another app, or failed
    /// to start) and starts a fresh one, up to `maxRestarts` times.
    @available(iOS 26.0, *)
    private func handleSessionLost(builderId: ObjectIdentifier) {
        guard let workout = liveWorkout as? LiveWorkout,
              ObjectIdentifier(workout.builder) == builderId else {
            return
        }
        liveWorkout = nil
        workout.end()
        scheduleRestart()
    }

    private func scheduleRestart() {
        guard #available(iOS 26.0, *), restartCount < Self.maxRestarts else {
            Self.log.error("giving up on HealthKit heart rate after repeated failures")
            return
        }
        restartCount += 1
        let startGeneration = generation
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard let self, self.generation == startGeneration else {
                return
            }
            self.beginSession()
        }
    }

    @available(iOS 26.0, *)
    fileprivate func record(bpm: Int, at date: Date, builderId: ObjectIdentifier) {
        guard let workout = liveWorkout as? LiveWorkout,
              ObjectIdentifier(workout.builder) == builderId else {
            return
        }
        samples = Self.appending((bpm, date), to: samples)
        restartCount = 0
        onSample?(bpm, date)
    }

    @available(iOS 26.0, *)
    fileprivate func sessionEnded(sessionId: ObjectIdentifier) {
        guard let workout = liveWorkout as? LiveWorkout,
              ObjectIdentifier(workout.session) == sessionId else {
            return
        }
        Self.log.info("workout session ended externally; restarting")
        handleSessionLost(builderId: ObjectIdentifier(workout.builder))
    }
}

@available(iOS 26.0, *)
private final class LiveWorkout {
    let session: HKWorkoutSession
    let builder: HKLiveWorkoutBuilder

    init(session: HKWorkoutSession, builder: HKLiveWorkoutBuilder) {
        self.session = session
        self.builder = builder
    }

    func end() {
        session.end()
        builder.discardWorkout()
    }
}

@available(iOS 26.0, *)
extension HealthKitHeartRateMonitor: HKWorkoutSessionDelegate {
    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {
        guard toState == .ended || toState == .stopped else {
            return
        }
        let sessionId = ObjectIdentifier(workoutSession)
        Task { @MainActor [weak self] in
            self?.sessionEnded(sessionId: sessionId)
        }
    }

    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didFailWithError error: Error
    ) {
        let sessionId = ObjectIdentifier(workoutSession)
        let message = error.localizedDescription
        Task { @MainActor [weak self] in
            Self.log.error("workout session failed: \(message, privacy: .public)")
            self?.sessionEnded(sessionId: sessionId)
        }
    }
}

@available(iOS 26.0, *)
extension HealthKitHeartRateMonitor: HKLiveWorkoutBuilderDelegate {
    nonisolated func workoutBuilder(
        _ workoutBuilder: HKLiveWorkoutBuilder,
        didCollectDataOf collectedTypes: Set<HKSampleType>
    ) {
        let heartRate = HKQuantityType(.heartRate)
        guard collectedTypes.contains(heartRate),
              let statistics = workoutBuilder.statistics(for: heartRate),
              let quantity = statistics.mostRecentQuantity(),
              let interval = statistics.mostRecentQuantityDateInterval() else {
            return
        }
        let bpm = Int(quantity.doubleValue(for: .count().unitDivided(by: .minute())).rounded())
        let builderId = ObjectIdentifier(workoutBuilder)
        Task { @MainActor [weak self] in
            self?.record(bpm: bpm, at: interval.end, builderId: builderId)
        }
    }

    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}
}
