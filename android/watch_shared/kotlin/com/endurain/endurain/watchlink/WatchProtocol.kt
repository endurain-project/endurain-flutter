package com.endurain.endurain.watchlink

import java.time.Instant
import java.time.ZoneOffset
import java.time.format.DateTimeFormatter
import java.time.format.DateTimeParseException

/**
 * Wire contract between the Endurain phone app and its Wear OS app.
 *
 * Compiled into both apps. The watch publishes each finished session as a
 * Wearable Data Layer item at [handoffPath] whose [KEY_PAYLOAD] asset is
 * exactly the envelope the Dart `WatchSessionHandoff.fromJson` reads. Once
 * Dart has stored the activity, the phone publishes an item at [ackPath];
 * the watch then deletes its copy and its handoff item, and the phone drops
 * the acknowledgement when it sees the handoff item deleted.
 */
object WatchProtocol {
    /** Mirrors `WatchSessionHandoff.currentPayloadVersion` in Dart. */
    const val PAYLOAD_VERSION = 1

    /** Mirrors the Dart `WatchSource.wearOs` name. */
    const val SOURCE = "wearOs"

    /** Mirrors `ActiveActivitySession.currentSchemaVersion` in Dart. */
    const val SESSION_SCHEMA_VERSION = 3

    const val HANDOFF_PATH_PREFIX = "/endurain/handoff/"
    const val ACK_PATH_PREFIX = "/endurain/ack/"

    const val KEY_SESSION_ID = "sessionId"
    const val KEY_VERSION = "version"
    const val KEY_PAYLOAD = "payload"
    const val KEY_TIMESTAMP = "timestamp"

    /** Capability the watch app advertises (`res/values/wear.xml`). */
    const val WEAR_APP_CAPABILITY = "endurain_wear_app"

    fun handoffPath(sessionId: String): String =
        HANDOFF_PATH_PREFIX + HandoffFileStore.encode(sessionId)

    fun ackPath(sessionId: String): String =
        ACK_PATH_PREFIX + HandoffFileStore.encode(sessionId)

    /** The session id a handoff or acknowledgement path names, or null. */
    fun sessionIdFromPath(path: String?, prefix: String): String? {
        if (path == null || !path.startsWith(prefix)) return null
        return HandoffFileStore.decode(path.removePrefix(prefix))
    }

    /** UTC ISO-8601 with milliseconds, the format the Dart models write. */
    fun timestamp(epochMillis: Long): String =
        isoFormatter.format(Instant.ofEpochMilli(epochMillis))

    fun parseTimestamp(value: String): Long? =
        try {
            Instant.parse(value).toEpochMilli()
        } catch (_: DateTimeParseException) {
            null
        }

    private val isoFormatter: DateTimeFormatter =
        DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").withZone(ZoneOffset.UTC)
}
