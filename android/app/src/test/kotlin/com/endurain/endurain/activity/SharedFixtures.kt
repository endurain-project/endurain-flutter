package com.endurain.endurain.activity

import java.io.File
import org.json.JSONObject

/**
 * Loads the cross-platform JSON vectors in `test/fixtures/` that the Dart,
 * Kotlin and Swift tests all run, so the duplicated logic cannot drift.
 */
object SharedFixtures {
    /** Gradle's working directory is android/app; walk up to the repo root. */
    fun load(name: String): JSONObject {
        var dir: File? = File(System.getProperty("user.dir")!!).absoluteFile
        while (dir != null) {
            val candidate = File(dir, "test/fixtures/$name")
            if (candidate.isFile) {
                return JSONObject(candidate.readText())
            }
            dir = dir.parentFile
        }
        throw AssertionError("$name not found under test/fixtures")
    }

    /** Decodes two hex digits per byte, no separators (empty string = empty). */
    fun hexToBytes(hex: String): ByteArray =
        ByteArray(hex.length / 2) { hex.substring(it * 2, it * 2 + 2).toInt(16).toByte() }
}
