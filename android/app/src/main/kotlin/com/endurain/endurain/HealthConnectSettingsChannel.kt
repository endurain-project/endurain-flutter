package com.endurain.endurain

import android.content.Context
import android.content.Intent
import android.os.Build
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Opens Health Connect's permission screen for this app (launched from the
 * activity, so no new task is needed), so Dart can send a
 * user who revoked access to the place where it is granted again.
 *
 * `openPermissions` replies `true` when a screen was launched and `false`
 * when Health Connect is missing or refused the intent.
 */
class HealthConnectSettingsChannel(
    private val launcher: (Intent) -> Unit,
    private val resolves: (Intent) -> Boolean,
    private val packageName: String,
    private val sdkInt: Int = Build.VERSION.SDK_INT,
) : MethodChannel.MethodCallHandler {
    constructor(context: Context) : this(
        launcher = { intent -> context.startActivity(intent) },
        resolves = { intent -> intent.resolveActivity(context.packageManager) != null },
        packageName = context.packageName,
    )

    private var channel: MethodChannel? = null

    fun register(messenger: BinaryMessenger) {
        channel = MethodChannel(messenger, CHANNEL_NAME).also {
            it.setMethodCallHandler(this)
        }
    }

    fun unregister() {
        channel?.setMethodCallHandler(null)
        channel = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != METHOD_OPEN_PERMISSIONS) {
            result.notImplemented()
            return
        }
        result.success(openPermissions())
    }

    private fun openPermissions(): Boolean {
        val intent = permissionsIntent()
        return try {
            if (!resolves(intent)) {
                false
            } else {
                launcher(intent)
                true
            }
        } catch (_: RuntimeException) {
            // ActivityNotFoundException or a refused start.
            false
        }
    }

    /**
     * Android 14+ has Health Connect in the framework and a per-app screen;
     * before it, the Health Connect app answers its own settings action.
     */
    internal fun permissionsIntent(): Intent =
        if (sdkInt >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            Intent(ACTION_MANAGE_HEALTH_PERMISSIONS)
                .putExtra(Intent.EXTRA_PACKAGE_NAME, packageName)
        } else {
            Intent(ACTION_HEALTH_CONNECT_SETTINGS)
        }

    internal companion object {
        const val CHANNEL_NAME = "endurain/health_connect_settings"
        const val METHOD_OPEN_PERMISSIONS = "openPermissions"
        const val ACTION_MANAGE_HEALTH_PERMISSIONS =
            "android.health.connect.action.MANAGE_HEALTH_PERMISSIONS"
        const val ACTION_HEALTH_CONNECT_SETTINGS = "androidx.health.ACTION_HEALTH_CONNECT_SETTINGS"
    }
}
