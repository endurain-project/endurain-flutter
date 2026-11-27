package com.endurain.endurain.watchlink

import android.net.Uri
import java.io.InputStream
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

    /** `PutDataRequest.WEAR_URI_SCHEME`, spelled out so the build without Play Services compiles too. */
    private const val DATA_LAYER_SCHEME = "wear"

    /**
     * The largest handoff payload read into memory. A real session (hours of
     * one-second GPS fixes) is a few MB, so anything beyond this is corrupt or
     * hostile and is dropped instead of exhausting the heap.
     */
    const val MAX_PAYLOAD_BYTES = 32 * 1024 * 1024

    /** Capability the watch app advertises (`res/values/wear.xml`). */
    const val WEAR_APP_CAPABILITY = "endurain_wear_app"

    fun handoffPath(sessionId: String): String =
        HANDOFF_PATH_PREFIX + HandoffFileStore.encode(sessionId)

    fun ackPath(sessionId: String): String =
        ACK_PATH_PREFIX + HandoffFileStore.encode(sessionId)

    /** The Data Layer URI of an item at [path], for `getDataItems` and `deleteDataItems`. */
    fun dataLayerUri(path: String): Uri = Uri.Builder().scheme(DATA_LAYER_SCHEME).path(path).build()

    /**
     * Whether a receiver can process an item written with [version]. Older
     * versions stay readable; a newer one comes from an app this build does not
     * understand yet, so it is neither processed nor acknowledged.
     */
    fun isSupportedVersion(version: Int): Boolean = version <= PAYLOAD_VERSION

    /**
     * Reads [stream] fully, or returns null once it holds more than
     * [maxBytes], without ever buffering more than that.
     */
    fun readCapped(stream: InputStream, maxBytes: Int = MAX_PAYLOAD_BYTES): ByteArray? {
        val buffer = java.io.ByteArrayOutputStream()
        val chunk = ByteArray(8192)
        while (true) {
            val read = stream.read(chunk)
            if (read < 0) return buffer.toByteArray()
            if (buffer.size() + read > maxBytes) return null
            buffer.write(chunk, 0, read)
        }
    }

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
