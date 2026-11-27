// Flutter's Objective-C headers carry no concurrency annotations; the engine
// and its channels are only used on the main thread here.
@preconcurrency import Flutter
import Foundation
import HealthKit
import UIKit

/// Groups the HealthKit deliveries into background sync runs. Every delivery's
/// completion handler is called once a run that started after it finishes:
/// a delivery during a run waits for one follow-up run, since the running one
/// may have read its anchors before the new data was saved.
struct HealthBackgroundRuns {
    private var current: [@MainActor () -> Void] = []
    private var followUp: [@MainActor () -> Void] = []

    private(set) var isRunning = false

    /// Adds a delivery. Returns `true` when the caller should start a run now.
    mutating func request(_ completion: @escaping @MainActor () -> Void) -> Bool {
        if isRunning {
            followUp.append(completion)
            return false
        }
        isRunning = true
        current = [completion]
        return true
    }

    /// Ends the running run. Returns the completion handlers to call, and
    /// whether to start the follow-up run now.
    mutating func finish() -> (completions: [@MainActor () -> Void], startFollowUp: Bool) {
        let done = current
        current = followUp
        followUp = []
        isRunning = !current.isEmpty
        return (done, isRunning)
    }
}

/// Imports new workouts when HealthKit saves them, without the app being
/// opened. An `HKObserverQuery` with background delivery watches workouts and
/// workout routes (a route is often saved after its workout), so HealthKit
/// wakes the app for each change.
///
/// Each run is the Dart automatic-import pass: on the app's engine when its
/// Dart side listens, otherwise on a headless engine started on the
/// `healthBackgroundSyncMain` entry point (`lib/main.dart`). While the app is
/// starting in the foreground, the run waits for the app's engine instead of
/// starting a second one next to it.
///
/// The scheduled state is stored because HealthKit expects the observer
/// queries to be set up again at every launch, from
/// `application(_:didFinishLaunchingWithOptions:)`.
@MainActor
final class HealthBackgroundSync {
    private static let scheduledKey = "endurain.health_background_sync.scheduled"
    private static let entrypoint = "healthBackgroundSyncMain"
    nonisolated private static let log = AppLogger.make(category: "HealthBackgroundSync")

    private static var types: [HKSampleType] {
        [HKObjectType.workoutType(), HKSeriesType.workoutRoute()]
    }

    private let healthStore: HKHealthStore
    private let defaults: UserDefaults
    private var observers: [HKObserverQuery] = []
    private var runs = HealthBackgroundRuns()

    /// Tells a run's replies apart from those of an earlier run that already
    /// ended, for example on expiry.
    private var runID = 0
    private var listening: HealthBackgroundSyncChannel?
    private var waitingForApp = false
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid

    /// The headless engine of the running run and the channels it needs.
    private var headless: (engine: FlutterEngine, channels: [AnyObject])?

    init(healthStore: HKHealthStore = HKHealthStore(), defaults: UserDefaults = .standard) {
        self.healthStore = healthStore
        self.defaults = defaults
    }

    /// Sets the observer queries up again when background import is on.
    func startIfScheduled() {
        if defaults.bool(forKey: Self.scheduledKey) {
            startObservers()
        }
    }

    /// Turns background delivery of new workouts on or off. Idempotent.
    ///
    /// Each type is turned on or off even when another one fails, so a type
    /// HealthKit refuses does not keep the other from waking the app; the
    /// first failure is thrown afterwards.
    func setScheduled(_ scheduled: Bool) async throws {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let wasScheduled = defaults.bool(forKey: Self.scheduledKey)
        defaults.set(scheduled, forKey: Self.scheduledKey)
        if scheduled {
            startObservers()
        } else {
            stopObservers()
            guard wasScheduled else { return }
        }
        var firstError: Error?
        for type in Self.types {
            do {
                if scheduled {
                    try await healthStore.enableBackgroundDelivery(for: type, frequency: .immediate)
                } else {
                    try await healthStore.disableBackgroundDelivery(for: type)
                }
            } catch {
                firstError = firstError ?? error
            }
        }
        if let firstError {
            throw firstError
        }
    }

