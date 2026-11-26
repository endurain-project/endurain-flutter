package com.endurain.endurain.activity

import android.Manifest
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.location.Location
import android.location.LocationManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.annotation.VisibleForTesting
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
    private var collectingSessionId: String? = null

    private lateinit var collector: RecorderLocationCollector
    private lateinit var notifications: RecorderNotifications
    private lateinit var announcements: RecorderAnnouncementDriver
    private lateinit var wakeLock: RecordingWakeLock
    private val handler = Handler(Looper.getMainLooper())

    /** Whether the service only keeps the app alive for a start countdown. */
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
    private var autoPauseDetector: MovementAutoPauseDetector? = null
    /** Ends a warm-up that no recording and no `endStartWarmUp` ever ended. */
    private val warmUpTimeoutRunnable = Runnable { finishWarmUp() }

    override fun onCreate() {
        super.onCreate()
        activeInstance = this
        store = ActiveActivityStore.of(applicationContext)
        collector = RecorderLocationCollector(
            this,
            getSystemService(Context.LOCATION_SERVICE) as? LocationManager,
        )
        notifications = RecorderNotifications(this)
        announcements = RecorderAnnouncementDriver(this, store)
        wakeLock = RecordingWakeLock(this)
        notifications.createChannel()
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
        collector.stopWarmUp()
        handler.removeCallbacks(warmUpTimeoutRunnable)
        isWarmingUp = false
        announcements.reset()
        val title = requestedTitle ?: notifications.defaultTitle()
        val text = requestedText ?: notifications.defaultText()
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
                notifications.defaultTitle(),
                notifications.startingText(),
                connectedDevice = hasPermission(Manifest.permission.BLUETOOTH_CONNECT) ||
                    hasPermission(Manifest.permission.BLUETOOTH_SCAN),
            )
        } catch (_: RuntimeException) {
            stopSelf()
            return
        }
        isWarmingUp = true
        collector.startWarmUp()
        handler.removeCallbacks(warmUpTimeoutRunnable)
        val countdownSeconds = if (intent.hasExtra(EXTRA_COUNTDOWN_SECONDS)) {
            intent.getLongExtra(EXTRA_COUNTDOWN_SECONDS, 0L)
        } else {
            null
        }
        handler.postDelayed(
            warmUpTimeoutRunnable,
            warmUpTimeoutMillis(countdownSeconds),
        )
    }

    /** Ends the warm-up when no recording started from it. */
    private fun finishWarmUp() {
        handler.removeCallbacks(warmUpTimeoutRunnable)
        if (!isWarmingUp) {
            return
        }
        isWarmingUp = false
        collector.stopWarmUp()
        stopForegroundCompat()
        stopSelf()
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
            activeNotificationTitle ?: notifications.defaultTitle(),
            activeNotificationText ?: notifications.defaultText(),
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
        announcements.flush()
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
                notifications.postInterrupted()
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
            activeNotificationTitle ?: notifications.defaultTitle(),
            activeNotificationText ?: notifications.defaultText(),
            notifyInterrupted = stickyRestart,
        )) {
            return
        }
        if (session.requiresLocationMonitoring) {
            resumedFromPause = session.status == ActiveActivitySessionData.STATUS_RECORDING &&
                store.lastPoint() != null
            if (!beginCollection()) {
                if (stickyRestart) {
                    notifications.postInterrupted()
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
        collector.unavailability()?.let {
            failCollection(it)
            return false
        }
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
        val failure = collector.startActive(
            minUpdateDistanceMeters,
            onFix = ::onLocationFix,
            onProviderToggled = ::handleProviderAvailabilityChanged,
        )
        if (failure != null) {
            failCollection(failure)
            return false
        }
        collectingSessionId = store.loadSession()?.localSessionId
        wakeLock.acquire()
        announcements.scheduleNextTimeAnnouncement()
        return true
    }

    /** Persists and reports why collection could not start. */
    private fun failCollection(failure: RecorderLocationCollector.Failure) {
        persistFailure()
        ActivityRecorderCoordinator.emitFailed(
            when (failure) {
                RecorderLocationCollector.Failure.PERMISSION_LOST ->
                    ActivityRecorderCoordinator.REASON_PERMISSION_LOST
                RecorderLocationCollector.Failure.LOCATION_UNAVAILABLE ->
                    ActivityRecorderCoordinator.REASON_LOCATION_UNAVAILABLE
            },
        )
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
            startForegroundCompat(notifications.defaultTitle(), notifications.defaultText(), connectedDevice = false)
        } catch (_: RuntimeException) {
            // See above.
        }
        stopForegroundCompat()
        stopSelf()
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
        announcements.cancelScheduled()
        wakeLock.release()
        // A manual pause reaches here and must stop monitoring movement
        // entirely, so a manually paused recording can never auto-resume;
        // `beginCollection` always rebuilds a fresh detector for the next
        // active period.
        autoPauseDetector = null
        collector.stopActive()
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
        val failure = collector.unavailability()
        if (failure != null) {
            failCollection(failure)
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
        wakeLock.renew()
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
        announcements.onFix(nowMillis, location, isNewSegment)
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
        announcements.speakTransitionCue(autoPaused = false)
        // Persist this same triggering fix as the first point of the new
        // segment, matching the manual resume flow (`resumedFromPause` forces
        // a segment break above).
        onActiveLocationFix(resumed, location)
        announcements.scheduleNextTimeAnnouncement()
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
        announcements.speakTransitionCue(autoPaused = true)
        announcements.flush()
        announcements.cancelScheduled()
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

    private fun verticalAccuracy(location: Location): Double? {
        return if (location.hasVerticalAccuracy()) location.verticalAccuracyMeters.toDouble() else null
    }

    private fun bearingAccuracy(location: Location): Double? {
        return if (location.hasBearingAccuracy()) location.bearingAccuracyDegrees.toDouble() else null
    }

    private fun speedAccuracy(location: Location): Double? {
        return if (location.hasSpeedAccuracy()) location.speedAccuracyMetersPerSecond.toDouble() else null
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
        val notification = notifications.build(title, text)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            // `location` is always required; `connectedDevice` is added only
            // when it is both needed and permitted (see the doc above).
            var types = ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION
            if (connectedDevice) {
                types = types or ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE
            }
            startForeground(RecorderNotifications.NOTIFICATION_ID, notification, types)
        } else {
            startForeground(RecorderNotifications.NOTIFICATION_ID, notification)
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
            notifications.cancelInterrupted()
            return true
        } catch (_: SecurityException) {
            ActivityRecorderCoordinator.REASON_PERMISSION_LOST
        } catch (_: RuntimeException) {
            ActivityRecorderCoordinator.REASON_LOCATION_STREAM_FAILED
        }
        persistFailure()
        ActivityRecorderCoordinator.emitFailed(reason)
        if (notifyInterrupted) {
            notifications.postInterrupted()
        }
        stopSelf()
        return false
    }

    private fun stopForegroundCompat() {
        inForeground = false
        stopForeground(STOP_FOREGROUND_REMOVE)
    }

    /** Swiping the app away ends a countdown's warm-up; a recording keeps running. */
    override fun onTaskRemoved(rootIntent: Intent?) {
        finishWarmUp()
        super.onTaskRemoved(rootIntent)
    }

    override fun onDestroy() {
        handler.removeCallbacks(warmUpTimeoutRunnable)
        AudioAnnouncer.stop()
        if (store.loadSession()?.isActive == true) {
            announcements.flush()
        }
        stopCollection()
        collector.stopWarmUp()
        isWarmingUp = false
        stopSensorCapture()
        wakeLock.release()
        if (activeInstance === this) {
            activeInstance = null
        }
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    companion object {
        private const val TAG = "ActivityRecorder"

        @Volatile
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

        // Mirror the Dart location/segment policy constants.
        private const val MIN_UPDATE_DISTANCE_METERS = 3f
        private const val MAX_TIME_GAP_MILLIS = 30_000L
        private const val MAX_ACCURACY_METERS = 100f
        private const val MAX_SPEED_METERS_PER_SECOND = 90f

        private fun baseIntent(context: Context, action: String): Intent {
            return Intent(context, ActivityRecorderService::class.java).setAction(action)
        }

        /** Pauses collection in the running service, if any (see `recover`). */
        internal fun pauseActiveInstance() {
            activeInstance?.handlePause()
        }

        /** Whether the running service is already collecting [sessionId]. */
        internal fun isCollecting(sessionId: String): Boolean =
            activeInstance?.collectingSessionId == sessionId

        /**
         * Asks the service to reattach to the stored session. May throw a
         * [RuntimeException] when Android refuses the foreground start.
         */
        internal fun reconnect(context: Context) {
            ContextCompat.startForegroundService(context, baseIntent(context, ACTION_RECONNECT))
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

        /**
         * Pauses collection. Always delivered, even before the service's
         * onCreate ran: a pause sent right after [start] must not be dropped.
         */
        fun pause(context: Context) {
            sendToRunningService(context, ACTION_PAUSE)
        }

        fun resume(context: Context) {
            ContextCompat.startForegroundService(
                context,
                baseIntent(context, ACTION_RESUME),
            )
        }

        /** Stops the service; delivered like [pause]. */
        fun stop(context: Context) {
            sendToRunningService(context, ACTION_STOP)
        }

        // No activeInstance check: it is set in onCreate, so a pause or stop
        // sent right after start() would be lost. Starting the service just to
        // stop it is harmless, and from the background it is refused below.
        private fun sendToRunningService(context: Context, action: String) {
            try {
                context.startService(baseIntent(context, action))
            } catch (error: IllegalStateException) {
                // Includes ForegroundServiceStartNotAllowedException: the app is
                // in the background and the service is no longer startable.
                Log.w(TAG, "Could not deliver $action to the recorder service", error)
            }
        }
    }
}
