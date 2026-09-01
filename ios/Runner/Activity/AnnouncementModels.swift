import Foundation

/// Durable state for the spoken progress announcements of one recording:
/// the immutable, localized configuration handed over at `start` (see the
/// Dart `AudioAnnouncementConfig`) plus the mutable progress the on-device
/// scheduler advances from location fixes and elapsed-time callbacks.
///
/// Mirrors the Android `AnnouncementStateData` data class. Persisted as its
/// own file inside the same active-recording directory as
/// `ActiveActivityStore`'s session/points files (see
/// `ActiveActivityStore.saveAnnouncementState`), so `clear()` (called on
/// discard) removes it too, and the "already announced" bookkeeping survives
/// whatever iOS process lifecycle event happens between scheduler callbacks.
///
/// Deliberately kept separate from `ActiveActivitySessionData`: that model's
/// JSON schema is a durability contract shared with Dart and Android, and
/// announcement bookkeeping is a native-only concern that never crosses the
/// platform channel after `start`.
struct AnnouncementStateData: Equatable {
    // Immutable config, supplied once at `start`.
    let enabled: Bool
    let duckOtherAudio: Bool
    let intervalUnit: String
    let distanceIntervalMeters: Double
    let timeIntervalSeconds: Int
    let useImperialUnits: Bool
    let metric: String
    let languageTag: String
    let distanceUnitTemplate: String
    let metricUnitTemplate: String
    let metricLabel: String
    let messageTemplate: String
    let autoPausedMessage: String
    let autoResumedMessage: String
    // Scheduler progress, checkpointed from GPS fixes and the elapsed-time timer.
    var cumulativeDistanceMeters: Double
    var lastAnnouncedDistanceIndex: Int
    var lastAnnouncedTimeIndex: Int
    var lastLatitude: Double?
    var lastLongitude: Double?
    var lastElapsedSeconds: Int
    var lastAnnouncementDistanceMeters: Double
    var lastAnnouncementElapsedSeconds: Int

    static let unitDistance = "distance"
    static let unitTime = "time"
    static let metricPace = "pace"
    static let metricSpeed = "speed"

    init(
        enabled: Bool,
        duckOtherAudio: Bool,
        intervalUnit: String,
        distanceIntervalMeters: Double,
        timeIntervalSeconds: Int,
        useImperialUnits: Bool,
        metric: String,
        languageTag: String,
        distanceUnitTemplate: String,
        metricUnitTemplate: String,
        metricLabel: String,
        messageTemplate: String,
        autoPausedMessage: String = "",
        autoResumedMessage: String = "",
        cumulativeDistanceMeters: Double = 0,
        lastAnnouncedDistanceIndex: Int = 0,
        lastAnnouncedTimeIndex: Int = 0,
        lastLatitude: Double? = nil,
        lastLongitude: Double? = nil,
        lastElapsedSeconds: Int = 0,
        lastAnnouncementDistanceMeters: Double = 0,
        lastAnnouncementElapsedSeconds: Int = 0
    ) {
        self.enabled = enabled
        self.duckOtherAudio = duckOtherAudio
        self.intervalUnit = intervalUnit
        self.distanceIntervalMeters = distanceIntervalMeters
        self.timeIntervalSeconds = timeIntervalSeconds
        self.useImperialUnits = useImperialUnits
        self.metric = metric
        self.languageTag = languageTag
        self.distanceUnitTemplate = distanceUnitTemplate
        self.metricUnitTemplate = metricUnitTemplate
        self.metricLabel = metricLabel
        self.messageTemplate = messageTemplate
        self.autoPausedMessage = autoPausedMessage
        self.autoResumedMessage = autoResumedMessage
        self.cumulativeDistanceMeters = cumulativeDistanceMeters
        self.lastAnnouncedDistanceIndex = lastAnnouncedDistanceIndex
        self.lastAnnouncedTimeIndex = lastAnnouncedTimeIndex
        self.lastLatitude = lastLatitude
        self.lastLongitude = lastLongitude
        self.lastElapsedSeconds = lastElapsedSeconds
        self.lastAnnouncementDistanceMeters = lastAnnouncementDistanceMeters
        self.lastAnnouncementElapsedSeconds = lastAnnouncementElapsedSeconds
    }

