package com.endurain.endurain.activity

import org.json.JSONObject

/**
 * Durable state for the spoken progress announcements of one recording:
 * the immutable, localized configuration handed over at `start` (see the
 * Dart `AudioAnnouncementConfig`) plus the mutable progress the on-device
 * scheduler advances at every location fix.
 *
 * Persisted as its own file inside the same active-recording directory as
 * `ActiveActivityStore`'s session/points files (see
 * `ActiveActivityStore.saveAnnouncementState`), so:
 * - it survives the foreground service being killed and restarted by the
 *   system (the config is not re-sent on a sticky restart), and
 * - `lastAnnouncedDistanceIndex`/`lastAnnouncedTimeIndex` prevent an
 *   already-spoken threshold from being announced again after that restart.
 *
 * Deliberately kept separate from `ActiveActivitySessionData`: that model's
 * JSON schema is a durability contract shared with Dart and iOS, and
 * announcement bookkeeping is a native-only concern that never crosses the
 * platform channel after `start`.
 */
data class AnnouncementStateData(
    // Immutable config, supplied once at `start`.
    val enabled: Boolean,
    val duckOtherAudio: Boolean,
    val intervalUnit: String,
    val distanceIntervalMeters: Double,
    val timeIntervalSeconds: Int,
    val useImperialUnits: Boolean,
    val languageTag: String,
    val distanceUnitTemplate: String,
    val paceUnitTemplate: String,
    val messageTemplate: String,
    // Durable progress, advanced by the scheduler at every fix.
    val cumulativeDistanceMeters: Double = 0.0,
    val lastAnnouncedDistanceIndex: Int = 0,
    val lastAnnouncedTimeIndex: Int = 0,
    val lastLatitude: Double? = null,
    val lastLongitude: Double? = null,
    val lastElapsedSeconds: Int = 0,
) {
    val isTimeBased: Boolean
        get() = intervalUnit == UNIT_TIME

    fun toJson(): JSONObject {
        return JSONObject().apply {
            put("enabled", enabled)
            put("duckOtherAudio", duckOtherAudio)
            put("intervalUnit", intervalUnit)
            put("distanceIntervalMeters", distanceIntervalMeters)
            put("timeIntervalSeconds", timeIntervalSeconds)
            put("useImperialUnits", useImperialUnits)
            put("languageTag", languageTag)
            put("distanceUnitTemplate", distanceUnitTemplate)
            put("paceUnitTemplate", paceUnitTemplate)
            put("messageTemplate", messageTemplate)
            put("cumulativeDistanceMeters", cumulativeDistanceMeters)
            put("lastAnnouncedDistanceIndex", lastAnnouncedDistanceIndex)
            put("lastAnnouncedTimeIndex", lastAnnouncedTimeIndex)
            lastLatitude?.let { put("lastLatitude", it) }
            lastLongitude?.let { put("lastLongitude", it) }
            put("lastElapsedSeconds", lastElapsedSeconds)
        }
    }

    companion object {
        const val UNIT_DISTANCE = "distance"
        const val UNIT_TIME = "time"

        fun fromJson(json: JSONObject): AnnouncementStateData? {
            val languageTag = json.optStringOrNull("languageTag") ?: return null
            return AnnouncementStateData(
                enabled = json.optBoolean("enabled", false),
                duckOtherAudio = json.optBoolean("duckOtherAudio", true),
                intervalUnit = json.optString("intervalUnit", UNIT_DISTANCE),
                distanceIntervalMeters = json.optDouble("distanceIntervalMeters", 1000.0),
                timeIntervalSeconds = json.optInt("timeIntervalSeconds", 300),
                useImperialUnits = json.optBoolean("useImperialUnits", false),
                languageTag = languageTag,
                distanceUnitTemplate = json.optString("distanceUnitTemplate", "{value}"),
                paceUnitTemplate = json.optString("paceUnitTemplate", "{value}"),
                messageTemplate = json.optString(
                    "messageTemplate",
                    "{distance} {duration} {pace}",
                ),
                cumulativeDistanceMeters = json.optDouble("cumulativeDistanceMeters", 0.0),
                lastAnnouncedDistanceIndex = json.optInt("lastAnnouncedDistanceIndex", 0),
                lastAnnouncedTimeIndex = json.optInt("lastAnnouncedTimeIndex", 0),
                lastLatitude = json.optDoubleOrNull("lastLatitude"),
                lastLongitude = json.optDoubleOrNull("lastLongitude"),
                lastElapsedSeconds = json.optInt("lastElapsedSeconds", 0),
            )
        }

        /**
         * Parses the `audioAnnouncements` argument map sent by Dart's `start`
         * method call. Returns `null` when the argument is absent (recorders
         * that never enabled announcements never write this file at all).
         */
        fun fromStartArguments(map: Map<*, *>?): AnnouncementStateData? {
            if (map == null) {
                return null
            }
            val languageTag = map["languageTag"] as? String ?: return null
            return AnnouncementStateData(
                enabled = map["enabled"] as? Boolean ?: false,
                duckOtherAudio = map["duckOtherAudio"] as? Boolean ?: true,
                intervalUnit = map["intervalUnit"] as? String ?: UNIT_DISTANCE,
                distanceIntervalMeters = (map["distanceIntervalMeters"] as? Number)
                    ?.toDouble() ?: 1000.0,
                timeIntervalSeconds = (map["timeIntervalSeconds"] as? Number)?.toInt()
                    ?: 300,
                useImperialUnits = map["useImperialUnits"] as? Boolean ?: false,
                languageTag = languageTag,
                distanceUnitTemplate = map["distanceUnitTemplate"] as? String
                    ?: "{value}",
                paceUnitTemplate = map["paceUnitTemplate"] as? String ?: "{value}",
                messageTemplate = map["messageTemplate"] as? String
                    ?: "{distance} {duration} {pace}",
            )
        }
    }
}
