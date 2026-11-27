package com.endurain.endurain

import android.Manifest
import android.os.Bundle
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContracts
import com.endurain.endurain.activity.ActivityRecorderChannel
import com.endurain.endurain.activity.NotificationPermissionGate
import com.endurain.endurain.watch.WatchInbox
import com.endurain.endurain.watch.WatchLinkFactory
import com.endurain.endurain.watch.WatchTransportChannel
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterFragmentActivity() {
    private var recorderChannel: ActivityRecorderChannel? = null
    private var deviceMeasurementSystemChannel: DeviceMeasurementSystemChannel? = null
    private var healthConnectSettingsChannel: HealthConnectSettingsChannel? = null
    private var watchTransportChannel: WatchTransportChannel? = null

    /**
     * Asks for the Android 13+ notification permission when Dart requests it
     * (right before a recording or its start countdown), not on app start.
     * The permission is declared in the manifest but, from API 33, must also
     * be granted at runtime for the recorder's foreground notification to show.
     * Recording itself never depends on the answer.
     */
    private val notificationPermissionGate: NotificationPermissionGate = NotificationPermissionGate(
        isGranted = {
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
                android.content.pm.PackageManager.PERMISSION_GRANTED
        },
        // After a permanent denial the system answers "denied" without showing
        // anything, so the launcher is safe to call every time.
        launch = { notificationPermissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS) },
    )

    // Registered at construction: ActivityResult launchers must exist before
    // the activity is STARTED.
    private val notificationPermissionLauncher: ActivityResultLauncher<String> =
        registerForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
            notificationPermissionGate.onResult(granted)
        }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Android 15+ forces edge-to-edge for apps targeting SDK 35+; opt in on
        // older versions too so every device lays out the same way. Flutter
        // already pads its UI with the system bar insets (SafeArea/MediaQuery).
        // Called after super.onCreate so it replaces the translucent status bar
        // FlutterFragmentActivity sets there.
        enableEdgeToEdge()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        deviceMeasurementSystemChannel = DeviceMeasurementSystemChannel().also {
            it.register(flutterEngine.dartExecutor.binaryMessenger)
        }
        healthConnectSettingsChannel = HealthConnectSettingsChannel(this).also {
            it.register(flutterEngine.dartExecutor.binaryMessenger)
        }
        recorderChannel = ActivityRecorderChannel(
            applicationContext,
            notificationPermission = notificationPermissionGate,
        ).also {
            it.register(flutterEngine.dartExecutor.binaryMessenger)
        }
        watchTransportChannel = WatchTransportChannel(
            link = WatchLinkFactory.create(applicationContext),
            inbox = WatchInbox.create(applicationContext),
        ).also {
            it.register(flutterEngine.dartExecutor.binaryMessenger)
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        deviceMeasurementSystemChannel?.unregister()
        deviceMeasurementSystemChannel = null
        healthConnectSettingsChannel?.unregister()
        healthConnectSettingsChannel = null
        recorderChannel?.unregister()
        recorderChannel = null
        // Dart can no longer receive the answer; do not leave its call hanging.
        notificationPermissionGate.cancelPending()
        watchTransportChannel?.unregister()
        watchTransportChannel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

}
