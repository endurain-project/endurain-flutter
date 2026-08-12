package com.endurain.endurain

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import com.endurain.endurain.activity.ActivityRecorderChannel
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterFragmentActivity() {
    private var recorderChannel: ActivityRecorderChannel? = null
    private var deviceMeasurementSystemChannel: DeviceMeasurementSystemChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        maybeRequestNotificationPermission()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        deviceMeasurementSystemChannel = DeviceMeasurementSystemChannel().also {
            it.register(flutterEngine.dartExecutor.binaryMessenger)
        }
        recorderChannel = ActivityRecorderChannel(applicationContext).also {
            it.register(flutterEngine.dartExecutor.binaryMessenger)
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        deviceMeasurementSystemChannel?.unregister()
        deviceMeasurementSystemChannel = null
        recorderChannel?.unregister()
        recorderChannel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    /**
     * Requests the Android 13+ (API 33) runtime notification permission so the
     * foreground-service notification that keeps activity recording — and the
     * native heart-rate capture bound to it — alive stays visible. The
     * permission is declared in the manifest but, from API 33, must also be
     * granted at runtime. Best-effort: recording still runs if the user denies
     * it, just without a visible ongoing notification.
     */
    private fun maybeRequestNotificationPermission() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            return
        }
        val granted =
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
                PackageManager.PERMISSION_GRANTED
        if (!granted) {
            requestPermissions(
                arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                REQUEST_POST_NOTIFICATIONS,
            )
        }
    }

    private companion object {
        private const val REQUEST_POST_NOTIFICATIONS = 1001
    }
}
