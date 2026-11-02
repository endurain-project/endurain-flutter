import Foundation
import HealthKit

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
    /// Maximum distance between a point and the latest sample, matching the
    /// Dart sensor buffer freshness.
    static let freshnessSeconds: TimeInterval = 10

    private let healthStore = HKHealthStore()
    /// A `LiveWorkout`; typed loosely because it only exists on iOS 26+.
    private var liveWorkout: AnyObject?
    private var latestSample: (bpm: Int, date: Date)?
    /// Bumped on every start/stop so a late authorization callback cannot
    /// start a session after collection already stopped.
    private var generation = 0

    func start(activityType: String) {
        guard #available(iOS 26.0, *),
              liveWorkout == nil,
              HKHealthStore.isHealthDataAvailable() else {
            return
        }
        generation += 1
        let startGeneration = generation
        healthStore.requestAuthorization(
            toShare: [HKObjectType.workoutType()],
            read: [HKQuantityType(.heartRate)]
        ) { [weak self] success, _ in
            Task { @MainActor in
                guard let self, success, self.generation == startGeneration else {
                    return
                }
                self.beginSession(activityType: activityType)
            }
        }
    }

    func stop() {
        generation += 1
        latestSample = nil
        guard #available(iOS 26.0, *), let workout = liveWorkout as? LiveWorkout else {
            return
        }
        liveWorkout = nil
        workout.session.end()
        workout.builder.discardWorkout()
    }

    /// The latest heart rate if it was sampled close enough to `date`.
    func heartRateBpm(at date: Date) -> Int? {
        Self.freshBpm(latestSample, at: date)
    }

    static func freshBpm(_ sample: (bpm: Int, date: Date)?, at date: Date) -> Int? {
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

    @available(iOS 26.0, *)
    private func beginSession(activityType: String) {
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
            return
        }
        let builder = session.associatedWorkoutBuilder()
        builder.dataSource = HKLiveWorkoutDataSource(
            healthStore: healthStore,
            workoutConfiguration: configuration
        )
        builder.delegate = self
        liveWorkout = LiveWorkout(session: session, builder: builder)
        let startDate = Date()
        session.startActivity(with: startDate)
        builder.beginCollection(withStart: startDate) { _, _ in }
    }

    @available(iOS 26.0, *)
    private func record(bpm: Int, at date: Date, builderId: ObjectIdentifier) {
        guard let workout = liveWorkout as? LiveWorkout,
              ObjectIdentifier(workout.builder) == builderId else {
            return
        }
        latestSample = (bpm, date)
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
