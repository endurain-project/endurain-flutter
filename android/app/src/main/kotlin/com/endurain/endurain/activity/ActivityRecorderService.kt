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
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.os.SystemClock
import com.endurain.endurain.MainActivity
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
    private var collectingSessionId: String? = null

    /**
     * Location listener of the start-countdown warm-up; its fixes are dropped.
     * Non-null while the service only keeps the app alive for a countdown.
     */
    private var warmUpListener: LocationListener? = null
    private var isWarmingUp = false
    private var nextPointOffset = 0

    /** Whether [startForegroundCompat] succeeded since the last [stopForegroundCompat]. */
    private var inForeground = false

    private var lastPointEpochMillis: Long? = null
    private var activeNotificationTitle: String? = null
    private var activeNotificationText: String? = null
    private var resumedFromPause = false
    private var heartRateClient: HeartRateGattClient? = null
    private var powerClient: CyclingPowerGattClient? = null
    private var cadenceClient: CadenceGattClient? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var autoPauseDetector: MovementAutoPauseDetector? = null
    private val announcementStateCache = AnnouncementStateCache()
    private val announcementHandler = Handler(Looper.getMainLooper())
    private val timeAnnouncementRunnable = Runnable {
        announceTimeIfDue(System.currentTimeMillis())
        scheduleNextTimeAnnouncement()
    }

    /** Ends a warm-up that no recording and no `endStartWarmUp` ever ended. */
    private val warmUpTimeoutRunnable = Runnable { finishWarmUp() }

    override fun onCreate() {
        super.onCreate()
        activeInstance = this
        store = ActiveActivityStore.of(applicationContext)
        locationManager =
            getSystemService(Context.LOCATION_SERVICE) as? LocationManager
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> handleStart(intent)
            ACTION_WARM_UP -> handleWarmUp(intent)
            ACTION_RESUME -> handleResume()
            ACTION_PAUSE -> handlePause()
            ACTION_STOP -> handleStop()
            ACTION_RECONNECT -> handleRestart(rebaseTime = false)
            else -> handleRestart()
        }
        return START_STICKY
    }

    private fun handleStart(intent: Intent) {
        startRecording(intent.getStringExtra(EXTRA_TITLE), intent.getStringExtra(EXTRA_TEXT))
    }

    private fun startRecording(requestedTitle: String?, requestedText: String?) {
        stopWarmUpLocationUpdates()
        announcementHandler.removeCallbacks(warmUpTimeoutRunnable)
        isWarmingUp = false
        announcementStateCache.reset()
        val title = requestedTitle ?: defaultTitle()
        val text = requestedText ?: defaultText()
        activeNotificationTitle = title
        activeNotificationText = text
        resumedFromPause = false
        if (!hasAnyLocationPermission()) {
            persistFailure()
            ActivityRecorderCoordinator.emitFailed(
                ActivityRecorderCoordinator.REASON_PERMISSION_LOST,
            )
            stopBeforeForegroundWork()
            return
        }
        if (!startForegroundOrFail(title, text)) {
            return
        }
        if (!beginCollection()) {
            stopAfterCollectionFailure()
            return
        }
        startSensorCapture()
    }

    /**
     * Keeps the app alive during the start countdown.
     *
     * On newer Android versions an app the user switched away from can be
     * frozen within seconds, which would stall the countdown. A foreground
     * service prevents that. It is started while the app is still in the
     * foreground, so it gets location access now; when the countdown ends the
     * recording starts inside this same service (see [start]) instead of
     * starting a new one from the background, which Android would refuse or
     * grant without location. GPS runs meanwhile, so the first point is
     * accurate, but every fix is dropped and nothing is stored.
     *
     * The safety timeout is sized from the countdown length the channel put
     * in [EXTRA_COUNTDOWN_SECONDS]; see [warmUpTimeoutMillis].
     */
    private fun handleWarmUp(intent: Intent) {
        if (collectingSessionId != null || store.loadSession()?.isActive == true) {
            // A recording already owns this service. A fresh instance started
            // just for this warm-up must still enter the foreground before it
            // stops.
            if (!inForeground) {
                stopBeforeForegroundWork()
            }
            return
        }
        if (!hasAnyLocationPermission()) {
            stopBeforeForegroundWork()
            return
        }
        try {
            // Declares `connectedDevice` whenever it is permitted, before the
            // session says whether a sensor is bound: the recording that starts
            // from this service may then keep or drop the type, but never has
            // to add one while the app is in the background.
            startForegroundCompat(
                defaultTitle(),
                getString(R.string.activity_recording_notification_starting),
                connectedDevice = hasPermission(Manifest.permission.BLUETOOTH_CONNECT) ||
                    hasPermission(Manifest.permission.BLUETOOTH_SCAN),
            )
        } catch (_: RuntimeException) {
            stopSelf()
            return
        }
        isWarmingUp = true
        startWarmUpLocationUpdates()
        announcementHandler.removeCallbacks(warmUpTimeoutRunnable)
        val countdownSeconds = if (intent.hasExtra(EXTRA_COUNTDOWN_SECONDS)) {
            intent.getLongExtra(EXTRA_COUNTDOWN_SECONDS, 0L)
        } else {
            null
        }
        announcementHandler.postDelayed(
            warmUpTimeoutRunnable,
            warmUpTimeoutMillis(countdownSeconds),
        )
    }

    /** Ends the warm-up when no recording started from it. */
    private fun finishWarmUp() {
        announcementHandler.removeCallbacks(warmUpTimeoutRunnable)
        if (!isWarmingUp) {
            return
        }
        isWarmingUp = false
        stopWarmUpLocationUpdates()
        stopForegroundCompat()
        stopSelf()
    }

    private fun startWarmUpLocationUpdates() {
        val manager = locationManager ?: return
        val hasFine = hasPermission(Manifest.permission.ACCESS_FINE_LOCATION)
        val hasCoarse = hasPermission(Manifest.permission.ACCESS_COARSE_LOCATION)
        val listener = object : LocationListener {
            // Dropped on purpose: nothing is recorded before the countdown ends.
            override fun onLocationChanged(location: Location) {}

            override fun onProviderEnabled(provider: String) {}

            override fun onProviderDisabled(provider: String) {}

            @Deprecated("Deprecated in Android API 29")
            override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}
        }
        for (provider in selectProviders(manager, hasFine, hasCoarse)) {
            try {
                manager.requestLocationUpdates(
                    provider,
                    MIN_UPDATE_INTERVAL_MS,
                    0f,
                    listener,
                    Looper.getMainLooper(),
                )
                warmUpListener = listener
            } catch (_: SecurityException) {
                // The foreground service alone still keeps the countdown alive.
            } catch (_: IllegalArgumentException) {
                // Provider disappeared between discovery and subscription.
            }
        }
    }

    private fun stopWarmUpLocationUpdates() {
        val listener = warmUpListener ?: return
        warmUpListener = null
        try {
            locationManager?.removeUpdates(listener)
        } catch (_: Exception) {
            // Best effort; nothing to recover here.
        }
    }

    private fun handleResume() {
        val session = store.loadSession()
        resumedFromPause = session != null
        if (!hasAnyLocationPermission()) {
            persistFailure()
            ActivityRecorderCoordinator.emitFailed(
                ActivityRecorderCoordinator.REASON_PERMISSION_LOST,
            )
            stopBeforeForegroundWork()
            return
        }
        if (!startForegroundOrFail(
            activeNotificationTitle ?: defaultTitle(),
            activeNotificationText ?: defaultText(),
        )) {
            return
        }
        if (session != null && session.status == ActiveActivitySessionData.STATUS_RECORDING) {
            if (!beginCollection()) {
                stopAfterCollectionFailure()
                return
            }
            startSensorCapture()
        }
    }

    private fun handlePause() {
        AudioAnnouncer.stop()
        flushAnnouncementState()
        stopCollection()
        // Keep the foreground notification so recording can resume cheaply.
    }

    private fun handleStop() {
        AudioAnnouncer.stop()
        stopCollection()
        stopSensorCapture()
        resumedFromPause = false
        stopForegroundCompat()
        stopSelf()
    }

    /**
     * Restores collection after process death when movement is still needed.
     *
     * [rebaseTime] is true for the system's sticky restart (no intent), which
     * runs in the background with no Flutter engine to report a failure to;
     * false for [ACTION_RECONNECT], which [recover] sent with
     * `startForegroundService` after already rebasing the session.
     */
    private fun handleRestart(rebaseTime: Boolean = true) {
        val stickyRestart = rebaseTime
        val session = store.loadSession()
        if (session == null || !session.isActive) {
            if (stickyRestart) stopSelf() else stopBeforeForegroundWork()
            return
        }
        if (collectingSessionId == session.localSessionId &&
            session.status == ActiveActivitySessionData.STATUS_RECORDING
        ) {
            return
        }
        // Rebase first: every failure below persists the session as failed,
        // and must not count the time the process was dead as active time.
        if (rebaseTime && session.status == ActiveActivitySessionData.STATUS_RECORDING) {
            store.saveSession(
                SessionTiming.afterInterruption(
                    session,
                    store.lastPoint()?.timestamp?.let(IsoTime::toEpochMillis),
                    System.currentTimeMillis(),
                ),
            )
        }
        if (!hasAnyLocationPermission()) {
            persistFailure()
            ActivityRecorderCoordinator.emitFailed(
                ActivityRecorderCoordinator.REASON_PERMISSION_LOST,
            )
            if (stickyRestart) {
                postInterruptedNotification()
                stopSelf()
            } else {
                stopBeforeForegroundWork()
            }
            return
        }
        // Android 14+ refuses a location foreground service started from the
        // background without background location, so a sticky restart can
        // fail here; the notification lets the user reopen and resume.
        if (!startForegroundOrFail(
            activeNotificationTitle ?: defaultTitle(),
            activeNotificationText ?: defaultText(),
            notifyInterrupted = stickyRestart,
        )) {
            return
        }
        if (session.requiresLocationMonitoring) {
            resumedFromPause = session.status == ActiveActivitySessionData.STATUS_RECORDING &&
                store.lastPoint() != null
            if (!beginCollection()) {
                if (stickyRestart) {
                    postInterruptedNotification()
                }
                stopAfterCollectionFailure()
                return
            }
            startSensorCapture()
        }
    }

    /**
     * Subscribes to location updates for the active session. Returns false
     * when collection could not start; the failure is then already persisted
     * and emitted, and the caller stops the service.
     */
    private fun beginCollection(): Boolean {
        stopCollection()
        val manager = locationManager
        if (manager == null) {
            persistFailure()
            ActivityRecorderCoordinator.emitFailed(
                ActivityRecorderCoordinator.REASON_LOCATION_UNAVAILABLE,
            )
            return false
        }
        val hasFine = hasPermission(Manifest.permission.ACCESS_FINE_LOCATION)
        val hasCoarse = hasPermission(Manifest.permission.ACCESS_COARSE_LOCATION)
        if (!hasFine && !hasCoarse) {
            persistFailure()
            ActivityRecorderCoordinator.emitFailed(
                ActivityRecorderCoordinator.REASON_PERMISSION_LOST,
            )
            return false
        }
        val providers = selectProviders(manager, hasFine, hasCoarse)
        if (providers.isEmpty()) {
            persistFailure()
            ActivityRecorderCoordinator.emitFailed(
                ActivityRecorderCoordinator.REASON_LOCATION_UNAVAILABLE,
            )
            return false
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
        // Anchor stillness to this collection (re)start, not the last stored
        // point: that point can predate a manual pause or provider restart,
        // which would let the first slow fix auto-pause immediately.
        autoPauseDetector = MovementAutoPauseDetector(
            MovementAutoPauseConfig(
                enabled = session?.autoPauseEnabled ?: false,
                pauseDelayMillis = (session?.autoPauseDelaySeconds ?: 5) * 1000L,
            ),
        ).also { it.reset(System.currentTimeMillis()) }
        val minUpdateDistanceMeters = if (session?.autoPauseEnabled == true) {
            0f
        } else {
            MIN_UPDATE_DISTANCE_METERS
        }
        nextPointOffset = store.pointCount()
        var registeredProvider = false
        var permissionFailure = false
        for (provider in providers) {
            try {
                manager.requestLocationUpdates(
                    provider,
                    MIN_UPDATE_INTERVAL_MS,
                    minUpdateDistanceMeters,
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
            return false
        }
        collectingSessionId = store.loadSession()?.localSessionId
        acquireWakeLock()
        scheduleNextTimeAnnouncement()
        return true
    }

    /** Stops the service after [beginCollection] failed (and reported why). */
    private fun stopAfterCollectionFailure() {
        stopCollection()
        stopSensorCapture()
        stopForegroundCompat()
        stopSelf()
    }

    /**
     * Stops the service before any work started. A service started with
     * `startForegroundService` must call `startForeground` before it stops,
     * or Android 9+ crashes the app, so it briefly claims the foreground with
     * the default notification first. On Android 14+ that can itself be
     * refused (no location permission left to claim the type); nothing more
     * can be done then.
     */
    private fun stopBeforeForegroundWork() {
        try {
            startForegroundCompat(defaultTitle(), defaultText(), connectedDevice = false)
        } catch (_: RuntimeException) {
            // See above.
        }
        stopForegroundCompat()
        stopSelf()
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
    * so recovery requires explicit user action even if the failure event was
    * dropped while Flutter was detached. Points and session ownership remain.
     */
    private fun persistFailure() {
        val session = store.loadSession() ?: return
        if (session.isActive) {
            val nowMillis = System.currentTimeMillis()
            store.saveSession(
                session.copy(
                    status = ActiveActivitySessionData.STATUS_FAILED,
                    pausedAt = IsoTime.format(Date(nowMillis)),
                    elapsedDurationSeconds = SessionTiming.elapsedSeconds(session, nowMillis),
                ),
            )
        }
    }

    private fun stopCollection() {
        collectingSessionId = null
        // Released first and unconditionally: the listener may already be null
        // (e.g. a start that never registered a provider), and the wake lock
        // must never outlive collection.
        announcementHandler.removeCallbacks(timeAnnouncementRunnable)
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
        if (!beginCollection()) {
            stopAfterCollectionFailure()
        }
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
        var isNewSegment = false
        if (resumedFromPause) {
            if (previous != null) {
                segmentIndex += 1
                isNewSegment = true
                store.saveSession(session.copy(currentSegmentIndex = segmentIndex))
            }
            resumedFromPause = false
        } else if (previous != null && nowMillis - previous > MAX_TIME_GAP_MILLIS) {
            // Large time gap: start a new segment to avoid bridging a false line.
            segmentIndex += 1
            isNewSegment = true
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
        ActivityRecorderCoordinator.emitPointBatch(
            listOf(point),
            session.localSessionId,
            nextPointOffset,
        )
        nextPointOffset += 1
        announceIfDue(nowMillis, location, isNewSegment)
    }

    /** Advances announcement progress and speaks threshold crossings. */
    private fun announceIfDue(nowMillis: Long, location: Location, isNewSegment: Boolean) {
        val announcementState = currentAnnouncementState() ?: return
        if (!announcementState.enabled) {
            return
        }
        val session = store.loadSession() ?: return
        val elapsedSeconds = SessionTiming.elapsedSeconds(session, nowMillis)
        val result = AnnouncementScheduler.onFix(
            state = announcementState,
            latitude = location.latitude,
            longitude = location.longitude,
            elapsedSeconds = elapsedSeconds,
            isNewSegment = isNewSegment,
        )
        if (!cacheAnnouncementState(
                result.state,
                persistBeforeSpeech = result.announcements.isNotEmpty(),
            )
        ) {
            return
        }
        for (text in result.announcements) {
            AudioAnnouncer.speak(
                applicationContext,
                text,
                announcementState.duckOtherAudio,
                announcementState.languageTag,
            )
        }
    }

    /**
     * Schedules one main-looper callback at the next elapsed-time threshold.
     * One-shot scheduling avoids polling and serializes state with GPS fixes.
     */
    private fun scheduleNextTimeAnnouncement() {
        announcementHandler.removeCallbacks(timeAnnouncementRunnable)
        val announcementState = currentAnnouncementState() ?: return
        if (!announcementState.enabled || !announcementState.isTimeBased ||
            announcementState.timeIntervalSeconds !in
            MIN_TIME_ANNOUNCEMENT_INTERVAL_SECONDS..MAX_TIME_ANNOUNCEMENT_INTERVAL_SECONDS
        ) {
            return
        }
        val session = store.loadSession() ?: return
        if (session.status != ActiveActivitySessionData.STATUS_RECORDING) {
            return
        }
        val elapsedSeconds = SessionTiming.elapsedSeconds(
            session,
            System.currentTimeMillis(),
        )
        val nextIndex = maxOf(1L, announcementState.lastAnnouncedTimeIndex.toLong() + 1L)
        val nextThresholdSeconds =
            nextIndex * announcementState.timeIntervalSeconds.toLong()
        val remainingSeconds = nextThresholdSeconds - elapsedSeconds.toLong()
        val delayMillis = maxOf(
            TIME_ANNOUNCEMENT_RETRY_MILLIS,
            remainingSeconds * 1000L,
        )
        announcementHandler.postDelayed(timeAnnouncementRunnable, delayMillis)
    }

    /** Advances a time-based schedule without waiting for another GPS fix. */
    private fun announceTimeIfDue(referenceMillis: Long) {
        val announcementState = currentAnnouncementState() ?: return
        if (!announcementState.enabled || !announcementState.isTimeBased) {
            return
        }
        val session = store.loadSession() ?: return
        if (session.status != ActiveActivitySessionData.STATUS_RECORDING) {
            return
        }
        val result = AnnouncementScheduler.onElapsedTime(
            state = announcementState,
            elapsedSeconds = SessionTiming.elapsedSeconds(session, referenceMillis),
        )
        if (result.state == announcementState) {
            return
        }
        if (!cacheAnnouncementState(
                result.state,
                persistBeforeSpeech = result.announcements.isNotEmpty(),
            )
        ) {
            return
        }
        for (text in result.announcements) {
            AudioAnnouncer.speak(
                applicationContext,
                text,
                announcementState.duckOtherAudio,
                announcementState.languageTag,
            )
        }
    }

    private fun currentAnnouncementState(): AnnouncementStateData? {
        announcementStateCache.state?.let { return it }
        val state = store.loadAnnouncementState() ?: return null
        announcementStateCache.restore(state, SystemClock.elapsedRealtime())
        return state
    }

    /**
     * Keeps normal GPS progress in memory, checkpoints it periodically, and
     * makes threshold progress durable before the corresponding speech.
     */
    private fun cacheAnnouncementState(
        state: AnnouncementStateData,
        persistBeforeSpeech: Boolean,
    ): Boolean {
        val previousState = announcementStateCache.state
        announcementStateCache.update(state)
        val uptimeMillis = SystemClock.elapsedRealtime()
        val stateToPersist = announcementStateCache.stateToPersist(
            uptimeMillis,
            force = persistBeforeSpeech,
        ) ?: return true
        return try {
            store.saveAnnouncementState(stateToPersist)
            announcementStateCache.markPersisted(uptimeMillis)
            true
        } catch (_: Exception) {
            if (persistBeforeSpeech && previousState != null) {
                announcementStateCache.update(previousState)
            }
            !persistBeforeSpeech
        }
    }

    private fun flushAnnouncementState() {
        val uptimeMillis = SystemClock.elapsedRealtime()
        val state = announcementStateCache.stateToPersist(
            uptimeMillis,
            force = true,
        ) ?: return
        try {
            store.saveAnnouncementState(state)
            announcementStateCache.markPersisted(uptimeMillis)
        } catch (_: Exception) {
            // Announcement progress must never make recording teardown fail.
        }
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
        // Queue the state cue before this fix can enqueue a progress update.
        speakTransitionCue(autoPaused = false)
        // Persist this same triggering fix as the first point of the new
        // segment, matching the manual resume flow (`resumedFromPause` forces
        // a segment break above).
        onActiveLocationFix(resumed, location)
        scheduleNextTimeAnnouncement()
    }

    private fun transitionToAutoPaused(session: ActiveActivitySessionData, nowMillis: Long) {
        // Back-date the pause to when movement last stopped so the stillness
        // delay is not counted as recorded time.
        val anchorMillis = IsoTime.toEpochMillis(session.resumedAt ?: session.startedAt)
        val pausedAtMillis = (autoPauseDetector?.lastMovementAtMillis ?: nowMillis)
            .coerceAtLeast(anchorMillis ?: Long.MIN_VALUE)
            .coerceAtMost(nowMillis)
        val paused = session.copy(
            status = ActiveActivitySessionData.STATUS_PAUSED,
            pausedAt = IsoTime.format(Date(pausedAtMillis)),
            elapsedDurationSeconds = session.elapsedSecondsAt(pausedAtMillis),
            pausedAutomatically = true,
        )
        store.saveSession(paused)
        ActivityRecorderCoordinator.emitSession(
            ActivityRecorderCoordinator.TYPE_AUTO_PAUSED,
            paused,
        )
        // Cancel queued progress speech before announcing the state change.
        AudioAnnouncer.stop()
        speakTransitionCue(autoPaused = true)
        flushAnnouncementState()
        announcementHandler.removeCallbacks(timeAnnouncementRunnable)
        // Deliberately does not call `stopCollection()`: an automatic pause
        // must keep monitoring location so movement can resume the recording
        // without user interaction, unlike a manual pause which stops
        // collection entirely (see `stopCollection`).
    }

    private fun speakTransitionCue(autoPaused: Boolean) {
        val announcementState = currentAnnouncementState() ?: return
        val message = announcementState.transitionMessage(autoPaused) ?: return
        AudioAnnouncer.speak(
            applicationContext,
            message,
            announcementState.duckOtherAudio,
            announcementState.languageTag,
        )
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

    private fun hasAnyLocationPermission(): Boolean = hasLocationPermission(this)

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

    private fun startForegroundCompat(
        title: String,
        text: String,
        connectedDevice: Boolean = canDeclareConnectedDeviceType(store.loadSession()),
    ) {
        val notification = buildNotification(title, text)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            // `location` is always required; `connectedDevice` is added only
            // when it is both needed and permitted (see the doc above).
            var types = ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION
            if (connectedDevice) {
                types = types or ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE
            }
            startForeground(NOTIFICATION_ID, notification, types)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
        inForeground = true
    }

    /**
     * Enters the foreground or persists and reports the failure and stops.
     * With [notifyInterrupted], a failure also posts a notification that the
     * recording was interrupted, for restarts no Flutter engine sees.
     */
    private fun startForegroundOrFail(
        title: String,
        text: String,
        notifyInterrupted: Boolean = false,
    ): Boolean {
        val reason = try {
            startForegroundCompat(title, text)
            cancelInterruptedNotification()
            return true
        } catch (_: SecurityException) {
            ActivityRecorderCoordinator.REASON_PERMISSION_LOST
        } catch (_: RuntimeException) {
            ActivityRecorderCoordinator.REASON_LOCATION_STREAM_FAILED
        }
        persistFailure()
        ActivityRecorderCoordinator.emitFailed(reason)
        if (notifyInterrupted) {
            postInterruptedNotification()
        }
        stopSelf()
        return false
    }

    /**
     * Tells the user a recording stopped while the app was in the background.
     * Tapping it opens the app, whose recovery offers to resume.
     */
    private fun postInterruptedNotification() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            !hasPermission(Manifest.permission.POST_NOTIFICATIONS)
        ) {
            return
        }
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return
        try {
            createAlertNotificationChannel(manager)
            val openApp = PendingIntent.getActivity(
                this,
                0,
                Intent(this, MainActivity::class.java)
                    .setAction(Intent.ACTION_MAIN)
                    .addCategory(Intent.CATEGORY_LAUNCHER)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            val notification = NotificationCompat.Builder(this, ALERT_CHANNEL_ID)
                .setContentTitle(getString(R.string.activity_recording_interrupted_title))
                .setContentText(getString(R.string.activity_recording_interrupted_text))
                .setSmallIcon(applicationInfo.icon)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setCategory(NotificationCompat.CATEGORY_STATUS)
                .setAutoCancel(true)
                .setContentIntent(openApp)
                .build()
            manager.notify(INTERRUPTED_NOTIFICATION_ID, notification)
        } catch (_: RuntimeException) {
            // Best effort: the failed session is persisted either way.
        }
    }

    private fun cancelInterruptedNotification() {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return
        try {
            manager.cancel(INTERRUPTED_NOTIFICATION_ID)
        } catch (_: RuntimeException) {
            // Best effort.
        }
    }

    private fun createAlertNotificationChannel(manager: NotificationManager) {
        if (manager.getNotificationChannel(ALERT_CHANNEL_ID) != null) {
            return
        }
        val channel = NotificationChannel(
            ALERT_CHANNEL_ID,
            getString(R.string.activity_recording_alert_channel_name),
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = getString(R.string.activity_recording_alert_channel_description)
        }
        manager.createNotificationChannel(channel)
    }

    private fun stopForegroundCompat() {
        inForeground = false
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

    /** Swiping the app away ends a countdown's warm-up; a recording keeps running. */
    override fun onTaskRemoved(rootIntent: Intent?) {
        finishWarmUp()
        super.onTaskRemoved(rootIntent)
    }

    override fun onDestroy() {
        announcementHandler.removeCallbacks(warmUpTimeoutRunnable)
        AudioAnnouncer.stop()
        if (store.loadSession()?.isActive == true) {
            flushAnnouncementState()
        }
        stopCollection()
        stopWarmUpLocationUpdates()
        isWarmingUp = false
        stopSensorCapture()
        releaseWakeLock()
        if (activeInstance === this) {
            activeInstance = null
        }
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    companion object {
        private var activeInstance: ActivityRecorderService? = null

        const val ACTION_START = "com.endurain.endurain.activity.action.START"
        const val ACTION_PAUSE = "com.endurain.endurain.activity.action.PAUSE"
        const val ACTION_RESUME = "com.endurain.endurain.activity.action.RESUME"
        const val ACTION_STOP = "com.endurain.endurain.activity.action.STOP"
        const val ACTION_WARM_UP = "com.endurain.endurain.activity.action.WARM_UP"
        @VisibleForTesting
        internal const val ACTION_RECONNECT = "com.endurain.endurain.activity.action.RECONNECT"

        const val EXTRA_TITLE = "title"
        const val EXTRA_TEXT = "text"

        /** Full length of the start countdown, in seconds (a `Long` extra). */
        const val EXTRA_COUNTDOWN_SECONDS = "countdownSeconds"

        private const val CHANNEL_ID = "activity_recording"
        private const val NOTIFICATION_ID = 4711
        private const val ALERT_CHANNEL_ID = "activity_recording_alerts"
        private const val INTERRUPTED_NOTIFICATION_ID = 4712

        /**
         * Leak guard for a warm-up nobody ended (Dart died mid-countdown), used
         * when the countdown length is unknown. Longer than the longest
         * countdown Dart allows (StartCountdown's 10-minute maxRemaining), so
         * it never ends a live countdown early. Also the upper clamp of
         * [warmUpTimeoutMillis].
         */
        @VisibleForTesting
        internal const val WARM_UP_TIMEOUT_MILLIS = 11 * 60_000L

        /** Lower clamp of [warmUpTimeoutMillis]. */
        @VisibleForTesting
        internal const val MIN_WARM_UP_TIMEOUT_MILLIS = 60_000L

        /** Slack past the countdown's end before the warm-up is ended anyway. */
        private const val WARM_UP_TIMEOUT_MARGIN_MILLIS = 60_000L

        /**
         * The warm-up's safety timeout: the countdown plus a minute, clamped
         * to [[MIN_WARM_UP_TIMEOUT_MILLIS], [WARM_UP_TIMEOUT_MILLIS]], so a
         * leaked warm-up of a short countdown does not hold a location
         * foreground service for 11 minutes. [WARM_UP_TIMEOUT_MILLIS] when
         * [countdownSeconds] is unknown (an older Dart build).
         */
        @VisibleForTesting
        internal fun warmUpTimeoutMillis(countdownSeconds: Long?): Long {
            if (countdownSeconds == null) {
                return WARM_UP_TIMEOUT_MILLIS
            }
            // Bounded first so the multiplication cannot overflow.
            val countdownMillis =
                countdownSeconds.coerceIn(0L, WARM_UP_TIMEOUT_MILLIS / 1000L) * 1000L
            return (countdownMillis + WARM_UP_TIMEOUT_MARGIN_MILLIS)
                .coerceIn(MIN_WARM_UP_TIMEOUT_MILLIS, WARM_UP_TIMEOUT_MILLIS)
        }

        /**
         * Whether the app holds fine or coarse location. Without either, a
         * recorder started with `startForegroundService` cannot claim the
         * `location` foreground type on Android 14+, so callers check this
         * before starting it.
         */
        fun hasLocationPermission(context: Context): Boolean {
            return ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.ACCESS_FINE_LOCATION,
            ) == PackageManager.PERMISSION_GRANTED ||
                ContextCompat.checkSelfPermission(
                    context,
                    Manifest.permission.ACCESS_COARSE_LOCATION,
                ) == PackageManager.PERMISSION_GRANTED
        }

        /** Namespaced so this lock is attributable in `dumpsys power`. */
        private const val WAKE_LOCK_TAG = "endurain:activity-recording"

        // Mirror the Dart location/segment policy constants.
        private const val MIN_UPDATE_INTERVAL_MS = 1000L
        private const val MIN_UPDATE_DISTANCE_METERS = 3f
        private const val MAX_TIME_GAP_MILLIS = 30_000L
        private const val MAX_ACCURACY_METERS = 100f
        private const val MAX_SPEED_METERS_PER_SECOND = 90f
        private const val MIN_TIME_ANNOUNCEMENT_INTERVAL_SECONDS = 60
        private const val MAX_TIME_ANNOUNCEMENT_INTERVAL_SECONDS = 3600
        private const val TIME_ANNOUNCEMENT_RETRY_MILLIS = 1000L

        private fun baseIntent(context: Context, action: String): Intent {
            return Intent(context, ActivityRecorderService::class.java).setAction(action)
        }

        fun recover(context: Context): ActiveActivitySessionData? {
            val store = ActiveActivityStore.of(context)
            val session = store.loadSession() ?: return null
            if (session.status == ActiveActivitySessionData.STATUS_FAILED) {
                val paused = session.copy(
                    status = ActiveActivitySessionData.STATUS_PAUSED,
                    pausedAt = IsoTime.nowUtc(),
                    endedAt = null,
                )
                store.saveSession(paused)
                activeInstance?.handlePause()
                return paused
            }
            if (!session.requiresLocationMonitoring ||
                activeInstance?.collectingSessionId == session.localSessionId
            ) {
                return session
            }
            val recovered = SessionTiming.afterInterruption(
                session,
                store.lastPoint()?.timestamp?.let(IsoTime::toEpochMillis),
                System.currentTimeMillis(),
            )
            store.saveSession(recovered)
            // Checked before `startForegroundService`: without location the
            // service could not enter the foreground on Android 14+, and the
            // app would crash for not calling `startForeground` in time.
            val failureReason = if (!hasLocationPermission(context)) {
                ActivityRecorderCoordinator.REASON_PERMISSION_LOST
            } else {
                try {
                    ContextCompat.startForegroundService(
                        context,
                        baseIntent(context, ACTION_RECONNECT),
                    )
                    null
                } catch (_: RuntimeException) {
                    ActivityRecorderCoordinator.REASON_LOCATION_STREAM_FAILED
                }
            }
            if (failureReason != null) {
                val paused = recovered.copy(
                    status = ActiveActivitySessionData.STATUS_PAUSED,
                    pausedAt = IsoTime.nowUtc(),
                )
                store.saveSession(paused)
                ActivityRecorderCoordinator.emitFailed(failureReason)
                return paused
            }
            return recovered
        }

        fun start(context: Context, title: String?, text: String?) {
            val warm = activeInstance
            if (warm != null && warm.isWarmingUp) {
                // The countdown's service is already in the foreground with
                // location access: start recording in it, even if the app is
                // in the background by now. Posted so the channel reports the
                // start before the first point, as with a normal start.
                Handler(Looper.getMainLooper()).post { warm.startRecording(title, text) }
                return
            }
            val intent = baseIntent(context, ACTION_START)
            title?.let { intent.putExtra(EXTRA_TITLE, it) }
            text?.let { intent.putExtra(EXTRA_TEXT, it) }
            ContextCompat.startForegroundService(context, intent)
        }

        /**
         * Starts the start-countdown warm-up; see [handleWarmUp].
         * [countdownSeconds] sizes its safety timeout; null when unknown.
         */
        fun beginWarmUp(context: Context, countdownSeconds: Long? = null) {
            val intent = baseIntent(context, ACTION_WARM_UP)
            countdownSeconds?.let { intent.putExtra(EXTRA_COUNTDOWN_SECONDS, it) }
            ContextCompat.startForegroundService(context, intent)
        }

        /** Ends the warm-up, unless a recording started from it. */
        fun endWarmUp() {
            activeInstance?.finishWarmUp()
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
