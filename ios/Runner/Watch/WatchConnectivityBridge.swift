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
/// WatchConnectivity calls the delegate on a background queue, Dart's
/// acknowledgements arrive on an I/O queue, and the Flutter callbacks run on
/// the main actor. The bridge is `Sendable`: the callbacks are main-actor
/// state, the inbox locks itself, and the queued acknowledgements are only
/// read and written under [acknowledgementLock].
final class WatchConnectivityBridge: NSObject, WCSessionDelegate, Sendable {
    static let shared = WatchConnectivityBridge()

    /// Largest watch session file read into memory. A workout point is about
    /// 220 bytes of JSON at one fix per second, so this holds about 40 hours;
    /// anything bigger is not a session the watch app writes.
    static let maxHandoffBytes = 32 * 1024 * 1024

    /// Sessions received from the watch and not yet acknowledged by Dart.
    let inbox: HandoffFileStore

    /// Called after a session Dart can read lands in the inbox.
    @MainActor var onHandoffReceived: (@MainActor () -> Void)?

    /// Called with the new `WatchLinkStatus` name.
    @MainActor var onLinkStatusChanged: (@MainActor (String) -> Void)?

    // `UserDefaults` is documented as thread-safe ("you can use the same
    // object in multiple threads or tasks simultaneously") but is not marked
    // Sendable. Its read-modify-write sequences here run under the lock.
    nonisolated(unsafe) private let defaults: UserDefaults
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
        transferPendingAcknowledgements { sessionId in
            session.transferUserInfo(WatchProtocol.acknowledgement(sessionId: sessionId))
        }
    }

    /// Passes each queued acknowledgement to [transfer] and only then drops
    /// it from the queue, so one that was never handed over (the app killed
    /// mid-way) is sent on the next flush. A duplicate is harmless: the watch
    /// ignores an acknowledgement for a session it no longer has.
    func transferPendingAcknowledgements(_ transfer: (String) -> Void) {
        acknowledgementLock.lock()
        defer { acknowledgementLock.unlock() }
        var transferred = Set<String>()
        for sessionId in pendingAcknowledgements() {
            transfer(sessionId)
            transferred.insert(sessionId)
        }
        guard !transferred.isEmpty else {
            return
        }
        let remaining = pendingAcknowledgements().filter { !transferred.contains($0) }
        if remaining.isEmpty {
            defaults.removeObject(forKey: Self.pendingAcknowledgementsKey)
        } else {
            defaults.set(remaining, forKey: Self.pendingAcknowledgementsKey)
        }
    }

    /// What happened to a file received from the watch.
    enum ReceiveOutcome: Equatable {
        /// Stored in the inbox for Dart.
        case stored
        /// Written by a newer watch app. Neither stored nor acknowledged, so
        /// the watch keeps it and sends it again until an updated app here
        /// can read it.
        case deferred
        /// Not stored: unreadable, too large, or without a session id.
        case dropped
    }

    /// Moves a received file into the inbox.
    @discardableResult
    func storeReceivedHandoff(fileURL: URL, metadata: [String: Any]?) -> ReceiveOutcome {
        guard let data = Self.readHandoff(at: fileURL) else {
            return .dropped
        }
        guard WatchProtocol.isSupported(version: metadata?[WatchProtocol.keyVersion]),
              Self.isReadableVersion(data)
        else {
            NSLog("Endurain watch bridge: left a session from a newer watch app on the watch")
            return .deferred
        }
        guard let sessionId = Self.sessionId(metadata: metadata, data: data) else {
            NSLog("Endurain watch bridge: dropped a session without an id")
            return .dropped
        }
        do {
            try inbox.save(data, sessionId: sessionId)
            return .stored
        } catch {
            NSLog("Endurain watch bridge: could not store a received session")
            return .dropped
        }
    }

    /// The file's contents, or nil when it cannot be read or is larger than
    /// [maxHandoffBytes]. Reads at most one byte past the limit, so an
    /// oversized file is never loaded whole.
    static func readHandoff(at fileURL: URL, maxBytes: Int = maxHandoffBytes) -> Data? {
        do {
            let handle = try FileHandle(forReadingFrom: fileURL)
            defer { try? handle.close() }
            let data = try handle.read(upToCount: maxBytes + 1) ?? Data()
            guard data.count <= maxBytes else {
                NSLog("Endurain watch bridge: dropped a received session over the size limit")
                return nil
            }
            return data
        } catch {
            NSLog("Endurain watch bridge: could not read a received session")
            return nil
        }
    }

    /// Whether the envelope in [data] is of a version this app can read. An
    /// unparseable envelope counts as readable, so Dart sees (and reports) it.
    static func isReadableVersion(_ data: Data) -> Bool {
        guard let object = try? JSONSerialization.jsonObject(with: data),
              let envelope = object as? [String: Any]
        else {
            return true
        }
        return WatchProtocol.isSupported(version: envelope[WatchProtocol.keyVersion])
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
        guard storeReceivedHandoff(fileURL: file.fileURL, metadata: file.metadata) == .stored else {
            return
        }
        Task { @MainActor [weak self] in
            self?.onHandoffReceived?()
        }
    }

    // MARK: - Private

    private func notifyLinkStatus() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.onLinkStatusChanged?(self.linkStatus)
        }
    }
}