    var isTimeBased: Bool {
        return intervalUnit == AnnouncementStateData.unitTime
    }

    func transitionMessage(autoPaused: Bool) -> String? {
        guard enabled else {
            return nil
        }
        let message = autoPaused ? autoPausedMessage : autoResumedMessage
        return message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? nil
            : message
    }

    func copyWith(
        cumulativeDistanceMeters: Double? = nil,
        lastAnnouncedDistanceIndex: Int? = nil,
        lastAnnouncedTimeIndex: Int? = nil,
        lastLatitude: Double?? = nil,
        lastLongitude: Double?? = nil,
        lastElapsedSeconds: Int? = nil,
        lastAnnouncementDistanceMeters: Double? = nil,
        lastAnnouncementElapsedSeconds: Int? = nil
    ) -> AnnouncementStateData {
        return AnnouncementStateData(
            enabled: enabled,
            duckOtherAudio: duckOtherAudio,
            intervalUnit: intervalUnit,
            distanceIntervalMeters: distanceIntervalMeters,
            timeIntervalSeconds: timeIntervalSeconds,
            useImperialUnits: useImperialUnits,
            metric: metric,
            languageTag: languageTag,
            distanceUnitTemplate: distanceUnitTemplate,
            metricUnitTemplate: metricUnitTemplate,
            metricLabel: metricLabel,
            messageTemplate: messageTemplate,
            autoPausedMessage: autoPausedMessage,
            autoResumedMessage: autoResumedMessage,
            cumulativeDistanceMeters: cumulativeDistanceMeters ?? self.cumulativeDistanceMeters,
            lastAnnouncedDistanceIndex: lastAnnouncedDistanceIndex ?? self.lastAnnouncedDistanceIndex,
            lastAnnouncedTimeIndex: lastAnnouncedTimeIndex ?? self.lastAnnouncedTimeIndex,
            lastLatitude: lastLatitude ?? self.lastLatitude,
            lastLongitude: lastLongitude ?? self.lastLongitude,
            lastElapsedSeconds: lastElapsedSeconds ?? self.lastElapsedSeconds,
            lastAnnouncementDistanceMeters: lastAnnouncementDistanceMeters
                ?? self.lastAnnouncementDistanceMeters,
            lastAnnouncementElapsedSeconds: lastAnnouncementElapsedSeconds
                ?? self.lastAnnouncementElapsedSeconds
        )
    }

