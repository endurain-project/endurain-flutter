import Foundation

/// Durable state for the spoken progress announcements of one recording:
/// the immutable, localized configuration handed over at `start` (see the
/// Dart `AudioAnnouncementConfig`) plus the mutable progress the on-device
/// scheduler advances at every location fix.
///
/// Mirrors the Android `AnnouncementStateData` data class. Persisted as its
/// own file inside the same active-recording directory as
/// `ActiveActivityStore`'s session/points files (see
/// `ActiveActivityStore.saveAnnouncementState`), so `clear()` (called on
/// discard) removes it too, and the "already announced" bookkeeping survives
/// whatever iOS process lifecycle event happens between two location fixes.
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
    let languageTag: String
    let distanceUnitTemplate: String
    let paceUnitTemplate: String
    let messageTemplate: String
    // Durable progress, advanced by the scheduler at every fix.
    var cumulativeDistanceMeters: Double
    var lastAnnouncedDistanceIndex: Int
    var lastAnnouncedTimeIndex: Int
    var lastLatitude: Double?
    var lastLongitude: Double?
    var lastElapsedSeconds: Int

    static let unitDistance = "distance"
    static let unitTime = "time"

    init(
        enabled: Bool,
        duckOtherAudio: Bool,
        intervalUnit: String,
        distanceIntervalMeters: Double,
        timeIntervalSeconds: Int,
        useImperialUnits: Bool,
        languageTag: String,
        distanceUnitTemplate: String,
        paceUnitTemplate: String,
        messageTemplate: String,
        cumulativeDistanceMeters: Double = 0,
        lastAnnouncedDistanceIndex: Int = 0,
        lastAnnouncedTimeIndex: Int = 0,
        lastLatitude: Double? = nil,
        lastLongitude: Double? = nil,
        lastElapsedSeconds: Int = 0
    ) {
        self.enabled = enabled
        self.duckOtherAudio = duckOtherAudio
        self.intervalUnit = intervalUnit
        self.distanceIntervalMeters = distanceIntervalMeters
        self.timeIntervalSeconds = timeIntervalSeconds
        self.useImperialUnits = useImperialUnits
        self.languageTag = languageTag
        self.distanceUnitTemplate = distanceUnitTemplate
        self.paceUnitTemplate = paceUnitTemplate
        self.messageTemplate = messageTemplate
        self.cumulativeDistanceMeters = cumulativeDistanceMeters
        self.lastAnnouncedDistanceIndex = lastAnnouncedDistanceIndex
        self.lastAnnouncedTimeIndex = lastAnnouncedTimeIndex
        self.lastLatitude = lastLatitude
        self.lastLongitude = lastLongitude
        self.lastElapsedSeconds = lastElapsedSeconds
    }

    var isTimeBased: Bool {
        return intervalUnit == AnnouncementStateData.unitTime
    }

    func copyWith(
        cumulativeDistanceMeters: Double? = nil,
        lastAnnouncedDistanceIndex: Int? = nil,
        lastAnnouncedTimeIndex: Int? = nil,
        lastLatitude: Double?? = nil,
        lastLongitude: Double?? = nil,
        lastElapsedSeconds: Int? = nil
    ) -> AnnouncementStateData {
        return AnnouncementStateData(
            enabled: enabled,
            duckOtherAudio: duckOtherAudio,
            intervalUnit: intervalUnit,
            distanceIntervalMeters: distanceIntervalMeters,
            timeIntervalSeconds: timeIntervalSeconds,
            useImperialUnits: useImperialUnits,
            languageTag: languageTag,
            distanceUnitTemplate: distanceUnitTemplate,
            paceUnitTemplate: paceUnitTemplate,
            messageTemplate: messageTemplate,
            cumulativeDistanceMeters: cumulativeDistanceMeters ?? self.cumulativeDistanceMeters,
            lastAnnouncedDistanceIndex: lastAnnouncedDistanceIndex ?? self.lastAnnouncedDistanceIndex,
            lastAnnouncedTimeIndex: lastAnnouncedTimeIndex ?? self.lastAnnouncedTimeIndex,
            lastLatitude: lastLatitude ?? self.lastLatitude,
            lastLongitude: lastLongitude ?? self.lastLongitude,
            lastElapsedSeconds: lastElapsedSeconds ?? self.lastElapsedSeconds
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
        map["languageTag"] = languageTag
        map["distanceUnitTemplate"] = distanceUnitTemplate
        map["paceUnitTemplate"] = paceUnitTemplate
        map["messageTemplate"] = messageTemplate
        map["cumulativeDistanceMeters"] = cumulativeDistanceMeters
        map["lastAnnouncedDistanceIndex"] = lastAnnouncedDistanceIndex
        map["lastAnnouncedTimeIndex"] = lastAnnouncedTimeIndex
        if let lastLatitude = lastLatitude { map["lastLatitude"] = lastLatitude }
        if let lastLongitude = lastLongitude { map["lastLongitude"] = lastLongitude }
        map["lastElapsedSeconds"] = lastElapsedSeconds
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
            languageTag: languageTag,
            distanceUnitTemplate: (json["distanceUnitTemplate"] as? String) ?? "{value}",
            paceUnitTemplate: (json["paceUnitTemplate"] as? String) ?? "{value}",
            messageTemplate: (json["messageTemplate"] as? String) ?? "{distance} {duration} {pace}",
            cumulativeDistanceMeters: JsonScalar.double(json["cumulativeDistanceMeters"]) ?? 0,
            lastAnnouncedDistanceIndex: JsonScalar.int(json["lastAnnouncedDistanceIndex"]) ?? 0,
            lastAnnouncedTimeIndex: JsonScalar.int(json["lastAnnouncedTimeIndex"]) ?? 0,
            lastLatitude: JsonScalar.double(json["lastLatitude"]),
            lastLongitude: JsonScalar.double(json["lastLongitude"]),
            lastElapsedSeconds: JsonScalar.int(json["lastElapsedSeconds"]) ?? 0
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
            languageTag: languageTag,
            distanceUnitTemplate: (map["distanceUnitTemplate"] as? String) ?? "{value}",
            paceUnitTemplate: (map["paceUnitTemplate"] as? String) ?? "{value}",
            messageTemplate: (map["messageTemplate"] as? String) ?? "{distance} {duration} {pace}"
        )
    }
}
