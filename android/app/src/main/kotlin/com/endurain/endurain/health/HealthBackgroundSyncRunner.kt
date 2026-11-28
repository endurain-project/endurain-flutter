package com.endurain.endurain.health

import android.content.Context
import androidx.annotation.MainThread
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext
import kotlin.coroutines.resume

/**
 * Runs one automatic health import for [HealthBackgroundSyncWorker].
 *
 * While the app's engine is up and its Dart side listens, the import runs
 * there, so a single Dart isolate imports and uploads at a time. Otherwise a
 * headless engine is started on the `healthBackgroundSyncMain` entry point
 * (`lib/main.dart`) and destroyed once Dart reports the import finished, or
 * when WorkManager stops the work.
 */
internal object HealthBackgroundSyncRunner {
    private const val ENTRYPOINT = "healthBackgroundSyncMain"

    // Read and written only on the main thread.
    private var listening: HealthBackgroundSyncChannel? = null

    @MainThread
    fun listen(channel: HealthBackgroundSyncChannel) {
        listening = channel
    }

    @MainThread
    fun stopListening(channel: HealthBackgroundSyncChannel) {
        if (listening === channel) listening = null
    }

    /** Returns whether the import ran without failures. */
    suspend fun run(context: Context): Boolean = withContext(Dispatchers.Main) {
        val app = listening
        if (app != null) {
            suspendCancellableCoroutine { continuation ->
                app.run { succeeded ->
                    if (continuation.isActive) continuation.resume(succeeded)
                }
            }
        } else {
            runHeadless(context)
        }
    }

    @MainThread
    private suspend fun runHeadless(context: Context): Boolean {
        // Registers every plugin, as the app's engine does.
        val engine = FlutterEngine(context)
        try {
            return suspendCancellableCoroutine { continuation ->
                HealthBackgroundSyncChannel(
                    setScheduled = { HealthBackgroundSyncWorker.schedule(context, it) },
                    // A headless engine only runs the import it was started for.
                    onListen = {},
                    onFinished = { succeeded ->
                        if (continuation.isActive) continuation.resume(succeeded)
                    },
                ).register(engine.dartExecutor.binaryMessenger)
                engine.dartExecutor.executeDartEntrypoint(
                    DartExecutor.DartEntrypoint(
                        FlutterInjector.instance().flutterLoader().findAppBundlePath(),
                        ENTRYPOINT,
                    ),
                )
            }
        } finally {
            engine.destroy()
        }
    }
}
