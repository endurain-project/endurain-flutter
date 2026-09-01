import Foundation

/// Native mirror of the Dart `ActiveActivitySession` model.
///
/// The JSON schema must stay compatible with
/// `lib/features/activity/models/active_activity_session.dart` and the Android
/// `ActiveActivitySessionData` so any recorder can recover sessions written by
/// another. Status values mirror the Dart `ActiveActivityStatus` enum names.
struct ActiveActivitySessionData {
    let localSessionId: String
    let activityType: String
    let status: String
    let startedAt: String
    let connectionOrigin: String?
    let connectionProfileId: String?
    let heartRateDeviceId: String?
    let powerDeviceId: String?
    let cadenceDeviceId: String?
    let resumedAt: String?
    let pausedAt: String?
    let endedAt: String?
    let elapsedDurationSeconds: Int
    let currentSegmentIndex: Int
    let autoPauseEnabled: Bool
    let autoPauseDelaySeconds: Int
    let pausedAutomatically: Bool
    let schemaVersion: Int

    init(
        localSessionId: String,
        activityType: String,
        status: String,
        startedAt: String,
        connectionOrigin: String? = nil,
        connectionProfileId: String? = nil,
        heartRateDeviceId: String? = nil,
        powerDeviceId: String? = nil,
        cadenceDeviceId: String? = nil,
        resumedAt: String? = nil,
        pausedAt: String? = nil,
        endedAt: String? = nil,
        elapsedDurationSeconds: Int = 0,
        currentSegmentIndex: Int = 0,
        autoPauseEnabled: Bool = false,
        autoPauseDelaySeconds: Int = 5,
        pausedAutomatically: Bool = false,
        schemaVersion: Int = ActiveActivitySessionData.schemaVersionValue
    ) {
        self.localSessionId = localSessionId
        self.activityType = activityType
        self.status = status
        self.startedAt = startedAt
        self.connectionOrigin = connectionOrigin
        self.connectionProfileId = connectionProfileId
        self.heartRateDeviceId = heartRateDeviceId
        self.powerDeviceId = powerDeviceId
        self.cadenceDeviceId = cadenceDeviceId
        self.resumedAt = resumedAt
        self.pausedAt = pausedAt
        self.endedAt = endedAt
        self.elapsedDurationSeconds = elapsedDurationSeconds
        self.currentSegmentIndex = currentSegmentIndex
        self.autoPauseEnabled = autoPauseEnabled
        self.autoPauseDelaySeconds = autoPauseDelaySeconds
        self.pausedAutomatically = pausedAutomatically
        self.schemaVersion = schemaVersion
    }

    var isActive: Bool {
        return status == ActiveActivitySessionData.statusRecording
            || status == ActiveActivitySessionData.statusPaused
    }

    var requiresLocationMonitoring: Bool {
        return status == ActiveActivitySessionData.statusRecording
            || (status == ActiveActivitySessionData.statusPaused && pausedAutomatically)
    }

    /// Accumulated elapsed seconds as of `referenceMillis`: a paused session
    /// keeps its stored value; otherwise adds the current segment's running
    /// time from `resumedAt ?? startedAt`. Mirrors the Dart geolocator
    /// recorder and the Android `elapsedSecondsAt`; shared by
    /// `ActivityRecorderChannel` (manual pause/stop/recover) and
    /// `CoreLocationActivityRecorder` (auto-pause).
    func elapsedSecondsAt(_ referenceMillis: Int64) -> Int {
        if status == ActiveActivitySessionData.statusPaused {
            return elapsedDurationSeconds
        }
        guard let anchor = IsoTime.toEpochMillis(resumedAt ?? startedAt) else {
            return elapsedDurationSeconds
        }
        let segmentSeconds = Int((referenceMillis - anchor) / 1000)
        return elapsedDurationSeconds + max(0, segmentSeconds)
    }

