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

    private let activeDirectory: URL
    private let directoryRemover: (URL) throws -> Void
    private let sessionWriter: (Data, URL) throws -> Void

    init(
        activeDirectory: URL? = nil,
        directoryRemover: @escaping (URL) throws -> Void = { url in
            try FileManager.default.removeItem(at: url)
        },
        sessionWriter: @escaping (Data, URL) throws -> Void = { data, url in
            try data.write(to: url, options: .atomic)
        }
    ) {
        self.activeDirectory = activeDirectory
            ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("activity_records", isDirectory: true)
                .appendingPathComponent("active", isDirectory: true)
            self.directoryRemover = directoryRemover
        self.sessionWriter = sessionWriter
    }

    private var sessionFile: URL {
        return activeDirectory.appendingPathComponent("session.json", isDirectory: false)
    }

    private var pointsFile: URL {
        return activeDirectory.appendingPathComponent("points.jsonl", isDirectory: false)
    }

    private var sensorFile: URL {
        return activeDirectory.appendingPathComponent("sensors.jsonl", isDirectory: false)
    }

    private var announcementFile: URL {
        return activeDirectory.appendingPathComponent("announcement.json", isDirectory: false)
    }

    private func ensureDirectory() throws {
        if !fileManager.fileExists(atPath: activeDirectory.path) {
            try fileManager.createDirectory(
                at: activeDirectory,
                withIntermediateDirectories: true
            )
        }
    }

    @discardableResult
    func saveSession(_ session: ActiveActivitySessionData) -> Bool {
        return queue.sync {
            guard let data = session.toJsonString()?.data(using: .utf8) else { return false }
            do {
                try ensureDirectory()
                try sessionWriter(data, sessionFile)
                return true
            } catch {
                // Surface persistence failures via the coordinator; never log
                // the session payload itself.
                ActivityRecorderCoordinator.shared.emitFailed(
                    ActivityRecorderCoordinator.reasonPersistenceFailed
                )
                return false
            }
        }
    }

    func loadSession() -> ActiveActivitySessionData? {
        return queue.sync { loadSessionUnlocked() }
    }

    private func loadSessionUnlocked() -> ActiveActivitySessionData? {
        guard
            let data = try? Data(contentsOf: sessionFile),
            let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return orphanedSession()
        }
        return ActiveActivitySessionData.fromJson(object) ?? orphanedSession()
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
            try appendLogData(payload, to: pointsFile)
        }
    }

    enum SensorError: Error {
        case invalidSession
    }

    func appendSensorSample(_ sample: RecordedSensorSampleData, localSessionId: String) throws {
        try queue.sync {
            guard let session = loadSessionUnlocked(),
                  session.localSessionId == localSessionId,
                  session.status == ActiveActivitySessionData.statusRecording else {
                throw SensorError.invalidSession
            }
            var payload = try JSONSerialization.data(withJSONObject: sample.toMap())
            payload.append(10)
            try appendLogData(payload, to: sensorFile)
        }
    }

    func readSensorSamples(localSessionId: String) throws -> [RecordedSensorSampleData] {
        return try queue.sync {
            guard loadSessionUnlocked()?.localSessionId == localSessionId else {
                throw SensorError.invalidSession
            }
            guard fileManager.fileExists(atPath: sensorFile.path) else {
                return []
            }
            let content = try String(contentsOf: sensorFile, encoding: .utf8)
            return content.split(separator: "\n").compactMap { line in
                guard let data = String(line).data(using: .utf8),
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    return nil
                }
                return RecordedSensorSampleData.fromJson(json)
            }
        }
    }

    private func appendLogData(_ payload: Data, to file: URL) throws {
        if !fileManager.fileExists(atPath: file.path) {
            guard fileManager.createFile(atPath: file.path, contents: nil) else {
                throw CocoaError(.fileWriteUnknown)
            }
        }
        let handle = try FileHandle(forUpdating: file)
        defer { try? handle.close() }
        let endOffset = try handle.seekToEnd()
        if endOffset > 0 {
            try handle.seek(toOffset: endOffset - 1)
            let lastByte = try handle.read(upToCount: 1)
            try handle.seekToEnd()
            if lastByte != Data([10]) {
                try handle.write(contentsOf: Data([10]))
            }
        }
        try handle.write(contentsOf: payload)
        try handle.synchronize()
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

    @discardableResult
    func clear() -> Bool {
        return queue.sync {
            do {
                if fileManager.fileExists(atPath: activeDirectory.path) {
                    try directoryRemover(activeDirectory)
                }
                return true
            } catch {
                ActivityRecorderCoordinator.shared.emitFailed(
                    ActivityRecorderCoordinator.reasonPersistenceFailed
                )
                return false
            }
        }
    }

    /// Persists the audio-announcement config + progress for the active
    /// recording. Lives inside the same active-recording directory as the
    /// session/points files, so `clear()` removes it too and
    /// `hasRecoverableData()` keeps working unchanged.
    @discardableResult
    func saveAnnouncementState(_ state: AnnouncementStateData) -> Bool {
        return queue.sync {
            guard let json = state.toJsonString() else { return false }
            do {
                try ensureDirectory()
                try json.data(using: .utf8)?.write(to: announcementFile, options: .atomic)
                return true
            } catch {
                // Losing this write only risks a duplicate or skipped
                // announcement on the next fix, never the recorded track.
                return false
            }
        }
    }

    /// Returns the persisted announcement state, or `nil` when absent/corrupt.
    func loadAnnouncementState() -> AnnouncementStateData? {
        return queue.sync {
            guard
                let data = try? Data(contentsOf: announcementFile),
                let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            else {
                return nil
            }
            return AnnouncementStateData.fromJson(object)
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
