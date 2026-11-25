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
final class HandoffFileStore {
    struct Entry {
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
    private let fileManager = FileManager.default
    private let lock = NSLock()

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
    /// renamed, until the acknowledgement arrives or [pruneDelivered] drops it.
    func markDelivered(_ sessionId: String, at date: Date = Date()) {
        guard let stem = try? Self.fileStem(for: sessionId) else {
            return
        }
        lock.lock()
        defer { lock.unlock() }
        let pending = pendingURL(stem: stem)
        let delivered = deliveredURL(stem: stem)
        guard fileManager.fileExists(atPath: pending.path) else {
            return
        }
        removeIfPresent(delivered)
        do {
            try fileManager.moveItem(at: pending, to: delivered)
            try fileManager.setAttributes(
                [.modificationDate: date],
                ofItemAtPath: delivered.path
            )
        } catch {
            NSLog("Endurain watch store: could not mark a session delivered")
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

    /// Drops delivered entries older than [date] whose acknowledgement never
    /// came. The phone holds its own copy of each, so nothing is lost.
    func pruneDelivered(olderThan date: Date) {
        let stale = ((try? entries()) ?? []).filter { entry in
            guard let deliveredAt = entry.deliveredAt else { return false }
            return deliveredAt < date
        }
        lock.lock()
        defer { lock.unlock() }
        for entry in stale {
            removeIfPresent(entry.url)
        }
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