    /// Channel-safe / JSON-safe dictionary using the same keys the Dart model
    /// expects. Optional fields are omitted when nil.
    func toMap() -> [String: Any] {
        var map: [String: Any] = [:]
        map["schemaVersion"] = schemaVersion
        map["localSessionId"] = localSessionId
        map["activityType"] = activityType
        map["status"] = status
        map["startedAt"] = startedAt
        if let connectionOrigin = connectionOrigin { map["connectionOrigin"] = connectionOrigin }
        if let connectionProfileId = connectionProfileId { map["connectionProfileId"] = connectionProfileId }
        if let heartRateDeviceId = heartRateDeviceId { map["hrDeviceId"] = heartRateDeviceId }
        if let powerDeviceId = powerDeviceId { map["powerDeviceId"] = powerDeviceId }
        if let cadenceDeviceId = cadenceDeviceId { map["cadenceDeviceId"] = cadenceDeviceId }
        if let resumedAt = resumedAt { map["resumedAt"] = resumedAt }
        if let pausedAt = pausedAt { map["pausedAt"] = pausedAt }
        if let endedAt = endedAt { map["endedAt"] = endedAt }
        map["elapsedDurationSeconds"] = elapsedDurationSeconds
        map["currentSegmentIndex"] = currentSegmentIndex
        map["autoPauseEnabled"] = autoPauseEnabled
        map["autoPauseDelaySeconds"] = autoPauseDelaySeconds
        map["pausedAutomatically"] = pausedAutomatically
        return map
    }

    func toJsonString() -> String? {
        guard
            let data = try? JSONSerialization.data(withJSONObject: toMap()),
            let string = String(data: data, encoding: .utf8)
        else {
            return nil
        }
        return string
    }

    func copyWith(
        status: String? = nil,
        resumedAt: String?? = nil,
        pausedAt: String?? = nil,
        endedAt: String?? = nil,
        elapsedDurationSeconds: Int? = nil,
        currentSegmentIndex: Int? = nil,
        pausedAutomatically: Bool? = nil
    ) -> ActiveActivitySessionData {
        return ActiveActivitySessionData(
            localSessionId: localSessionId,
            activityType: activityType,
            status: status ?? self.status,
            startedAt: startedAt,
            connectionOrigin: connectionOrigin,
            connectionProfileId: connectionProfileId,
            heartRateDeviceId: heartRateDeviceId,
            powerDeviceId: powerDeviceId,
            cadenceDeviceId: cadenceDeviceId,
            resumedAt: resumedAt ?? self.resumedAt,
            pausedAt: pausedAt ?? self.pausedAt,
            endedAt: endedAt ?? self.endedAt,
            elapsedDurationSeconds: elapsedDurationSeconds ?? self.elapsedDurationSeconds,
            currentSegmentIndex: currentSegmentIndex ?? self.currentSegmentIndex,
            autoPauseEnabled: autoPauseEnabled,
            autoPauseDelaySeconds: autoPauseDelaySeconds,
            pausedAutomatically: pausedAutomatically ?? self.pausedAutomatically,
            schemaVersion: schemaVersion
        )
    }

    static func fromJson(_ json: [String: Any]) -> ActiveActivitySessionData? {
        guard
            let localSessionId = json["localSessionId"] as? String,
            !localSessionId.isEmpty,
            let startedAt = json["startedAt"] as? String,
            !startedAt.isEmpty
        else {
            return nil
        }
        return ActiveActivitySessionData(
            localSessionId: localSessionId,
            activityType: (json["activityType"] as? String) ?? "",
            status: (json["status"] as? String) ?? statusFailed,
            startedAt: startedAt,
            connectionOrigin: json["connectionOrigin"] as? String,
            connectionProfileId: json["connectionProfileId"] as? String,
            heartRateDeviceId: json["hrDeviceId"] as? String,
            powerDeviceId: json["powerDeviceId"] as? String,
            cadenceDeviceId: json["cadenceDeviceId"] as? String,
            resumedAt: json["resumedAt"] as? String,
            pausedAt: json["pausedAt"] as? String,
            endedAt: json["endedAt"] as? String,
            elapsedDurationSeconds: JsonScalar.int(json["elapsedDurationSeconds"]) ?? 0,
            currentSegmentIndex: JsonScalar.int(json["currentSegmentIndex"]) ?? 0,
            // Absent on sessions persisted before schema version 3: default to
            // disabled rather than the current app preference, so an
            // in-flight recording recovered after an app update never
            // silently starts auto-pausing.
            autoPauseEnabled: (json["autoPauseEnabled"] as? Bool) ?? false,
            autoPauseDelaySeconds: JsonScalar.int(json["autoPauseDelaySeconds"]) ?? 5,
            pausedAutomatically: (json["pausedAutomatically"] as? Bool) ?? false,
            schemaVersion: JsonScalar.int(json["schemaVersion"]) ?? schemaVersionValue
        )
    }

