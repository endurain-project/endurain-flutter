import Foundation

/// Activity types the watch can record, by their Endurain API value (the Dart
/// `ActivityType.apiValue`).
enum WatchActivityType: String, CaseIterable, Codable {
    case run
    case ride
    case walk
    case hike
}

/// Timing state of a workout being recorded on the watch.
///
/// Persisted on every pause and resume, so a session interrupted by a crash
/// can still be finished with the right duration. Each resume starts a new
/// segment, matching the phone recorders, so a pause shows as a track break.
struct WatchRecording: Codable, Equatable {
    let sessionId: String
    let activityType: WatchActivityType
    let startedAt: Date
    private(set) var segmentIndex: Int = 0

    /// Active time accumulated before the current run of the clock.
    private(set) var activeSecondsBeforeCurrentRun: TimeInterval = 0

    /// When the clock last started; nil while paused.
    private(set) var currentRunStartedAt: Date?

    init(sessionId: String, activityType: WatchActivityType, startedAt: Date) {
        self.sessionId = sessionId
        self.activityType = activityType
        self.startedAt = startedAt
        self.currentRunStartedAt = startedAt
    }

    var isPaused: Bool {
        return currentRunStartedAt == nil
    }

    /// Active (unpaused) seconds as of [date].
    func elapsedSeconds(at date: Date) -> TimeInterval {
        guard let runStart = currentRunStartedAt else {
            return activeSecondsBeforeCurrentRun
        }
        return activeSecondsBeforeCurrentRun + max(0, date.timeIntervalSince(runStart))
    }

    mutating func pause(at date: Date) {
        guard !isPaused else { return }
        activeSecondsBeforeCurrentRun = elapsedSeconds(at: date)
        currentRunStartedAt = nil
    }

    mutating func resume(at date: Date) {
        guard isPaused else { return }
        currentRunStartedAt = date
        segmentIndex += 1
    }
}

/// One GPS fix recorded on the watch.
///
/// Serializes with the short keys of the Dart `RecordedActivityPoint`, so the
/// phone can hand the points to Dart unchanged.
struct WatchRecordedPoint: Equatable {
    let timestamp: Date
    let latitude: Double
    let longitude: Double
    let segmentIndex: Int
    var elevationMeters: Double?
    var horizontalAccuracyMeters: Double?
    var verticalAccuracyMeters: Double?
    var headingDegrees: Double?
    var speedMetersPerSecond: Double?
    var speedAccuracyMetersPerSecond: Double?
    var heartRateBpm: Int?

    func jsonObject() -> [String: Any] {
        var json: [String: Any] = [
            "t": WatchProtocol.timestamp(timestamp),
            "lat": latitude,
            "lon": longitude,
            "seg": segmentIndex,
        ]
        if let elevationMeters { json["ele"] = elevationMeters }
        if let horizontalAccuracyMeters { json["hAcc"] = horizontalAccuracyMeters }
        if let verticalAccuracyMeters { json["vAcc"] = verticalAccuracyMeters }
        if let headingDegrees { json["head"] = headingDegrees }
        if let speedMetersPerSecond { json["spd"] = speedMetersPerSecond }
        if let speedAccuracyMetersPerSecond { json["spdAcc"] = speedAccuracyMetersPerSecond }
        if let heartRateBpm { json["hr"] = heartRateBpm }
        return json
    }

    init(
        timestamp: Date,
        latitude: Double,
        longitude: Double,
        segmentIndex: Int,
        elevationMeters: Double? = nil,
        horizontalAccuracyMeters: Double? = nil,
        verticalAccuracyMeters: Double? = nil,
        headingDegrees: Double? = nil,
        speedMetersPerSecond: Double? = nil,
        speedAccuracyMetersPerSecond: Double? = nil,
        heartRateBpm: Int? = nil
    ) {
        self.timestamp = timestamp
        self.latitude = latitude
        self.longitude = longitude
        self.segmentIndex = segmentIndex
        self.elevationMeters = elevationMeters
        self.horizontalAccuracyMeters = horizontalAccuracyMeters
        self.verticalAccuracyMeters = verticalAccuracyMeters
        self.headingDegrees = headingDegrees
        self.speedMetersPerSecond = speedMetersPerSecond
        self.speedAccuracyMetersPerSecond = speedAccuracyMetersPerSecond
        self.heartRateBpm = heartRateBpm
    }

