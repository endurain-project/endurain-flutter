import Foundation

/// Durable store of session handoffs, one JSON file per session.
///
/// The phone uses it as the inbox of sessions received from the watch, and
/// the watch as the outbox of sessions waiting for the phone's
/// acknowledgement. Writes are atomic, so a crash leaves either the previous
/// file or the new one, never a partial one.
///
/// File names are the hex encoding of the session id's UTF-8 bytes: injective
/// (two sessions never share a file), safe on any file system, and reversible,
/// so listing the directory yields the session ids without reading the files.
///
/// Used from the WatchConnectivity delegate queue, an I/O queue and the main
/// actor at once. It is `Sendable` because its only state is on disk and
/// every read-modify-write of the directory runs under [lock]; it stays
/// synchronous (not an actor) because a received file must be stored before
/// the WatchConnectivity callback returns.
final class HandoffFileStore: Sendable {
    struct Entry: Sendable {
        let sessionId: String
        let url: URL

        /// When the watch's transfer of this entry to the phone finished, or
        /// nil while it has not been delivered. Unused by the phone's inbox.
        let deliveredAt: Date?
    }

    enum StoreError: Error {
        /// The session id is empty or too long to name a file.
        case invalidSessionId
    }

    /// File names are limited to 255 bytes; hex doubles the length.
    static let maxSessionIdBytes = 120

    private static let pendingExtension = "json"
    private static let deliveredSuffix = ".delivered.json"

    let directory: URL
    private let lock = NSLock()

    /// The shared manager is thread-safe; a stored one would not be Sendable.
    private var fileManager: FileManager {
        return FileManager.default
    }

    init(directory: URL) {
        self.directory = directory
    }

    /// Stores [data] as the handoff of [sessionId], replacing any earlier copy
    /// (including a delivered one) so a re-sent session is kept once.
    func save(_ data: Data, sessionId: String) throws {
        let name = try Self.fileStem(for: sessionId)
        lock.lock()
        defer { lock.unlock() }
        try ensureDirectory()
        try data.write(to: pendingURL(stem: name), options: .atomic)
        removeIfPresent(deliveredURL(stem: name))
    }

    func data(for sessionId: String) -> Data? {
        guard let entry = entry(for: sessionId) else {
            return nil
        }
        return try? Data(contentsOf: entry.url)
    }

    func entry(for sessionId: String) -> Entry? {
        return ((try? entries()) ?? []).first { $0.sessionId == sessionId }
    }

    /// Every stored handoff, oldest first.
    ///
    /// Throws only when the directory exists but cannot be listed; a missing
    /// directory is an empty store.
    func entries() throws -> [Entry] {
        lock.lock()
        defer { lock.unlock() }
        guard fileManager.fileExists(atPath: directory.path) else {
            return []
        }
        let urls = try fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )
        var result: [(entry: Entry, modified: Date)] = []
        for url in urls {
            let name = url.lastPathComponent
            let delivered = name.hasSuffix(Self.deliveredSuffix)
            let stem: String
            if delivered {
                stem = String(name.dropLast(Self.deliveredSuffix.count))
            } else if url.pathExtension == Self.pendingExtension {
                stem = url.deletingPathExtension().lastPathComponent
            } else {
                continue
            }
            guard let sessionId = Self.sessionId(fromStem: stem) else {
                continue
            }
            let modified = (try? url.resourceValues(
                forKeys: [.contentModificationDateKey]
            ).contentModificationDate) ?? .distantPast
            result.append((
                Entry(
                    sessionId: sessionId,
                    url: url,
                    deliveredAt: delivered ? modified : nil
                ),
                modified
            ))
        }
        return result
            .sorted { $0.modified < $1.modified }
            .map { $0.entry }
    }

    var isEmpty: Bool {
        return ((try? entries()) ?? []).isEmpty
    }

    /// Records that the transfer of [sessionId] finished. The file is kept,
    /// renamed, until the acknowledgement arrives. A repeated delivery of an
    /// already delivered entry (see [entriesToTransfer]) restarts its clock.
    func markDelivered(_ sessionId: String, at date: Date = Date()) {
        guard let stem = try? Self.fileStem(for: sessionId) else {
            return
        }
        lock.lock()
        defer { lock.unlock() }
        let pending = pendingURL(stem: stem)
        let delivered = deliveredURL(stem: stem)
        do {
            if fileManager.fileExists(atPath: pending.path) {
                removeIfPresent(delivered)
                try fileManager.moveItem(at: pending, to: delivered)
            } else if !fileManager.fileExists(atPath: delivered.path) {
                return
            }
            try fileManager.setAttributes(
                [.modificationDate: date],
                ofItemAtPath: delivered.path
            )
        } catch {
            NSLog("Endurain watch store: could not mark a session delivered")
        }
    }

    /// The entries the watch should transfer: every one not yet delivered,
    /// and every delivered one still unacknowledged since before
    /// [redeliverDeliveredBefore].
    ///
    /// A delivered file is not proof the phone kept it: the phone can fail
    /// to read or store it, and then never acknowledges it. Sending it again
    /// is safe because the phone stores one copy per session and Dart
    /// ignores a session it already has.
    func entriesToTransfer(redeliverDeliveredBefore date: Date) -> [Entry] {
        return ((try? entries()) ?? []).filter { entry in
            guard let deliveredAt = entry.deliveredAt else { return true }
            return deliveredAt <= date
        }
    }

    func remove(_ sessionId: String) {
        guard let stem = try? Self.fileStem(for: sessionId) else {
            return
        }
        lock.lock()
        defer { lock.unlock() }
        removeIfPresent(pendingURL(stem: stem))
        removeIfPresent(deliveredURL(stem: stem))
    }

    // MARK: - File names

    static func fileStem(for sessionId: String) throws -> String {
        let bytes = Array(sessionId.utf8)
        guard !bytes.isEmpty, bytes.count <= maxSessionIdBytes else {
            throw StoreError.invalidSessionId
        }
        return bytes.map { String(format: "%02x", $0) }.joined()
    }

    static func sessionId(fromStem stem: String) -> String? {
        guard !stem.isEmpty, stem.count % 2 == 0 else {
            return nil
        }
        var bytes: [UInt8] = []
        bytes.reserveCapacity(stem.count / 2)
        var index = stem.startIndex
        while index < stem.endIndex {
            let next = stem.index(index, offsetBy: 2)
            guard let byte = UInt8(stem[index..<next], radix: 16) else {
                return nil
            }
            bytes.append(byte)
            index = next
        }
        return String(bytes: bytes, encoding: .utf8)
    }

    // MARK: - Private

    private func pendingURL(stem: String) -> URL {
        return directory.appendingPathComponent("\(stem).\(Self.pendingExtension)")
    }

    private func deliveredURL(stem: String) -> URL {
        return directory.appendingPathComponent("\(stem)\(Self.deliveredSuffix)")
    }

    private func ensureDirectory() throws {
        guard !fileManager.fileExists(atPath: directory.path) else {
            return
        }
        try fileManager.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        // Workout routes and heart rate are health data: keep them out of
        // device and iCloud backups.
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        var mutableDirectory = directory
        try? mutableDirectory.setResourceValues(values)
    }

    private func removeIfPresent(_ url: URL) {
        if fileManager.fileExists(atPath: url.path) {
            try? fileManager.removeItem(at: url)
        }
    }
}
