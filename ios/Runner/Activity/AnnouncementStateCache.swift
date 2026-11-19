import Foundation

/// Keeps live announcement progress in memory between durable checkpoints.
final class AnnouncementStateCache {
    static let defaultCheckpointInterval: TimeInterval = 60

    private let checkpointInterval: TimeInterval
    private var persistedState: AnnouncementStateData?
    private var lastCheckpointUptime: TimeInterval?

    private(set) var state: AnnouncementStateData?

    init(checkpointInterval: TimeInterval = defaultCheckpointInterval) {
        precondition(checkpointInterval > 0)
        self.checkpointInterval = checkpointInterval
    }

    func restore(_ state: AnnouncementStateData, uptime: TimeInterval) {
        self.state = state
        persistedState = state
        lastCheckpointUptime = uptime
    }

    func update(_ state: AnnouncementStateData) {
        self.state = state
    }

    func stateToPersist(
        uptime: TimeInterval,
        force: Bool = false
    ) -> AnnouncementStateData? {
        guard let state, state != persistedState else {
            return nil
        }
        guard let lastCheckpointUptime else {
            return state
        }
        return force || uptime - lastCheckpointUptime >= checkpointInterval
            ? state
            : nil
    }

    func markPersisted(uptime: TimeInterval) {
        persistedState = state
        lastCheckpointUptime = uptime
    }

    func reset() {
        state = nil
        persistedState = nil
        lastCheckpointUptime = nil
    }
}