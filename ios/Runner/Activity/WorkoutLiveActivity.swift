import ActivityKit
import Foundation
import os

/// Keeps the Live Activity of a recording in step with its durable session.
///
/// The session's state (recording, paused, finished) and timing come from
/// `ActiveActivityStore`, which reports every change through
/// `sessionDidChange`, so the elapsed time and the paused state stay right
/// even while Flutter is not running. The distance and pace or speed come from
/// Flutter (`updateMetrics`), already formatted the way the recording screen
/// shows them. The activity starts with the first metrics of a recording,
/// which arrive while the app is in front, and ends when the recording is
/// stopped or discarded.
@MainActor
final class WorkoutLiveActivity {
    nonisolated private static let log = AppLogger.make(category: "WorkoutLiveActivity")

    private let store: ActiveActivityStore

    /// The latest metrics Flutter sent, and the session they belong to.
    private var metrics: WorkoutActivityAttributes.Metrics?
    private var metricsSessionId: String?

    /// The state last asked of each activity, by ID. A new state is compared
    /// with this rather than with the one shown, which lags behind while an
    /// update is queued.
    private var requestedStates: [String: WorkoutActivityAttributes.ContentState] = [:]

    /// The last queued ActivityKit call. Each call waits for the one before,
    /// so they apply in the order they were made and the latest state wins.
    private var lastOperation: Task<Void, Never>?

    init(store: ActiveActivityStore) {
        self.store = store
    }

    /// Shows [metrics] for the recording [localSessionId]. Ignored when that
    /// recording is no longer the active one.
    func updateMetrics(_ metrics: WorkoutActivityAttributes.Metrics, localSessionId: String) {
        guard let session = store.loadSession(), session.localSessionId == localSessionId else {
            return
        }
        self.metrics = metrics
        metricsSessionId = localSessionId
        sessionDidChange(session)
    }

    /// Brings the Live Activity in line with [session]: ends it when there is
    /// no recording or it finished, otherwise updates it, or starts it once
    /// metrics for the recording are known. Ends activities left behind by
    /// any other recording.
    func sessionDidChange(_ session: ActiveActivitySessionData?) {
        let activities = Activity<WorkoutActivityAttributes>.activities
        guard let session, session.status != ActiveActivitySessionData.statusCompleted else {
            end(activities)
            return
        }
        let current = activities.first { $0.attributes.localSessionId == session.localSessionId }
        end(activities.filter { $0.id != current?.id })
        // After a relaunch only the activity itself still holds the metrics.
        let latestMetrics = metricsSessionId == session.localSessionId ? metrics : nil
        guard let metrics = latestMetrics ?? current?.content.state.metrics else {
            return
        }
        let state = Self.contentState(
            for: session,
            metrics: metrics,
            nowMillis: LocationFixPolicy.nowMillis()
        )
        if let current {
            let activityId = current.id
            guard (requestedStates[activityId] ?? current.content.state) != state else {
                return
            }
            requestedStates[activityId] = state
            enqueue {
                await Self.update(activityId: activityId, to: state)
            }
            return
        }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            return
        }
        do {
            let activity = try Activity.request(
                attributes: WorkoutActivityAttributes(localSessionId: session.localSessionId),
                content: ActivityContent(state: state, staleDate: nil)
            )
            requestedStates[activity.id] = state
        } catch {
            // iOS starts a Live Activity only while the app is in front, for
            // example not after a start countdown that ended on a locked
            // screen. The next metrics update tries again.
            Self.log.info("Live Activity not started: \(error.localizedDescription, privacy: .private)")
        }
    }

    /// The Live Activity content for [session]: its elapsed-time counter
    /// running from the recorded time so far while it records, or stopped at
    /// the pause.
    static func contentState(
        for session: ActiveActivitySessionData,
        metrics: WorkoutActivityAttributes.Metrics,
        nowMillis: Int64
    ) -> WorkoutActivityAttributes.ContentState {
        let elapsedMillis = Int64(session.elapsedDurationSeconds) * 1000
        if session.status == ActiveActivitySessionData.statusRecording {
            let anchorMillis = IsoTime.toEpochMillis(session.resumedAt ?? session.startedAt)
                ?? nowMillis
            return WorkoutActivityAttributes.ContentState(
                timerStart: date(anchorMillis - elapsedMillis),
                pausedAt: nil,
                metrics: metrics
            )
        }
        let pausedAtMillis = IsoTime.toEpochMillis(session.pausedAt) ?? nowMillis
        return WorkoutActivityAttributes.ContentState(
            timerStart: date(pausedAtMillis - elapsedMillis),
            pausedAt: date(pausedAtMillis),
            metrics: metrics
        )
    }

    private static func date(_ millis: Int64) -> Date {
        return Date(timeIntervalSince1970: Double(millis) / 1000)
    }

    private func end(_ activities: [Activity<WorkoutActivityAttributes>]) {
        for activityId in activities.map(\.id) {
            requestedStates[activityId] = nil
            enqueue {
                await Self.end(activityId: activityId)
            }
        }
    }

    private func enqueue(_ operation: @escaping @Sendable () async -> Void) {
        let previous = lastOperation
        lastOperation = Task {
            await previous?.value
            await operation()
        }
    }

    // `Activity` is not `Sendable`, so these look the activity up again off
    // the main actor instead of handing it over.

    nonisolated private static func update(
        activityId: String,
        to state: WorkoutActivityAttributes.ContentState
    ) async {
        for activity in Activity<WorkoutActivityAttributes>.activities where activity.id == activityId {
            await activity.update(ActivityContent(state: state, staleDate: nil))
        }
    }

    nonisolated private static func end(activityId: String) async {
        for activity in Activity<WorkoutActivityAttributes>.activities where activity.id == activityId {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
}

extension WorkoutActivityAttributes.Metrics {
    /// Reads the metrics from the `updateLiveActivity` channel arguments, or
    /// returns nil when one is missing.
    init?(channelArguments arguments: [String: Any]?) {
        guard
            let title = arguments?["title"] as? String,
            let distanceLabel = arguments?["distanceLabel"] as? String,
            let distanceValue = arguments?["distanceValue"] as? String,
            let speedLabel = arguments?["speedLabel"] as? String,
            let speedValue = arguments?["speedValue"] as? String,
            let pausedLabel = arguments?["pausedLabel"] as? String
        else {
            return nil
        }
        self.init(
            title: title,
            distanceLabel: distanceLabel,
            distanceValue: distanceValue,
            speedLabel: speedLabel,
            speedValue: speedValue,
            pausedLabel: pausedLabel
        )
    }
}
