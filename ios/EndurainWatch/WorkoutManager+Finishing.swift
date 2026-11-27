import Foundation
import HealthKit

// MARK: - Finishing

extension WorkoutManager {
    func finish(at endDate: Date) async {
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
                Self.log.error("Could not save the workout to Health: \(error.localizedDescription, privacy: .private)")
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

    func enqueueHandoff(
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
            Self.log.error("Could not queue the workout: \(error.localizedDescription, privacy: .private)")
            errorMessage = String(localized: "The workout could not be queued for your iPhone. It will be retried.")
        }
    }

    func persistRecording() {
        guard let recording else { return }
        do {
            try store.update(recording)
        } catch {
            Self.log.error("Could not save the workout state: \(error.localizedDescription, privacy: .private)")
        }
    }
}
