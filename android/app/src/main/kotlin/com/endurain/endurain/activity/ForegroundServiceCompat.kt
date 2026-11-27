package com.endurain.endurain.activity

import android.Manifest
import android.app.Service
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.os.Build
import androidx.core.content.ContextCompat

/**
 * Enters and leaves the foreground for [service], handling the Android 14
 * (API 34) foreground-service type rules.
 *
 * Android 14 validates every declared type at `startForeground` time. The
 * `connectedDevice` type requires the app to *hold at runtime* one of the
 * nearby-device permissions; the only ones this app declares
 * (`BLUETOOTH_CONNECT`/`BLUETOOTH_SCAN`) are runtime permissions that a user
 * who never paired a sensor has never granted. Requesting the type
 * unconditionally threw `SecurityException` for plain GPS-only recordings and
 * the recording never started, so the type is claimed only when needed and
 * permitted. Called only from the recorder thread.
 */
internal class ForegroundServiceCompat(
    private val service: Service,
    private val notifications: RecorderNotifications,
    private val store: ActiveActivityStore,
) {
    /** Whether [start] succeeded since the last [stop]. */
    var inForeground = false
        private set

    /** Whether the app holds a nearby-device permission `connectedDevice` needs. */
    fun hasConnectedDevicePermission(): Boolean =
        hasPermission(Manifest.permission.BLUETOOTH_CONNECT) ||
            hasPermission(Manifest.permission.BLUETOOTH_SCAN)

    /**
     * Whether the service may declare
     * [ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE] for [session]: it
     * must bind a sensor AND the permission must be granted.
     */
    fun canDeclareConnectedDeviceType(session: ActiveActivitySessionData?): Boolean {
        if (session == null || !session.hasAnySensorBinding()) {
            return false
        }
        return hasConnectedDevicePermission()
    }

    /**
     * Calls `startForeground` with the notification for [title] and [text]. `location` is always
     * declared; `connectedDevice` only when [connectedDevice] (by default when
     * the stored session needs and is permitted it). May throw
     * `SecurityException` or another `RuntimeException` when refused.
     */
    fun start(
        title: String,
        text: String,
        connectedDevice: Boolean = canDeclareConnectedDeviceType(store.loadSession()),
    ) {
        val notification = notifications.build(title, text)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            var types = ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION
            if (connectedDevice) {
                types = types or ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE
            }
            service.startForeground(RecorderNotifications.NOTIFICATION_ID, notification, types)
        } else {
            service.startForeground(RecorderNotifications.NOTIFICATION_ID, notification)
        }
        inForeground = true
    }

    fun stop() {
        inForeground = false
        service.stopForeground(Service.STOP_FOREGROUND_REMOVE)
    }

    /**
     * Enters the foreground or persists and reports the failure and stops.
     * With [notifyInterrupted], a failure also posts a notification that the
     * recording was interrupted, for restarts no Flutter engine sees.
     */
    fun startOrFail(title: String, text: String, notifyInterrupted: Boolean = false): Boolean {
        val reason = try {
            start(title, text)
            notifications.cancelInterrupted()
            return true
        } catch (_: SecurityException) {
            ActivityRecorderCoordinator.REASON_PERMISSION_LOST
        } catch (_: RuntimeException) {
            ActivityRecorderCoordinator.REASON_LOCATION_STREAM_FAILED
        }
        SessionRecovery.persistFailure(store)
        ActivityRecorderCoordinator.emitFailed(reason)
        if (notifyInterrupted) {
            notifications.postInterrupted()
        }
        service.stopSelf()
        return false
    }

    /**
     * Stops the service before any work started. A service started with
     * `startForegroundService` must call `startForeground` before it stops,
     * or Android 9+ crashes the app, so it briefly claims the foreground with
     * the default notification first. On Android 14+ that can itself be
     * refused (no location permission left to claim the type); nothing more
     * can be done then.
     */
    fun stopBeforeForegroundWork() {
        try {
            start(notifications.defaultTitle(), notifications.defaultText(), connectedDevice = false)
        } catch (_: RuntimeException) {
            // See above.
        }
        stop()
        service.stopSelf()
    }

    private fun hasPermission(permission: String): Boolean =
        ContextCompat.checkSelfPermission(service, permission) ==
            PackageManager.PERMISSION_GRANTED
}
