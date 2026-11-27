import Foundation
import os

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
    private static let log = AppLogger.make(category: "HandoffFileStore")

    struct Entry: Sendable {
        let sessionId: String
        let url: URL

        /// When the watch's transfer of this entry to the phone finished, or
        /// nil while it has not been delivered. Unused by the phone's inbox.
        let deliveredAt: Date?

        /// How many times the watch's transfer of this entry finished without
        /// the phone acknowledging it. Zero until the first delivery.
        let deliveryAttempts: Int
    }

    enum StoreError: Error {
        /// The session id is empty or too long to name a file.
        case invalidSessionId
    }

    /// File names are limited to 255 bytes; hex doubles the length.
    static let maxSessionIdBytes = 120

    private static let pendingExtension = "json"
    private static let deliveredSuffix = ".delivered.json"
    private static let attemptsExtension = "attempts"

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
        removeIfPresent(attemptsURL(stem: name))
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
                    deliveredAt: delivered ? modified : nil,
                    deliveryAttempts: delivered ? readAttempts(stem: stem) : 0
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
    /// already delivered entry (see [entriesToTransfer]) restarts its clock
    /// and counts as another unacknowledged attempt, which lengthens the wait
    /// before the next one.
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
            try writeAttempts(readAttempts(stem: stem) + 1, stem: stem)
        } catch {
            Self.log.error("Could not mark a session delivered: \(error.localizedDescription, privacy: .private)")
        }
    }

    /// The entries the watch should transfer: every one not yet delivered,
    /// and every delivered one still unacknowledged when its backoff has run
    /// out (see [redeliveryDelay]).
    ///
    /// A delivered file is not proof the phone kept it: the phone can fail
    /// to read or store it, and then never acknowledges it. Sending it again
    /// is safe because the phone stores one copy per session and Dart
    /// ignores a session it already has. A file the phone can never accept
    /// would otherwise be resent forever at a fixed rate, so the wait doubles
    /// with every unacknowledged delivery, up to [maxDelay]. The workout is
    /// never deleted.
    func entriesToTransfer(
        at now: Date = Date(),
        baseDelay: TimeInterval,
        maxDelay: TimeInterval
    ) -> [Entry] {
        return ((try? entries()) ?? []).filter { entry in
            guard let deliveredAt = entry.deliveredAt else { return true }
            let delay = Self.redeliveryDelay(
                afterAttempts: entry.deliveryAttempts,
                baseDelay: baseDelay,
                maxDelay: maxDelay
            )
            return deliveredAt.addingTimeInterval(delay) <= now
        }
    }

    /// How long a delivered entry waits for the acknowledgement before the
    /// next delivery: [baseDelay] after the first one, doubling after each
    /// further one, never more than [maxDelay].
    static func redeliveryDelay(
        afterAttempts attempts: Int,
        baseDelay: TimeInterval,
        maxDelay: TimeInterval
    ) -> TimeInterval {
        let doublings = min(max(attempts - 1, 0), 30)
        return min(baseDelay * Double(1 << doublings), maxDelay)
    }

    func remove(_ sessionId: String) {
        guard let stem = try? Self.fileStem(for: sessionId) else {
            return
        }
        lock.lock()
        defer { lock.unlock() }
        removeIfPresent(pendingURL(stem: stem))
        removeIfPresent(deliveredURL(stem: stem))
        removeIfPresent(attemptsURL(stem: stem))
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

    private func attemptsURL(stem: String) -> URL {
        return directory.appendingPathComponent("\(stem).\(Self.attemptsExtension)")
    }

    /// Called with [lock] held.
    private func readAttempts(stem: String) -> Int {
        guard let data = try? Data(contentsOf: attemptsURL(stem: stem)),
              let text = String(data: data, encoding: .utf8),
              let count = Int(text.trimmingCharacters(in: .whitespacesAndNewlines))
        else {
            return 0
        }
        return max(count, 0)
    }

    /// Called with [lock] held.
    private func writeAttempts(_ count: Int, stem: String) throws {
        try Data(String(count).utf8).write(to: attemptsURL(stem: stem), options: .atomic)
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
        try? WatchStorage.excludeFromBackup(directory)
    }

    private func removeIfPresent(_ url: URL) {
        if fileManager.fileExists(atPath: url.path) {
            try? fileManager.removeItem(at: url)
        }
    }
}
