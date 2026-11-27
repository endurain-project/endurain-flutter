import Foundation
import HealthKit

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
        Self.log.error("The workout session failed: \(error.localizedDescription, privacy: .private)")
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
