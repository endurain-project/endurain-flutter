package com.endurain.endurain.watchlink

import java.io.File
import java.io.IOException

/**
 * Durable store of session handoffs, one JSON file per session.
 *
 * The phone uses it as the inbox of sessions received from the watch, and
 * the watch as the outbox of sessions waiting for the phone's
 * acknowledgement. Writes go to a temporary file renamed into place, so a
 * crash leaves either the previous file or the new one, never a partial one.
 *
 * File names are the hex encoding of the session id's UTF-8 bytes: injective
 * (two sessions never share a file), safe on any file system, and
 * reversible, so listing the directory yields the session ids.
 */
class HandoffFileStore(val directory: File) {
    data class Entry(
        val sessionId: String,
        val file: File,
        /** When the handoff was last saved, in epoch milliseconds. */
        val savedAtMillis: Long,
    )

    private val lock = Any()

    @Throws(IOException::class)
    fun save(data: ByteArray, sessionId: String) {
        val name = encode(sessionId)
        synchronized(lock) {
            if (!directory.isDirectory && !directory.mkdirs()) {
                throw IOException("Could not create ${directory.name}")
            }
            val target = File(directory, "$name.$EXTENSION")
            val temporary = File(directory, "$name.$EXTENSION.tmp")
            temporary.writeBytes(data)
            if (!temporary.renameTo(target)) {
                temporary.delete()
                throw IOException("Could not store a handoff")
            }
        }
    }

    fun data(sessionId: String): ByteArray? =
        entry(sessionId)?.file?.let { file ->
            try {
                file.readBytes()
            } catch (_: IOException) {
                null
            }
        }

    fun entry(sessionId: String): Entry? = entries().firstOrNull { it.sessionId == sessionId }

    /** Every stored handoff, oldest first. A missing directory is empty. */
    fun entries(): List<Entry> =
        synchronized(lock) {
            val files = directory.listFiles() ?: return emptyList()
            files
                .filter { it.isFile && it.name.endsWith(".$EXTENSION") }
                .mapNotNull { file ->
                    val id = decode(file.name.removeSuffix(".$EXTENSION")) ?: return@mapNotNull null
                    Entry(id, file, file.lastModified())
                }
                .sortedBy { it.savedAtMillis }
        }

    fun remove(sessionId: String) {
        val name = runCatching { encode(sessionId) }.getOrNull() ?: return
        synchronized(lock) {
            File(directory, "$name.$EXTENSION").delete()
        }
    }

    /** Drops entries saved before [epochMillis] and returns their ids. */
    fun pruneSavedBefore(epochMillis: Long): List<String> {
        val stale = entries().filter { it.savedAtMillis < epochMillis }
        synchronized(lock) {
            stale.forEach { it.file.delete() }
        }
        return stale.map { it.sessionId }
    }

    companion object {
        private const val EXTENSION = "json"

        /** File names are limited to 255 bytes; hex doubles the length. */
        const val MAX_SESSION_ID_BYTES = 120

        /** Hex encoding of [sessionId]'s UTF-8 bytes. */
        fun encode(sessionId: String): String {
            val bytes = sessionId.toByteArray(Charsets.UTF_8)
            require(bytes.isNotEmpty() && bytes.size <= MAX_SESSION_ID_BYTES) {
                "Unusable session id"
            }
            return bytes.joinToString("") { "%02x".format(it.toInt() and 0xff) }
        }

        fun decode(stem: String): String? {
            if (stem.isEmpty() || stem.length % 2 != 0) return null
            val bytes = ByteArray(stem.length / 2)
            for (index in bytes.indices) {
                val byte = stem.substring(index * 2, index * 2 + 2).toIntOrNull(16) ?: return null
                bytes[index] = byte.toByte()
            }
            val decoded = String(bytes, Charsets.UTF_8)
            // Reject byte sequences that are not valid UTF-8 (they would not
            // round-trip back to the same file name).
            return decoded.takeIf { it.toByteArray(Charsets.UTF_8).contentEquals(bytes) }
        }
    }
}