    init?(json: [String: Any]) {
        guard let time = json["t"] as? String,
              let timestamp = WatchProtocol.date(fromTimestamp: time),
              let latitude = Self.double(json["lat"]),
              let longitude = Self.double(json["lon"]),
              (-90...90).contains(latitude),
              (-180...180).contains(longitude)
        else {
            return nil
        }
        self.init(
            timestamp: timestamp,
            latitude: latitude,
            longitude: longitude,
            segmentIndex: (json["seg"] as? NSNumber)?.intValue ?? 0,
            elevationMeters: Self.double(json["ele"]),
            horizontalAccuracyMeters: Self.double(json["hAcc"]),
            verticalAccuracyMeters: Self.double(json["vAcc"]),
            headingDegrees: Self.double(json["head"]),
            speedMetersPerSecond: Self.double(json["spd"]),
            speedAccuracyMetersPerSecond: Self.double(json["spdAcc"]),
            heartRateBpm: (json["hr"] as? NSNumber)?.intValue
        )
    }

    private static func double(_ value: Any?) -> Double? {
        guard let number = value as? NSNumber else { return nil }
        let result = number.doubleValue
        return result.isFinite ? result : nil
    }
}

/// Durable copy of the workout being recorded on the watch: the timing state
/// in `recording.json` and the points appended to `points.jsonl`.
///
/// Lets a workout interrupted by a crash or a forced quit be resumed, or at
/// least finished and sent, instead of being lost.
final class WatchRecordingStore {
    let directory: URL
    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(directory: URL) {
        self.directory = directory
    }

    private var recordingURL: URL {
        return directory.appendingPathComponent("recording.json")
    }

    private var pointsURL: URL {
        return directory.appendingPathComponent("points.jsonl")
    }

    /// Starts a new recording, discarding any previous one.
    func begin(_ recording: WatchRecording) throws {
        clear()
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        var mutableDirectory = directory
        try? mutableDirectory.setResourceValues(values)
        try update(recording)
        try Data().write(to: pointsURL, options: .atomic)
    }

    func update(_ recording: WatchRecording) throws {
        try encoder.encode(recording).write(to: recordingURL, options: .atomic)
    }

    func append(_ points: [WatchRecordedPoint]) throws {
        guard !points.isEmpty else { return }
        var lines = Data()
        for point in points {
            let line = try JSONSerialization.data(withJSONObject: point.jsonObject())
            lines.append(line)
            lines.append(0x0A)
        }
        if !fileManager.fileExists(atPath: pointsURL.path) {
            try Data().write(to: pointsURL, options: .atomic)
        }
        let handle = try FileHandle(forUpdating: pointsURL)
        defer { try? handle.close() }
        let end = try handle.seekToEnd()
        if end > 0 {
            // A crash can cut the last line short. Terminate it first, or the
            // new points would be glued onto it and lost with it on load.
            try handle.seek(toOffset: end - 1)
            if try handle.read(upToCount: 1) != Data([0x0A]) {
                lines.insert(0x0A, at: 0)
            }
            try handle.seekToEnd()
        }
        try handle.write(contentsOf: lines)
    }

    /// The unfinished recording and its points, or nil when there is none.
    /// A corrupt line (for example one cut short by a crash) is skipped.
    func load() -> (recording: WatchRecording, points: [WatchRecordedPoint])? {
        guard let data = try? Data(contentsOf: recordingURL),
              let recording = try? decoder.decode(WatchRecording.self, from: data)
        else {
            return nil
        }
        var points: [WatchRecordedPoint] = []
        if let contents = try? Data(contentsOf: pointsURL) {
            for line in contents.split(separator: 0x0A) where !line.isEmpty {
                guard let object = try? JSONSerialization.jsonObject(with: Data(line)),
                      let json = object as? [String: Any],
                      let point = WatchRecordedPoint(json: json)
                else {
                    continue
                }
                points.append(point)
            }
        }
        return (recording, points)
    }

    func clear() {
        if fileManager.fileExists(atPath: directory.path) {
            try? fileManager.removeItem(at: directory)
        }
    }
}
