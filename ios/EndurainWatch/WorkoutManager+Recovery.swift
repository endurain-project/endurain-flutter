import Foundation
import HealthKit

// MARK: - Recovery

extension WorkoutManager {
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
                    Self.log.error(
                        "Could not check for a running workout: \(error.localizedDescription, privacy: .private)"
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
}
