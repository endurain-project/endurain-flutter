import Foundation

/// File-backed store for the in-progress activity recording on iOS.
///
/// Mirrors the Android `ActiveActivityStore` and the Dart active store layout.
/// All files live under app-private application support storage
/// (`Library/Application Support/activity_records/active/`) which matches the
/// path returned by `path_provider`'s `getApplicationSupportDirectory()` so the
/// Dart and native sides agree on the location. Never writes to shared or
/// publicly visible storage.
final class ActiveActivityStore {
    static let shared = ActiveActivityStore()

    private let fileManager = FileManager.default
    private let queue = DispatchQueue(label: "com.endurain.activity.store")

    private init() {}

    private var activeDirectory: URL {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base
            .appendingPathComponent("activity_records", isDirectory: true)
            .appendingPathComponent("active", isDirectory: true)
    }

    private var sessionFile: URL {
        return activeDirectory.appendingPathComponent("session.json", isDirectory: false)
    }

    private var pointsFile: URL {
        return activeDirectory.appendingPathComponent("points.jsonl", isDirectory: false)
    }

    private func ensureDirectory() throws {
        if !fileManager.fileExists(atPath: activeDirectory.path) {
            try fileManager.createDirectory(
                at: activeDirectory,
                withIntermediateDirectories: true
            )
        }
    }

    func saveSession(_ session: ActiveActivitySessionData) {
        queue.sync {
            guard let json = session.toJsonString() else { return }
            do {
                try ensureDirectory()
                try json.data(using: .utf8)?.write(to: sessionFile, options: .atomic)
            } catch {
                // Surface persistence failures via the coordinator; never log
                // the session payload itself.
                ActivityRecorderCoordinator.shared.emitFailed(
                    ActivityRecorderCoordinator.reasonPersistenceFailed
                )
            }
        }
    }

    func loadSession() -> ActiveActivitySessionData? {
        return queue.sync {
            guard
                let data = try? Data(contentsOf: sessionFile),
                let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            else {
                return orphanedSession()
            }
            return ActiveActivitySessionData.fromJson(object) ?? orphanedSession()
        }
    }

    func hasRecoverableData() -> Bool {
        return queue.sync {
            guard let files = try? fileManager.contentsOfDirectory(
                at: activeDirectory,
                includingPropertiesForKeys: nil
            ) else {
                return false
            }
            return !files.isEmpty
        }
    }

    /// Appends already-validated points to the JSONL file. Throws on I/O
    /// failure so callers can surface a typed recorder failure.
    func appendPoints(_ points: [RecordedActivityPointData]) throws {
        if points.isEmpty {
            return
        }
        try queue.sync {
            try ensureDirectory()
            var payload = Data()
            for point in points {
                guard let line = point.toJsonLine() else { continue }
                if let lineData = (line + "\n").data(using: .utf8) {
                    payload.append(lineData)
                }
            }
            if payload.isEmpty {
                return
            }
            if !fileManager.fileExists(atPath: pointsFile.path) {
                try payload.write(to: pointsFile)
            } else {
                // Throwing variants (iOS 13.4+) rather than the ObjC-bridged
                // `seekToEndOfFile()`/`write(_:)`/`closeFile()`, which raise an
                // NSException on I/O failure. Swift cannot catch NSException, so
                // those would bypass the caller's do/catch — which exists
                // specifically to convert an append failure into a typed
                // `persistenceFailed` — and hard-crash the app mid-recording.
                let handle = try FileHandle(forWritingTo: pointsFile)
                defer { try? handle.close() }
                try handle.seekToEnd()
                try handle.write(contentsOf: payload)
            }
        }
    }

    /// Reads persisted points, skipping malformed lines, returning entries at or
    /// after `sinceOffset` (counted across valid points only).
    func readPoints(sinceOffset: Int = 0) throws -> [RecordedActivityPointData] {
        return try queue.sync {
            guard fileManager.fileExists(atPath: pointsFile.path) else {
                return []
            }
            let content = try String(contentsOf: pointsFile, encoding: .utf8)
            var result: [RecordedActivityPointData] = []
            var validIndex = 0
            for rawLine in content.split(separator: "\n", omittingEmptySubsequences: false) {
                guard let point = RecordedActivityPointData.tryParseLine(String(rawLine)) else {
                    continue
                }
                if validIndex >= sinceOffset {
                    result.append(point)
                }
                validIndex += 1
            }
            return result
        }
    }

    func pointCount() -> Int {
        return queue.sync {
            guard let content = try? String(contentsOf: pointsFile, encoding: .utf8) else {
                return 0
            }
            var count = 0
            for rawLine in content.split(separator: "\n", omittingEmptySubsequences: false) {
                if RecordedActivityPointData.tryParseLine(String(rawLine)) != nil {
                    count += 1
                }
            }
            return count
        }
    }

    func lastPoint() -> RecordedActivityPointData? {
        return queue.sync {
            guard let content = try? String(contentsOf: pointsFile, encoding: .utf8) else {
                return nil
            }
            var last: RecordedActivityPointData?
            for rawLine in content.split(separator: "\n", omittingEmptySubsequences: false) {
                if let point = RecordedActivityPointData.tryParseLine(String(rawLine)) {
                    last = point
                }
            }
            return last
        }
    }

    func clear() {
        queue.sync {
            try? fileManager.removeItem(at: activeDirectory)
        }
    }

    private func orphanedSession() -> ActiveActivitySessionData? {
        guard
            let content = try? String(contentsOf: pointsFile, encoding: .utf8)
        else {
            return nil
        }
        let points = content
            .split(separator: "\n", omittingEmptySubsequences: false)
            .compactMap { RecordedActivityPointData.tryParseLine(String($0)) }
        guard let first = points.first, let last = points.last else {
            return nil
        }
        let firstMillis = IsoTime.toEpochMillis(first.timestamp) ?? 0
        let lastMillis = IsoTime.toEpochMillis(last.timestamp) ?? firstMillis
        return ActiveActivitySessionData(
            localSessionId: "recovered_\(Int(fileManager.modificationDate(pointsFile).timeIntervalSince1970))",
            activityType: "other",
            status: ActiveActivitySessionData.statusFailed,
            startedAt: first.timestamp,
            endedAt: last.timestamp,
            elapsedDurationSeconds: max(0, Int((lastMillis - firstMillis) / 1000)),
            currentSegmentIndex: last.segmentIndex
        )
    }
}

private extension FileManager {
    func modificationDate(_ url: URL) -> Date {
        let attributes = try? attributesOfItem(atPath: url.path)
        return attributes?[.modificationDate] as? Date ?? Date(timeIntervalSince1970: 0)
    }
}