    static let schemaVersionValue = 3

    static let statusRecording = "recording"
    static let statusPaused = "paused"
    static let statusStopping = "stopping"
    static let statusCompleted = "completed"
    static let statusFailed = "failed"
}

/// Native mirror of the Dart `RecordedActivityPoint` model.
///
/// Uses the same short JSON keys (`t`, `lat`, `lon`, `seg`, ...) so points
/// written here can be drained directly by the Dart channel parser.
struct RecordedActivityPointData {
    let timestamp: String
    let latitude: Double
    let longitude: Double
    let segmentIndex: Int
    let elevationMeters: Double?
    let horizontalAccuracyMeters: Double?
    let verticalAccuracyMeters: Double?
    let headingDegrees: Double?
    let headingAccuracyDegrees: Double?
    let speedMetersPerSecond: Double?
    let speedAccuracyMetersPerSecond: Double?
    let heartRateBpm: Int?
    let powerWatts: Int?
    let cadenceRpm: Int?

    init(
        timestamp: String,
        latitude: Double,
        longitude: Double,
        segmentIndex: Int,
        elevationMeters: Double? = nil,
        horizontalAccuracyMeters: Double? = nil,
        verticalAccuracyMeters: Double? = nil,
        headingDegrees: Double? = nil,
        headingAccuracyDegrees: Double? = nil,
        speedMetersPerSecond: Double? = nil,
        speedAccuracyMetersPerSecond: Double? = nil,
        heartRateBpm: Int? = nil,
        powerWatts: Int? = nil,
        cadenceRpm: Int? = nil
    ) {
        self.timestamp = timestamp
        self.latitude = latitude
        self.longitude = longitude
        self.segmentIndex = segmentIndex
        self.elevationMeters = elevationMeters
        self.horizontalAccuracyMeters = horizontalAccuracyMeters
        self.verticalAccuracyMeters = verticalAccuracyMeters
        self.headingDegrees = headingDegrees
        self.headingAccuracyDegrees = headingAccuracyDegrees
        self.speedMetersPerSecond = speedMetersPerSecond
        self.speedAccuracyMetersPerSecond = speedAccuracyMetersPerSecond
        self.heartRateBpm = heartRateBpm
        self.powerWatts = powerWatts
        self.cadenceRpm = cadenceRpm
    }

    /// Channel-safe / JSON-safe dictionary. Optional fields omitted when nil.
    func toMap() -> [String: Any] {
        var map: [String: Any] = [:]
        map["t"] = timestamp
        map["lat"] = latitude
        map["lon"] = longitude
        map["seg"] = segmentIndex
        if let elevationMeters = elevationMeters { map["ele"] = elevationMeters }
        if let horizontalAccuracyMeters = horizontalAccuracyMeters { map["hAcc"] = horizontalAccuracyMeters }
        if let verticalAccuracyMeters = verticalAccuracyMeters { map["vAcc"] = verticalAccuracyMeters }
        if let headingDegrees = headingDegrees { map["head"] = headingDegrees }
        if let headingAccuracyDegrees = headingAccuracyDegrees { map["headAcc"] = headingAccuracyDegrees }
        if let speedMetersPerSecond = speedMetersPerSecond { map["spd"] = speedMetersPerSecond }
        if let speedAccuracyMetersPerSecond = speedAccuracyMetersPerSecond { map["spdAcc"] = speedAccuracyMetersPerSecond }
        if let heartRateBpm = heartRateBpm { map["hr"] = heartRateBpm }
        if let powerWatts = powerWatts { map["pow"] = powerWatts }
        if let cadenceRpm = cadenceRpm { map["cad"] = cadenceRpm }
        return map
    }

