package com.endurain.endurain.activity

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Build
import android.os.Bundle
import android.os.IBinder
import android.os.Looper
import com.endurain.endurain.R
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import java.util.Date

/**
 * Foreground service that owns background location collection for an active
 * recording.
 *
 * F-Droid compatible: uses the platform [LocationManager] with the GPS/network
 * providers only. No Google Play Services / fused location is used.
 *
 * Each fix is persisted to the durable [ActiveActivityStore] before being
 * broadcast to Flutter, so points survive process death and are replayed via
 * `drain` on reattach.
 */
class ActivityRecorderService : Service() {
    private lateinit var store: ActiveActivityStore
    private var locationManager: LocationManager? = null
    private var locationListener: LocationListener? = null

    private var lastPointEpochMillis: Long? = null
    private var activeNotificationTitle: String? = null
    private var activeNotificationText: String? = null
    private var resumedFromPause = false

    override fun onCreate() {
        super.onCreate()
        store = ActiveActivityStore.of(applicationContext)
        locationManager =
            getSystemService(Context.LOCATION_SERVICE) as? LocationManager
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> handleStart(intent)
            ACTION_RESUME -> handleResume()
            ACTION_PAUSE -> handlePause()
            ACTION_STOP -> handleStop()
            else -> handleRestart()
        }
        return START_STICKY
    }

    private fun handleStart(intent: Intent) {
        val title = intent.getStringExtra(EXTRA_TITLE) ?: defaultTitle()
        val text = intent.getStringExtra(EXTRA_TEXT) ?: defaultText()
        activeNotificationTitle = title
        activeNotificationText = text
        resumedFromPause = false
        if (!hasAnyLocationPermission()) {
            persistFailure()
            ActivityRecorderCoordinator.emitFailed(
                ActivityRecorderCoordinator.REASON_PERMISSION_LOST,
            )
            stopSelf()
            return
        }
        if (!startForegroundOrFail(title, text)) {
            return
        }
        beginCollection()
    }

    private fun handleResume() {
        val session = store.loadSession()
        resumedFromPause = session != null
        if (!hasAnyLocationPermission()) {
            persistFailure()
            ActivityRecorderCoordinator.emitFailed(
                ActivityRecorderCoordinator.REASON_PERMISSION_LOST,
            )
            stopSelf()
            return
        }
        if (!startForegroundOrFail(
            activeNotificationTitle ?: defaultTitle(),
            activeNotificationText ?: defaultText(),
        )) {
            return
        }
        if (session != null && session.status == ActiveActivitySessionData.STATUS_RECORDING) {
            beginCollection()
        }
    }

    private fun handlePause() {
        stopCollection()
        // Keep the foreground notification so recording can resume cheaply.
    }

    private fun handleStop() {
        stopCollection()
        resumedFromPause = false
        stopForegroundCompat()
        stopSelf()
    }

    /** Sticky restart after process death: resume only if still recording. */
    private fun handleRestart() {
        val session = store.loadSession()
        if (session == null || !session.isActive) {
            stopSelf()
            return
        }
        if (!hasAnyLocationPermission()) {
            persistFailure()
            ActivityRecorderCoordinator.emitFailed(
                ActivityRecorderCoordinator.REASON_PERMISSION_LOST,
            )
            stopSelf()
            return
        }
        if (!startForegroundOrFail(
            activeNotificationTitle ?: defaultTitle(),
            activeNotificationText ?: defaultText(),
        )) {
            return
        }
        if (session.status == ActiveActivitySessionData.STATUS_RECORDING) {
            beginCollection()
        }
    }

    private fun beginCollection() {
        stopCollection()
        val manager = locationManager
        if (manager == null) {
            persistFailure()
            ActivityRecorderCoordinator.emitFailed(
                ActivityRecorderCoordinator.REASON_LOCATION_UNAVAILABLE,
            )
            return
        }
        val hasFine = hasPermission(Manifest.permission.ACCESS_FINE_LOCATION)
        val hasCoarse = hasPermission(Manifest.permission.ACCESS_COARSE_LOCATION)
        if (!hasFine && !hasCoarse) {
            persistFailure()
            ActivityRecorderCoordinator.emitFailed(
                ActivityRecorderCoordinator.REASON_PERMISSION_LOST,
            )
            return
        }
        val providers = selectProviders(manager, hasFine, hasCoarse)
        if (providers.isEmpty()) {
            persistFailure()
            ActivityRecorderCoordinator.emitFailed(
                ActivityRecorderCoordinator.REASON_LOCATION_UNAVAILABLE,
            )
            return
        }
        val listener = object : LocationListener {
            override fun onLocationChanged(location: Location) {
                onLocationFix(location)
            }

            // Required no-op overrides for older API levels.
            override fun onProviderEnabled(provider: String) {}

            override fun onProviderDisabled(provider: String) {
                handleProviderAvailabilityChanged()
            }

            @Deprecated("Deprecated in Android API 29")
            override fun onStatusChanged(
                provider: String?,
                status: Int,
                extras: Bundle?,
            ) {
            }
        }
        locationListener = listener
        lastPointEpochMillis = store.lastPoint()?.timestamp?.let(IsoTime::toEpochMillis)
        var registeredProvider = false
        var permissionFailure = false
        for (provider in providers) {
            try {
                manager.requestLocationUpdates(
                    provider,
                    MIN_UPDATE_INTERVAL_MS,
                    MIN_UPDATE_DISTANCE_METERS,
                    listener,
                    Looper.getMainLooper(),
                )
                registeredProvider = true
            } catch (_: SecurityException) {
                permissionFailure = true
            } catch (_: IllegalArgumentException) {
                // Provider disappeared between discovery and subscription.
            }
        }
        if (!registeredProvider) {
            locationListener = null
            persistFailure()
            ActivityRecorderCoordinator.emitFailed(
                if (permissionFailure) {
                    ActivityRecorderCoordinator.REASON_PERMISSION_LOST
                } else {
                    ActivityRecorderCoordinator.REASON_LOCATION_UNAVAILABLE
                },
            )
        }
    }

    /**
     * Persists [ActiveActivitySessionData.STATUS_FAILED] for any active session
     * so Flutter sees a non-recoverable state on re-attach even if the failure
     * event was dropped while Flutter was detached.
     */
    private fun persistFailure() {
        val session = store.loadSession() ?: return
        if (session.isActive) {
            store.saveSession(session.copy(status = ActiveActivitySessionData.STATUS_FAILED))
        }
    }

    private fun stopCollection() {
        val listener = locationListener ?: return
        try {
            locationManager?.removeUpdates(listener)
        } catch (_: Exception) {
            // Best effort; nothing to recover here.
        }
        locationListener = null
    }

    /**
     * Called when a location provider is disabled mid-recording.
     *
     * Re-checks permissions and all available providers. If at least one
     * provider is still enabled no action is taken — the existing listener
     * registrations continue. If no usable provider remains, the session is
     * persisted as failed and the service is stopped.
     */
    private fun handleProviderAvailabilityChanged() {
        val manager = locationManager ?: return
        val hasFine = hasPermission(Manifest.permission.ACCESS_FINE_LOCATION)
        val hasCoarse = hasPermission(Manifest.permission.ACCESS_COARSE_LOCATION)
        if (!hasFine && !hasCoarse) {
            persistFailure()
            ActivityRecorderCoordinator.emitFailed(
                ActivityRecorderCoordinator.REASON_PERMISSION_LOST,
            )
            stopCollection()
            stopSelf()
            return
        }
        val remaining = selectProviders(manager, hasFine, hasCoarse)
        if (remaining.isNotEmpty()) {
            return
        }
        persistFailure()
        ActivityRecorderCoordinator.emitFailed(
            ActivityRecorderCoordinator.REASON_LOCATION_UNAVAILABLE,
        )
        stopCollection()
        stopSelf()
    }

    private fun onLocationFix(location: Location) {
        val session = store.loadSession() ?: return
        if (session.status != ActiveActivitySessionData.STATUS_RECORDING) {
            return
        }
        val nowMillis = if (location.time > 0) location.time else System.currentTimeMillis()
        var segmentIndex = session.currentSegmentIndex
        val previous = lastPointEpochMillis
        if (resumedFromPause) {
            if (previous != null) {
                segmentIndex += 1
                store.saveSession(session.copy(currentSegmentIndex = segmentIndex))
            }
            resumedFromPause = false
        } else if (previous != null && nowMillis - previous > MAX_TIME_GAP_MILLIS) {
            // Large time gap: start a new segment to avoid bridging a false line.
            segmentIndex += 1
            store.saveSession(session.copy(currentSegmentIndex = segmentIndex))
        }
        lastPointEpochMillis = nowMillis

        val point = RecordedActivityPointData(
            timestamp = IsoTime.format(Date(nowMillis)),
            latitude = location.latitude,
            longitude = location.longitude,
            segmentIndex = segmentIndex,
            elevationMeters = if (location.hasAltitude()) location.altitude else null,
            horizontalAccuracyMeters =
                if (location.hasAccuracy()) location.accuracy.toDouble() else null,
            verticalAccuracyMeters = verticalAccuracy(location),
            headingDegrees = if (location.hasBearing()) location.bearing.toDouble() else null,
            headingAccuracyDegrees = bearingAccuracy(location),
            speedMetersPerSecond = if (location.hasSpeed()) location.speed.toDouble() else null,
            speedAccuracyMetersPerSecond = speedAccuracy(location),
        )
        try {
            store.appendPoints(listOf(point))
        } catch (_: Exception) {
            persistFailure()
            ActivityRecorderCoordinator.emitFailed(
                ActivityRecorderCoordinator.REASON_PERSISTENCE_FAILED,
            )
            return
        }
        ActivityRecorderCoordinator.emitPointBatch(listOf(point))
    }

    private fun selectProviders(
        manager: LocationManager,
        hasFine: Boolean,
        hasCoarse: Boolean,
    ): List<String> {
        val gpsEnabled = isProviderEnabled(manager, LocationManager.GPS_PROVIDER)
        val networkEnabled = isProviderEnabled(manager, LocationManager.NETWORK_PROVIDER)
        val providers = ArrayList<String>()
        if (hasFine && gpsEnabled) {
            providers.add(LocationManager.GPS_PROVIDER)
        }
        if ((hasFine || hasCoarse) && networkEnabled) {
            providers.add(LocationManager.NETWORK_PROVIDER)
        }
        return providers
    }

    private fun isProviderEnabled(manager: LocationManager, provider: String): Boolean {
        return try {
            manager.isProviderEnabled(provider)
        } catch (_: Exception) {
            false
        }
    }

    private fun verticalAccuracy(location: Location): Double? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            location.hasVerticalAccuracy()
        ) {
            location.verticalAccuracyMeters.toDouble()
        } else {
            null
        }
    }

    private fun bearingAccuracy(location: Location): Double? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            location.hasBearingAccuracy()
        ) {
            location.bearingAccuracyDegrees.toDouble()
        } else {
            null
        }
    }

    private fun speedAccuracy(location: Location): Double? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            location.hasSpeedAccuracy()
        ) {
            location.speedAccuracyMetersPerSecond.toDouble()
        } else {
            null
        }
    }

    private fun hasPermission(permission: String): Boolean {
        return ContextCompat.checkSelfPermission(this, permission) ==
            PackageManager.PERMISSION_GRANTED
    }

    private fun hasAnyLocationPermission(): Boolean {
        return hasPermission(Manifest.permission.ACCESS_FINE_LOCATION) ||
            hasPermission(Manifest.permission.ACCESS_COARSE_LOCATION)
    }

    private fun startForegroundCompat(title: String, text: String) {
        val notification = buildNotification(title, text)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION,
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    private fun startForegroundOrFail(title: String, text: String): Boolean {
        return try {
            startForegroundCompat(title, text)
            true
        } catch (_: SecurityException) {
            persistFailure()
            ActivityRecorderCoordinator.emitFailed(
                ActivityRecorderCoordinator.REASON_PERMISSION_LOST,
            )
            stopSelf()
            false
        } catch (_: RuntimeException) {
            persistFailure()
            ActivityRecorderCoordinator.emitFailed(
                ActivityRecorderCoordinator.REASON_LOCATION_STREAM_FAILED,
            )
            stopSelf()
            false
        }
    }

    private fun stopForegroundCompat() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
    }

    private fun buildNotification(title: String, text: String): Notification {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        val contentIntent = launchIntent?.let {
            PendingIntent.getActivity(
                this,
                0,
                it,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(text)
            .setSmallIcon(applicationInfo.icon)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .apply { contentIntent?.let { setContentIntent(it) } }
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (manager.getNotificationChannel(CHANNEL_ID) != null) {
            return
        }
        val channel = NotificationChannel(
            CHANNEL_ID,
            getString(R.string.activity_recording_channel_name),
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = getString(R.string.activity_recording_channel_description)
            setShowBadge(false)
        }
        manager.createNotificationChannel(channel)
    }

    private fun defaultTitle(): String {
        return getString(R.string.activity_recording_notification_title)
    }

    private fun defaultText(): String {
        return getString(R.string.activity_recording_notification_text)
    }

    override fun onDestroy() {
        stopCollection()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    companion object {
        const val ACTION_START = "com.endurain.endurain.activity.action.START"
        const val ACTION_PAUSE = "com.endurain.endurain.activity.action.PAUSE"
        const val ACTION_RESUME = "com.endurain.endurain.activity.action.RESUME"
        const val ACTION_STOP = "com.endurain.endurain.activity.action.STOP"

        const val EXTRA_TITLE = "title"
        const val EXTRA_TEXT = "text"

        private const val CHANNEL_ID = "activity_recording"
        private const val NOTIFICATION_ID = 4711

        // Mirror the Dart location/segment policy constants.
        private const val MIN_UPDATE_INTERVAL_MS = 1000L
        private const val MIN_UPDATE_DISTANCE_METERS = 3f
        private const val MAX_TIME_GAP_MILLIS = 30_000L

        private fun baseIntent(context: Context, action: String): Intent {
            return Intent(context, ActivityRecorderService::class.java).setAction(action)
        }

        fun start(context: Context, title: String?, text: String?) {
            val intent = baseIntent(context, ACTION_START)
            title?.let { intent.putExtra(EXTRA_TITLE, it) }
            text?.let { intent.putExtra(EXTRA_TEXT, it) }
            ContextCompat.startForegroundService(context, intent)
        }

        fun pause(context: Context) {
            context.startService(baseIntent(context, ACTION_PAUSE))
        }

        fun resume(context: Context) {
            ContextCompat.startForegroundService(
                context,
                baseIntent(context, ACTION_RESUME),
            )
        }

        fun stop(context: Context) {
            context.startService(baseIntent(context, ACTION_STOP))
        }
    }
}
