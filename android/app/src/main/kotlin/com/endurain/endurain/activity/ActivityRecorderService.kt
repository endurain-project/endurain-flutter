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
import android.os.PowerManager
import com.endurain.endurain.R
import androidx.annotation.VisibleForTesting
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import java.util.Date

/**
 * Foreground service that owns background location collection for an active
 * recording.
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
    private var heartRateClient: HeartRateGattClient? = null
    private var powerClient: CyclingPowerGattClient? = null
    private var cadenceClient: CadenceGattClient? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var autoPauseDetector: MovementAutoPauseDetector? = null

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
        startSensorCapture()
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
            startSensorCapture()
        }
    }

    private fun handlePause() {
        stopCollection()
        // Keep the foreground notification so recording can resume cheaply.
    }

    private fun handleStop() {
        stopCollection()
        stopSensorCapture()
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
            startSensorCapture()
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
            override fun onProviderEnabled(provider: String) {
                handleProviderAvailabilityChanged()
            }

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
        val session = store.loadSession()
        lastPointEpochMillis = store.lastPoint()?.timestamp?.let(IsoTime::toEpochMillis)
        autoPauseDetector = MovementAutoPauseDetector(
            MovementAutoPauseConfig(
                enabled = session?.autoPauseEnabled ?: false,
                pauseDelayMillis = (session?.autoPauseDelaySeconds ?: 5) * 1000L,
            ),
        ).also { it.reset(lastPointEpochMillis ?: System.currentTimeMillis()) }
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
            return
        }
        acquireWakeLock()
    }

    /**
     * Holds a partial wake lock for the duration of active collection.
     *
     * A foreground service is not kept awake by itself: between distance-
     * filtered GPS fixes the AP can suspend, which drops BLE
     * `onCharacteristicChanged` callbacks and delays the `points.jsonl` append
     * that must happen on the same wake window. This is what the declared
     * `WAKE_LOCK` permission is for.
     *
     * Deliberately acquired without a timeout: the lock's lifetime is bounded by
     * [stopCollection]/[onDestroy] instead, because any fixed timeout long
     * enough for an ultra-distance activity would be useless as a leak guard,
     * and a shorter one would silently degrade a long recording.
     */
    private fun acquireWakeLock() {
        if (wakeLock?.isHeld == true) {
            return
        }
        val powerManager = getSystemService(Context.POWER_SERVICE) as? PowerManager ?: return
        val lock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            WAKE_LOCK_TAG,
        )
        lock.setReferenceCounted(false)
        try {
            lock.acquire()
        } catch (_: RuntimeException) {
            // Losing the wake lock degrades sampling but must never abort the
            // recording; GPS delivery still holds its own wakelock per fix.
            return
        }
        wakeLock = lock
    }

    private fun releaseWakeLock() {
        val lock = wakeLock ?: return
        wakeLock = null
        try {
            if (lock.isHeld) {
                lock.release()
            }
        } catch (_: RuntimeException) {
            // Already released or never held.
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
        // Released first and unconditionally: the listener may already be null
        // (e.g. a start that never registered a provider), and the wake lock
        // must never outlive collection.
        releaseWakeLock()
        // A manual pause reaches here and must stop monitoring movement
        // entirely, so a manually paused recording can never auto-resume;
        // `beginCollection` always rebuilds a fresh detector for the next
        // active period.
        autoPauseDetector = null
        val listener = locationListener ?: return
        try {
            locationManager?.removeUpdates(listener)
        } catch (_: Exception) {
            // Best effort; nothing to recover here.
        }
        locationListener = null
    }

    /**
     * Called when a location provider is enabled or disabled mid-recording.
     *
     * Re-checks permissions and the available providers. Because collection now
     * subscribes to a single preferred provider (GPS, with network as
     * fallback), a provider toggle may require switching providers, so the
     * listener is re-registered via [beginCollection]. If no usable provider
     * remains, the session is persisted as failed and the service is stopped.
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
        if (remaining.isEmpty()) {
            persistFailure()
            ActivityRecorderCoordinator.emitFailed(
                ActivityRecorderCoordinator.REASON_LOCATION_UNAVAILABLE,
            )
            stopCollection()
            stopSelf()
            return
        }
        // Re-subscribe so a GPS<->network provider switch takes effect.
        beginCollection()
    }

    /**
     * Connects to the paired external sensors (if any) recorded in the active
     * session, so their latest readings can be stamped onto points inside the
     * same foreground service that owns GPS.
     */
    private fun startSensorCapture() {
        val session = store.loadSession()
        stopSensorCapture()
        session?.heartRateDeviceId?.takeIf { it.isNotEmpty() }?.let { deviceId ->
            heartRateClient = HeartRateGattClient(applicationContext).also { it.start(deviceId) }
        }
        session?.powerDeviceId?.takeIf { it.isNotEmpty() }?.let { deviceId ->
            powerClient = CyclingPowerGattClient(applicationContext).also { it.start(deviceId) }
        }
        session?.cadenceDeviceId?.takeIf { it.isNotEmpty() }?.let { deviceId ->
            cadenceClient = CadenceGattClient(applicationContext).also { it.start(deviceId) }
        }
    }

    private fun stopSensorCapture() {
        heartRateClient?.stop()
        heartRateClient = null
        powerClient?.stop()
        powerClient = null
        cadenceClient?.stop()
        cadenceClient = null
    }

    private fun onLocationFix(location: Location) {
        val session = store.loadSession() ?: return
        when (session.status) {
            ActiveActivitySessionData.STATUS_RECORDING -> onActiveLocationFix(session, location)
            ActiveActivitySessionData.STATUS_PAUSED -> {
                // A manual pause stops collection entirely (see `handlePause`/
                // `stopCollection`), so only an auto-paused session can still
                // be receiving fixes here. This also guards a stray in-flight
                // fix delivered just as a manual pause took effect.
                if (session.pausedAutomatically) {
                    onAutoPausedLocationFix(session, location)
                }
            }
            else -> Unit
        }
    }

    private fun onActiveLocationFix(session: ActiveActivitySessionData, location: Location) {
        val nowMillis = if (location.time > 0) location.time else System.currentTimeMillis()

        // Feed the auto-pause detector before the accuracy/speed gates below,
        // so stillness timing advances from wall-clock progress on every fix
        // (including noisy ones the detector itself discounts as movement
        // evidence), matching the Dart geolocator recorder.
        val transition = autoPauseDetector?.onActivePoint(movementSample(location, nowMillis))
            ?: MovementAutoPauseTransition.NONE
        if (transition == MovementAutoPauseTransition.AUTO_PAUSE) {
            transitionToAutoPaused(session, nowMillis)
            return
        }

        // Drop low-accuracy fixes (e.g. network-provider triangulation) before
        // they enter the track. Without this, ghost points far from the real
        // route are persisted and bridged into the recorded line.
        if (location.hasAccuracy() && location.accuracy > MAX_ACCURACY_METERS) {
            return
        }
        val previous = lastPointEpochMillis
        if (previous != null && nowMillis > previous && location.hasSpeed() &&
            location.speed > MAX_SPEED_METERS_PER_SECOND
        ) {
            return
        }
        var segmentIndex = session.currentSegmentIndex
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
            heartRateBpm = heartRateClient?.latestBpm,
            powerWatts = powerClient?.latestWatts,
            cadenceRpm = cadenceClient?.latestRpm,
        )
        try {
            store.appendPoints(listOf(point))
        } catch (_: Exception) {
            persistFailure()
            ActivityRecorderCoordinator.emitFailed(
                ActivityRecorderCoordinator.REASON_PERSISTENCE_FAILED,
            )
            stopCollection()
            stopForegroundCompat()
            stopSelf()
            return
        }
        ActivityRecorderCoordinator.emitPointBatch(listOf(point))
    }

    /**
     * Feeds a fix received while auto-paused. Collection keeps running (the
     * location listener is never unregistered for an automatic pause) so
     * movement can resume the recording without user interaction, but no
     * point is persisted until hysteresis confirms movement has resumed.
     */
    private fun onAutoPausedLocationFix(session: ActiveActivitySessionData, location: Location) {
        val detector = autoPauseDetector ?: return
        val nowMillis = if (location.time > 0) location.time else System.currentTimeMillis()
        val transition = detector.onAutoPausedPoint(movementSample(location, nowMillis))
        if (transition != MovementAutoPauseTransition.AUTO_RESUME) {
            return
        }
        val resumed = session.copy(
            status = ActiveActivitySessionData.STATUS_RECORDING,
            resumedAt = IsoTime.format(Date(nowMillis)),
            pausedAt = null,
            pausedAutomatically = false,
        )
        store.saveSession(resumed)
        resumedFromPause = true
        ActivityRecorderCoordinator.emitSession(
            ActivityRecorderCoordinator.TYPE_AUTO_RESUMED,
            resumed,
        )
        // Persist this same triggering fix as the first point of the new
        // segment, matching the manual resume flow (`resumedFromPause` forces
        // a segment break above).
        onActiveLocationFix(resumed, location)
    }

    private fun transitionToAutoPaused(session: ActiveActivitySessionData, nowMillis: Long) {
        val paused = session.copy(
            status = ActiveActivitySessionData.STATUS_PAUSED,
            pausedAt = IsoTime.format(Date(nowMillis)),
            elapsedDurationSeconds = session.elapsedSecondsAt(nowMillis),
            pausedAutomatically = true,
        )
        store.saveSession(paused)
        ActivityRecorderCoordinator.emitSession(
            ActivityRecorderCoordinator.TYPE_AUTO_PAUSED,
            paused,
        )
        // Deliberately does not call `stopCollection()`: an automatic pause
        // must keep monitoring location so movement can resume the recording
        // without user interaction, unlike a manual pause which stops
        // collection entirely (see `stopCollection`).
    }

    private fun movementSample(location: Location, nowMillis: Long): MovementSample {
        return MovementSample(
            timestampMillis = nowMillis,
            latitude = location.latitude,
            longitude = location.longitude,
            speedMetersPerSecond = if (location.hasSpeed()) location.speed.toDouble() else null,
            horizontalAccuracyMeters =
                if (location.hasAccuracy()) location.accuracy.toDouble() else null,
        )
    }

    /**
     * Selects a single location provider, preferring GPS for its precision.
     *
     * The network provider is used only as a fallback when GPS is unavailable.
     * Subscribing to both simultaneously interleaves a precise GPS stream with
     * low-accuracy WiFi/cell triangulation, which surfaces as "ghost" points
     * hundreds of meters to kilometers off the real track (the network fixes
     * also lack altitude). Picking one provider avoids that artifact; the
     * accuracy gate in [onLocationFix] guards the remaining fallback case.
     */
    private fun selectProviders(
        manager: LocationManager,
        hasFine: Boolean,
        hasCoarse: Boolean,
    ): List<String> {
        val gpsEnabled = isProviderEnabled(manager, LocationManager.GPS_PROVIDER)
        if (hasFine && gpsEnabled) {
            return listOf(LocationManager.GPS_PROVIDER)
        }
        val networkEnabled = isProviderEnabled(manager, LocationManager.NETWORK_PROVIDER)
        if ((hasFine || hasCoarse) && networkEnabled) {
            return listOf(LocationManager.NETWORK_PROVIDER)
        }
        return emptyList()
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

    /**
     * Whether this service may declare [ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE].
     *
     * Android 14 (API 34) validates every declared foreground-service type at
     * `startForeground` time. The `connectedDevice` type requires the app to
     * *hold at runtime* one of the nearby-device permissions; the only ones this
     * app declares (`BLUETOOTH_CONNECT`/`BLUETOOTH_SCAN`) are runtime
     * permissions that a user who never paired a sensor has never granted.
     *
     * Requesting the type unconditionally therefore threw `SecurityException`
     * for plain GPS-only recordings, which `startForegroundOrFail` reported as
     * a lost location permission and the recording never started. Only claim
     * the type when the session actually binds a sensor AND the permission is
     * granted.
     */
    @VisibleForTesting
    internal fun canDeclareConnectedDeviceType(session: ActiveActivitySessionData?): Boolean {
        if (session == null || !session.hasAnySensorBinding()) {
            return false
        }
        return hasPermission(Manifest.permission.BLUETOOTH_CONNECT) ||
            hasPermission(Manifest.permission.BLUETOOTH_SCAN)
    }

    private fun startForegroundCompat(title: String, text: String) {
        val notification = buildNotification(title, text)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            // `location` is always required; `connectedDevice` is added only
            // when it is both needed and permitted (see the doc above).
            var types = ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION
            if (canDeclareConnectedDeviceType(store.loadSession())) {
                types = types or ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE
            }
            startForeground(NOTIFICATION_ID, notification, types)
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
        stopSensorCapture()
        releaseWakeLock()
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

        /** Namespaced so this lock is attributable in `dumpsys power`. */
        private const val WAKE_LOCK_TAG = "endurain:activity-recording"

        // Mirror the Dart location/segment policy constants.
        private const val MIN_UPDATE_INTERVAL_MS = 1000L
        private const val MIN_UPDATE_DISTANCE_METERS = 3f
        private const val MAX_TIME_GAP_MILLIS = 30_000L
        private const val MAX_ACCURACY_METERS = 100f
        private const val MAX_SPEED_METERS_PER_SECOND = 90f

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