    /// The app's engine runs the syncs from now on; one waiting for it starts.
    func listen(_ channel: HealthBackgroundSyncChannel) {
        listening = channel
        if waitingForApp {
            waitingForApp = false
            run(on: channel, id: runID)
        }
    }

    private func startObservers() {
        guard observers.isEmpty else { return }
        observers = Self.types.map { type in
            let query = HKObserverQuery(sampleType: type, predicate: nil) { [weak self] _, completionHandler, error in
                // HealthKit calls this on its own background queue.
                let completion = ObserverCompletion(completionHandler)
                if let error {
                    Self.log.error("Observer query failed: \(error.localizedDescription, privacy: .public)")
                    completion.call()
                    return
                }
                Task { @MainActor in
                    guard let self else {
                        completion.call()
                        return
                    }
                    self.deliver(completion)
                }
            }
            healthStore.execute(query)
            return query
        }
    }

    private func stopObservers() {
        observers.forEach(healthStore.stop)
        observers = []
    }

    private func deliver(_ completion: ObserverCompletion) {
        if runs.request({ completion.call() }) {
            startRun()
        }
    }

    private func startRun() {
        runID += 1
        let id = runID
        // Background delivery gives the app little time; this asks for the
        // usual background allowance and ends the run when it runs out.
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "HealthBackgroundSync") { [weak self] in
            MainActor.assumeIsolated {
                self?.finishRun(id: id)
            }
        }
        if let listening {
            run(on: listening, id: id)
        } else if UIApplication.shared.applicationState != .background {
            // The app is coming to the foreground and its engine is starting;
            // `listen` hands the run to it.
            waitingForApp = true
        } else {
            startHeadless(id: id)
        }
    }

    private func run(on channel: HealthBackgroundSyncChannel, id: Int) {
        channel.run { [weak self] _ in
            self?.finishRun(id: id)
        }
    }

    private func startHeadless(id: Int) {
        let engine = FlutterEngine(
            name: "health_background_sync",
            project: nil,
            allowHeadlessExecution: true
        )
        guard engine.run(withEntrypoint: Self.entrypoint) else {
            Self.log.error("The headless engine did not start")
            finishRun(id: id)
            return
        }
        GeneratedPluginRegistrant.register(with: engine)
        let syncChannel = HealthBackgroundSyncChannel(
            setScheduled: { [weak self] scheduled in
                try await self?.setScheduled(scheduled)
            },
            // A headless engine only runs the sync it was started for.
            onListen: { _ in },
            onFinished: { [weak self] _ in
                self?.finishRun(id: id)
            }
        )
        syncChannel.register(with: engine.binaryMessenger)
        let heartRateChannel = HeartRateSeriesChannel(healthStore: healthStore)
        heartRateChannel.register(with: engine.binaryMessenger)
        let changesChannel = HealthWorkoutChangesChannel(healthStore: healthStore)
        changesChannel.register(with: engine.binaryMessenger)
        headless = (engine, [syncChannel, heartRateChannel, changesChannel])
    }

    private func finishRun(id: Int) {
        guard id == runID, runs.isRunning else { return }
        waitingForApp = false
        headless?.engine.destroyContext()
        headless = nil
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
        let (completions, startFollowUp) = runs.finish()
        completions.forEach { $0() }
        if startFollowUp {
            startRun()
        }
    }
}

/// An observer query's completion handler, which HealthKit lets any thread
/// call once, carried from its queue to the main actor.
private final class ObserverCompletion: @unchecked Sendable {
    private let handler: () -> Void

    init(_ handler: @escaping () -> Void) {
        self.handler = handler
    }

    func call() {
        handler()
    }
}
