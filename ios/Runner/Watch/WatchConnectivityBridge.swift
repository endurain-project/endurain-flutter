import Foundation
import WatchConnectivity

/// Phone end of the link to the Endurain Apple Watch app.
///
/// Activated at launch, before the Flutter engine, because WatchConnectivity
/// delivers queued transfers as soon as the session activates and drops the
/// received file once the delegate call returns. Every session the watch
/// sends is therefore moved into a durable inbox first; Dart drains the inbox
/// whenever it runs and acknowledges what it stored, and only then is the
/// watch told it may delete its copy.
///
/// WatchConnectivity calls the delegate on a background queue. The callbacks
/// to Flutter are always made on the main queue.
final class WatchConnectivityBridge: NSObject, WCSessionDelegate {
    static let shared = WatchConnectivityBridge()

    /// Sessions received from the watch and not yet acknowledged by Dart.
    let inbox: HandoffFileStore

    /// Called on the main queue after a session lands in the inbox.
    var onHandoffReceived: (() -> Void)?

    /// Called on the main queue with the new `WatchLinkStatus` name.
    var onLinkStatusChanged: ((String) -> Void)?

    private let defaults: UserDefaults
    private static let pendingAcknowledgementsKey = "endurain.watch.pending_acknowledgements"
    private let acknowledgementLock = NSLock()

    init(
        inbox: HandoffFileStore = HandoffFileStore(directory: WatchConnectivityBridge.defaultInboxDirectory()),
        defaults: UserDefaults = .standard
    ) {
        self.inbox = inbox
        self.defaults = defaults
        super.init()
    }

    static func defaultInboxDirectory() -> URL {
        let support = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? FileManager.default.temporaryDirectory
        return support.appendingPathComponent("watch_inbox", isDirectory: true)
    }

    func activate() {
        guard WCSession.isSupported() else {
            return
        }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    var linkStatus: String {
        guard WCSession.isSupported() else {
            return WatchLinkState.status(
                isSupported: false,
                isActivated: false,
                isPaired: false,
                isWatchAppInstalled: false,
                isReachable: false
            )
        }
        let session = WCSession.default
        return WatchLinkState.status(
            isSupported: true,
            isActivated: session.activationState == .activated,
            isPaired: session.isPaired,
            isWatchAppInstalled: session.isWatchAppInstalled,
            isReachable: session.isReachable
        )
    }

    /// Drops [sessionId] from the inbox and tells the watch it may delete its
    /// copy. The acknowledgement is queued durably and sent once the session
    /// is usable, so it survives the phone app being closed in between.
    func acknowledge(sessionId: String) {
        inbox.remove(sessionId)
        acknowledgementLock.lock()
        var pending = pendingAcknowledgements()
        if !pending.contains(sessionId) {
            pending.append(sessionId)
        }
        defaults.set(pending, forKey: Self.pendingAcknowledgementsKey)
        acknowledgementLock.unlock()
        flushAcknowledgements()
    }

    func pendingAcknowledgements() -> [String] {
        return defaults.stringArray(forKey: Self.pendingAcknowledgementsKey) ?? []
    }

    /// Hands queued acknowledgements to WatchConnectivity, which keeps
    /// user-info transfers queued across launches until the watch gets them.
    func flushAcknowledgements() {
        guard WCSession.isSupported() else {
            return
        }
        let session = WCSession.default
        guard session.activationState == .activated,
              session.isPaired,
              session.isWatchAppInstalled
        else {
            return
        }
        acknowledgementLock.lock()
        let pending = pendingAcknowledgements()
        defaults.removeObject(forKey: Self.pendingAcknowledgementsKey)
        acknowledgementLock.unlock()
        for sessionId in pending {
            session.transferUserInfo(WatchProtocol.acknowledgement(sessionId: sessionId))
        }
    }

    /// Moves a received file into the inbox. Returns false when it carries no
    /// usable session id, in which case it is dropped.
    @discardableResult
    func storeReceivedHandoff(fileURL: URL, metadata: [String: Any]?) -> Bool {
        guard let data = try? Data(contentsOf: fileURL) else {
            NSLog("Endurain watch bridge: could not read a received session")
            return false
        }
        guard let sessionId = Self.sessionId(metadata: metadata, data: data) else {
            NSLog("Endurain watch bridge: dropped a session without an id")
            return false
        }
        do {
            try inbox.save(data, sessionId: sessionId)
            return true
        } catch {
            NSLog("Endurain watch bridge: could not store a received session")
            return false
        }
    }

    /// The session id from the transfer metadata, or from the envelope itself.
    static func sessionId(metadata: [String: Any]?, data: Data) -> String? {
        if let id = metadata?[WatchProtocol.keySessionId] as? String, !id.isEmpty {
            return id
        }
        guard let object = try? JSONSerialization.jsonObject(with: data),
              let envelope = object as? [String: Any],
              let session = envelope["session"] as? [String: Any],
              let id = session["localSessionId"] as? String,
              !id.isEmpty
        else {
            return nil
        }
        return id
    }

    // MARK: - WCSessionDelegate

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        flushAcknowledgements()
        notifyLinkStatus()
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        notifyLinkStatus()
    }

    func sessionDidDeactivate(_ session: WCSession) {
        // The user switched to another watch: activate again for the new one.
        WCSession.default.activate()
    }

    func sessionWatchStateDidChange(_ session: WCSession) {
        flushAcknowledgements()
        notifyLinkStatus()
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        notifyLinkStatus()
    }

    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        // The file is deleted when this returns, so it is stored synchronously.
        guard storeReceivedHandoff(fileURL: file.fileURL, metadata: file.metadata) else {
            return
        }
        DispatchQueue.main.async { [weak self] in
            self?.onHandoffReceived?()
        }
    }

    // MARK: - Private

    private func notifyLinkStatus() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.onLinkStatusChanged?(self.linkStatus)
        }
    }
}