    /// Single JSON line for append-only `points.jsonl` storage.
    func toJsonLine() -> String? {
        guard
            let data = try? JSONSerialization.data(withJSONObject: toMap()),
            let string = String(data: data, encoding: .utf8)
        else {
            return nil
        }
        return string
    }

    static func fromJson(_ json: [String: Any]) -> RecordedActivityPointData? {
        guard let timestamp = json["t"] as? String, !timestamp.isEmpty else {
            return nil
        }
        guard
            let latitude = JsonScalar.double(json["lat"]),
            let longitude = JsonScalar.double(json["lon"])
        else {
            return nil
        }
        if latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180 {
            return nil
        }
        return RecordedActivityPointData(
            timestamp: timestamp,
            latitude: latitude,
            longitude: longitude,
            segmentIndex: JsonScalar.int(json["seg"]) ?? 0,
            elevationMeters: JsonScalar.double(json["ele"]),
            horizontalAccuracyMeters: JsonScalar.double(json["hAcc"]),
            verticalAccuracyMeters: JsonScalar.double(json["vAcc"]),
            headingDegrees: JsonScalar.double(json["head"]),
            headingAccuracyDegrees: JsonScalar.double(json["headAcc"]),
            speedMetersPerSecond: JsonScalar.double(json["spd"]),
            speedAccuracyMetersPerSecond: JsonScalar.double(json["spdAcc"]),
            heartRateBpm: JsonScalar.int(json["hr"]),
            powerWatts: JsonScalar.int(json["pow"]),
            cadenceRpm: JsonScalar.int(json["cad"])
        )
    }

    /// Parses a single stored JSONL line, returning nil for blank or malformed
    /// lines so a single corrupt entry never aborts recovery.
    static func tryParseLine(_ line: String) -> RecordedActivityPointData? {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return nil
        }
        guard
            let data = trimmed.data(using: .utf8),
            let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return nil
        }
        return fromJson(object)
    }
}

/// UTC ISO-8601 helpers compatible with Dart `DateTime.toIso8601String()`.
enum IsoTime {
    static func nowUtc() -> String {
        return format(Date())
    }

    static func format(_ date: Date) -> String {
        return formatter.string(from: date)
    }

    /// Parses an ISO-8601 UTC timestamp to epoch millis at second precision.
    ///
    /// The Dart side always emits `...Z` UTC strings, so fractional seconds and
    /// the trailing `Z` are stripped before parsing. Returns nil on malformed
    /// input.
    static func toEpochMillis(_ iso: String?) -> Int64? {
        guard let iso = iso, !iso.isEmpty else {
            return nil
        }
        var core = iso
        if let dotIndex = core.firstIndex(of: ".") {
            core = String(core[..<dotIndex])
        }
        if core.hasSuffix("Z") {
            core.removeLast()
        }
        guard let date = secondFormatter.date(from: core) else {
            return nil
        }
        return Int64(date.timeIntervalSince1970 * 1000)
    }

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        return formatter
    }()

    private static let secondFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter
    }()
}

/// Lenient scalar parsing for values decoded by `JSONSerialization`, which can
/// yield `NSNumber`, `Int`, or `Double` depending on the source.
enum JsonScalar {
    static func int(_ value: Any?) -> Int? {
        if let intValue = value as? Int { return intValue }
        if let number = value as? NSNumber { return number.intValue }
        if let doubleValue = value as? Double { return Int(doubleValue) }
        return nil
    }

    static func double(_ value: Any?) -> Double? {
        if let doubleValue = value as? Double {
            return doubleValue.isFinite ? doubleValue : nil
        }
        if let number = value as? NSNumber {
            let doubleValue = number.doubleValue
            return doubleValue.isFinite ? doubleValue : nil
        }
        if let intValue = value as? Int { return Double(intValue) }
        return nil
    }
}
