import Foundation
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
/// the file it received; unconfirmed workouts are never dropped.
final class PhoneLink: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = PhoneLink()

    /// How long a delivered workout waits for the phone's confirmation
    /// before it is sent again.
    static let redeliveryDelay: TimeInterval = 10 * 60

    /// A failed transfer is retried after this long, or sooner when the phone
    /// becomes reachable.
    static let retryDelay: TimeInterval = 60

    /// Workouts not yet confirmed by the phone. Updated on the main queue.
    @Published private(set) var waitingCount = 0

    let outbox: HandoffFileStore

    init(outbox: HandoffFileStore = HandoffFileStore(directory: PhoneLink.defaultOutboxDirectory())) {
        self.outbox = outbox
        super.init()
    }

    static func defaultOutboxDirectory() -> URL {
        let support = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? FileManager.default.temporaryDirectory
        return support.appendingPathComponent("watch_outbox", isDirectory: true)
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
    /// but unconfirmed for [redeliveryDelay], and not already on its way.
    func sendPending() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated else { return }
        let inFlight = Set(session.outstandingFileTransfers.compactMap { transfer in
            transfer.file.metadata?[WatchProtocol.keySessionId] as? String
        })
        let entries = outbox.entriesToTransfer(
            redeliverDeliveredBefore: Date().addingTimeInterval(-Self.redeliveryDelay)
        )
        for entry in entries where !inFlight.contains(entry.sessionId) {
            session.transferFile(
                entry.url,
                metadata: WatchProtocol.handoffMetadata(sessionId: entry.sessionId)
            )
        }
        refreshWaitingCount()
    }

    private func refreshWaitingCount() {
        let count = ((try? outbox.entries()) ?? []).count
        DispatchQueue.main.async { [weak self] in
            self?.waitingCount = count
        }
    }

    // MARK: - WCSessionDelegate

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        sendPending()
    }

    func session(
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

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        guard let sessionId = WatchProtocol.acknowledgedSessionId(in: userInfo) else {
            return
        }
        outbox.remove(sessionId)
        refreshWaitingCount()
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        if session.isReachable {
            sendPending()
        }
    }
}
