package com.endurain.endurain.activity

import android.os.Handler
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Delivers the first reply to [delegate] on [mainHandler]'s thread; any later
 * reply is dropped. Lets a handler that runs on a background thread answer the
 * Flutter method channel, which must be replied to on the main thread, and
 * makes a late failure reply harmless after a success was already sent.
 */
internal class MainThreadResult(
    private val delegate: MethodChannel.Result,
    private val mainHandler: Handler,
) : MethodChannel.Result {
    private val replied = AtomicBoolean(false)

    override fun success(result: Any?) {
        if (replied.compareAndSet(false, true)) {
            mainHandler.post { delegate.success(result) }
        }
    }

    override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
        if (replied.compareAndSet(false, true)) {
            mainHandler.post { delegate.error(errorCode, errorMessage, errorDetails) }
        }
    }

    override fun notImplemented() {
        if (replied.compareAndSet(false, true)) {
            mainHandler.post { delegate.notImplemented() }
        }
    }
}
