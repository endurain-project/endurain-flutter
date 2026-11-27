import Foundation
import Observation
import WatchConnectivity

/// Watch end of the link to the Endurain iPhone app.
///
/// Every finished workout is kept in a durable outbox and sent with
/// `WCSession.transferFile`, which the system delivers in the background even
/// when the phone is out of range at the time. A delivered workout stays in
/// the outbox until the phone confirms Endurain stored it, so a session the
/// phone cannot store yet (for example one without a GPS route) is never lost
/// on the watch. A delivered workout still unconfirmed after
/// [redeliveryDelay] is sent again, because the phone may have failed to keep
/// the file it received. A workout the phone never confirms is resent with an
/// exponential backoff (doubling up to [maxRedeliveryDelay]) rather than at a
/// fixed rate, and is never dropped.
///
/// Main-actor isolated for SwiftUI. WatchConnectivity calls the delegate on a
/// background queue, so the delegate methods and the transfer logic are
/// nonisolated: they only touch `WCSession` and the self-locking outbox.
@MainActor
@Observable
final class PhoneLink: NSObject, WCSessionDelegate {
    static let shared = PhoneLink()

    /// How long a delivered workout waits for the phone's confirmation
    /// before it is sent again. Doubles with every further unconfirmed
    /// delivery, up to [maxRedeliveryDelay].
    nonisolated static let redeliveryDelay: TimeInterval = 10 * 60

    /// Longest wait between two deliveries of an unconfirmed workout.
    nonisolated static let maxRedeliveryDelay: TimeInterval = 24 * 60 * 60

    /// A failed transfer is retried after this long, or sooner when the phone
    /// becomes reachable.
    nonisolated static let retryDelay: TimeInterval = 60

    /// Workouts not yet confirmed by the phone.
    private(set) var waitingCount = 0

    @ObservationIgnored nonisolated let outbox: HandoffFileStore

    init(outbox: HandoffFileStore = HandoffFileStore(directory: PhoneLink.defaultOutboxDirectory())) {
        self.outbox = outbox
        super.init()
    }

    nonisolated static func defaultOutboxDirectory() -> URL {
        return WatchStorage.applicationSupportDirectory
            .appendingPathComponent("watch_outbox", isDirectory: true)
    }

    func activate() {
        refreshWaitingCount()
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    func enqueue(_ data: Data, sessionId: String) throws {
        try outbox.save(data, sessionId: sessionId)
        refreshWaitingCount()
        sendPending()
    }

    /// Starts a transfer for every workout not yet delivered, or delivered
    /// but unconfirmed past its backoff (see [redeliveryDelay]), and not
    /// already on its way.
    nonisolated func sendPending() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated else { return }
        let inFlight = Set(session.outstandingFileTransfers.compactMap { transfer in
            transfer.file.metadata?[WatchProtocol.keySessionId] as? String
        })
        let entries = outbox.entriesToTransfer(
            baseDelay: Self.redeliveryDelay,
            maxDelay: Self.maxRedeliveryDelay
        )
        for entry in entries where !inFlight.contains(entry.sessionId) {
            session.transferFile(
                entry.url,
                metadata: WatchProtocol.handoffMetadata(sessionId: entry.sessionId)
            )
        }
        refreshWaitingCount()
    }

    nonisolated private func refreshWaitingCount() {
        let count = ((try? outbox.entries()) ?? []).count
        Task { @MainActor [weak self] in
            self?.waitingCount = count
        }
    }

    // MARK: - WCSessionDelegate

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        sendPending()
    }

    nonisolated func session(
        _ session: WCSession,
        didFinish fileTransfer: WCSessionFileTransfer,
        error: Error?
    ) {
        guard let sessionId = fileTransfer.file.metadata?[WatchProtocol.keySessionId] as? String else {
            return
        }
        if error == nil {
            outbox.markDelivered(sessionId)
            refreshWaitingCount()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.retryDelay) { [weak self] in
                self?.sendPending()
            }
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        guard let sessionId = WatchProtocol.acknowledgedSessionId(in: userInfo) else {
            return
        }
        outbox.remove(sessionId)
        refreshWaitingCount()
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        if session.isReachable {
            sendPending()
        }
    }
}