    func toMap() -> [String: Any] {
        var map: [String: Any] = [:]
        map["enabled"] = enabled
        map["duckOtherAudio"] = duckOtherAudio
        map["intervalUnit"] = intervalUnit
        map["distanceIntervalMeters"] = distanceIntervalMeters
        map["timeIntervalSeconds"] = timeIntervalSeconds
        map["useImperialUnits"] = useImperialUnits
        map["metric"] = metric
        map["languageTag"] = languageTag
        map["distanceUnitTemplate"] = distanceUnitTemplate
        map["metricUnitTemplate"] = metricUnitTemplate
        map["metricLabel"] = metricLabel
        map["messageTemplate"] = messageTemplate
        map["autoPausedMessage"] = autoPausedMessage
        map["autoResumedMessage"] = autoResumedMessage
        map["cumulativeDistanceMeters"] = cumulativeDistanceMeters
        map["lastAnnouncedDistanceIndex"] = lastAnnouncedDistanceIndex
        map["lastAnnouncedTimeIndex"] = lastAnnouncedTimeIndex
        if let lastLatitude = lastLatitude { map["lastLatitude"] = lastLatitude }
        if let lastLongitude = lastLongitude { map["lastLongitude"] = lastLongitude }
        map["lastElapsedSeconds"] = lastElapsedSeconds
        map["lastAnnouncementDistanceMeters"] = lastAnnouncementDistanceMeters
        map["lastAnnouncementElapsedSeconds"] = lastAnnouncementElapsedSeconds
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

    static func fromJson(_ json: [String: Any]) -> AnnouncementStateData? {
        guard let languageTag = json["languageTag"] as? String else {
            return nil
        }
        return AnnouncementStateData(
            enabled: (json["enabled"] as? Bool) ?? false,
            duckOtherAudio: (json["duckOtherAudio"] as? Bool) ?? true,
            intervalUnit: (json["intervalUnit"] as? String) ?? unitDistance,
            distanceIntervalMeters: JsonScalar.double(json["distanceIntervalMeters"]) ?? 1000,
            timeIntervalSeconds: JsonScalar.int(json["timeIntervalSeconds"]) ?? 300,
            useImperialUnits: (json["useImperialUnits"] as? Bool) ?? false,
            metric: (json["metric"] as? String) ?? metricPace,
            languageTag: languageTag,
            distanceUnitTemplate: (json["distanceUnitTemplate"] as? String) ?? "{value}",
            metricUnitTemplate: (json["metricUnitTemplate"] as? String) ?? "{value}",
            metricLabel: (json["metricLabel"] as? String) ?? "",
            messageTemplate: (json["messageTemplate"] as? String)
                ?? "{distance} {duration} {lapMetric} {overallMetric}",
            autoPausedMessage: (json["autoPausedMessage"] as? String) ?? "",
            autoResumedMessage: (json["autoResumedMessage"] as? String) ?? "",
            cumulativeDistanceMeters: JsonScalar.double(json["cumulativeDistanceMeters"]) ?? 0,
            lastAnnouncedDistanceIndex: JsonScalar.int(json["lastAnnouncedDistanceIndex"]) ?? 0,
            lastAnnouncedTimeIndex: JsonScalar.int(json["lastAnnouncedTimeIndex"]) ?? 0,
            lastLatitude: JsonScalar.double(json["lastLatitude"]),
            lastLongitude: JsonScalar.double(json["lastLongitude"]),
            lastElapsedSeconds: JsonScalar.int(json["lastElapsedSeconds"]) ?? 0,
            lastAnnouncementDistanceMeters:
                JsonScalar.double(json["lastAnnouncementDistanceMeters"]) ?? 0,
            lastAnnouncementElapsedSeconds:
                JsonScalar.int(json["lastAnnouncementElapsedSeconds"]) ?? 0
        )
    }

    /// Parses the `audioAnnouncements` argument dictionary sent by Dart's
    /// `start` method call. Returns `nil` when the argument is absent
    /// (recorders that never enabled announcements never write this file at
    /// all).
    static func fromStartArguments(_ map: [String: Any]?) -> AnnouncementStateData? {
        guard let map = map, let languageTag = map["languageTag"] as? String else {
            return nil
        }
        return AnnouncementStateData(
            enabled: (map["enabled"] as? Bool) ?? false,
            duckOtherAudio: (map["duckOtherAudio"] as? Bool) ?? true,
            intervalUnit: (map["intervalUnit"] as? String) ?? unitDistance,
            distanceIntervalMeters: JsonScalar.double(map["distanceIntervalMeters"]) ?? 1000,
            timeIntervalSeconds: JsonScalar.int(map["timeIntervalSeconds"]) ?? 300,
            useImperialUnits: (map["useImperialUnits"] as? Bool) ?? false,
            metric: (map["metric"] as? String) ?? metricPace,
            languageTag: languageTag,
            distanceUnitTemplate: (map["distanceUnitTemplate"] as? String) ?? "{value}",
            metricUnitTemplate: (map["metricUnitTemplate"] as? String) ?? "{value}",
            metricLabel: (map["metricLabel"] as? String) ?? "",
            messageTemplate: (map["messageTemplate"] as? String)
                ?? "{distance} {duration} {lapMetric} {overallMetric}",
            autoPausedMessage: (map["autoPausedMessage"] as? String) ?? "",
            autoResumedMessage: (map["autoResumedMessage"] as? String) ?? ""
        )
    }
}
