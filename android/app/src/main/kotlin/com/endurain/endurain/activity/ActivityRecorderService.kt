package com.endurain.endurain.activity

import android.Manifest
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationManager
import android.os.IBinder
import android.util.Log
import androidx.annotation.VisibleForTesting
import androidx.core.content.ContextCompat

/**
 * Foreground service that owns background location collection for an active
 * recording.
 *
 * Each fix is persisted to the durable [ActiveActivityStore] before being
 * broadcast to Flutter, so points survive process death and are replayed via
 * `drain` on reattach.
 *
 * Threading: every command and every location fix runs on the dedicated
 * [RecorderWorker] thread (started in [onCreate], quit in [onDestroy]), which
 * therefore owns all non-`@Volatile` state below and keeps fixes and commands
 * strictly ordered. The main thread only enters through [onStartCommand] /
 * the static API (both just post to the worker) and receives Flutter
 * callbacks via [ActivityRecorderCoordinator], which hops back to it.
 */
class ActivityRecorderService : Service() {
    private lateinit var store: ActiveActivityStore

    private lateinit var worker: RecorderWorker
    private lateinit var collector: RecorderLocationCollector
    private lateinit var notifications: RecorderNotifications
    private lateinit var announcements: RecorderAnnouncementDriver
    private lateinit var wakeLock: RecordingWakeLock
    private lateinit var foreground: ForegroundServiceCompat
    private lateinit var sensors: RecorderSensors
    private val fixProcessor = LocationFixProcessor()
    private lateinit var fixPipeline: RecordingFixPipeline
    private lateinit var collection: RecorderCollection
    private lateinit var warmUp: StartWarmUp

    private var activeNotificationTitle: String? = null
    private var activeNotificationText: String? = null

    override fun onCreate() {
        super.onCreate()
        worker = RecorderWorker.create()
        store = ActiveActivityStore.of(applicationContext)
        collector = RecorderLocationCollector(
            this,
            getSystemService(Context.LOCATION_SERVICE) as? LocationManager,
            worker.looper,
        )
        notifications = RecorderNotifications(this)
        announcements = RecorderAnnouncementDriver(this, store, worker.handler)
        wakeLock = RecordingWakeLock(this, worker.handler)
        foreground = ForegroundServiceCompat(this, notifications, store)
        sensors = RecorderSensors(applicationContext)
        fixPipeline = RecordingFixPipeline(
            store, fixProcessor, sensors, announcements, wakeLock,
            onPersistenceFailure = ::failPersistence,
        )
        collection = RecorderCollection(
            store, collector, fixProcessor, fixPipeline, wakeLock, announcements,
        )
        warmUp = StartWarmUp(
            this, worker, collector, foreground, notifications,
            hasLocationPermission = ::hasAnyLocationPermission,
            recordingOwnsService = {
                collection.isCollecting || store.loadSession()?.isActive == true
            },
        )
        notifications.createChannel()
        activeInstance = this
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        worker.run { dispatch(intent) }
        return START_STICKY
    }

    private fun dispatch(intent: Intent?) {
        when (intent?.action) {
            ACTION_START -> handleStart(intent)
            ACTION_WARM_UP -> warmUp.begin(intent)
            ACTION_RESUME -> handleResume()
            ACTION_PAUSE -> handlePause()
            ACTION_STOP -> handleStop()
            ACTION_RECONNECT -> handleRestart(rebaseTime = false)
            else -> handleRestart()
        }
    }

    private fun handleStart(intent: Intent) {
        startRecording(intent.getStringExtra(EXTRA_TITLE), intent.getStringExtra(EXTRA_TEXT))
    }

    private fun startRecording(requestedTitle: String?, requestedText: String?) {
        warmUp.handOver()
        announcements.reset()
        val title = requestedTitle ?: notifications.defaultTitle()
        val text = requestedText ?: notifications.defaultText()
        activeNotificationTitle = title
        activeNotificationText = text
        fixProcessor.resumedFromPause = false
        if (!hasAnyLocationPermission()) {
            failForLostPermission()
            foreground.stopBeforeForegroundWork()
            return
        }
        if (!foreground.startOrFail(title, text)) {
            return
        }
        if (!beginCollection()) {
            stopAfterCollectionFailure()
            return
        }
        startSensorCapture()
    }

    private fun handleResume() {
        val session = store.loadSession()
        fixProcessor.resumedFromPause = session != null
        if (!hasAnyLocationPermission()) {
            failForLostPermission()
            foreground.stopBeforeForegroundWork()
            return
        }
        if (!foreground.startOrFail(
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
        fixProcessor.resumedFromPause = false
        foreground.stop()
        stopSelf()
    }

    /**
     * Restores collection after process death when movement is still needed.
     *
     * [rebaseTime] is true for the system's sticky restart (no intent), which
     * runs in the background with no Flutter engine to report a failure to;
     * false for [ACTION_RECONNECT], which [SessionRecovery.recover] sent with
     * `startForegroundService` after already rebasing the session.
     */
    private fun handleRestart(rebaseTime: Boolean = true) {
        val stickyRestart = rebaseTime
        val session = store.loadSession()
        if (session == null || !session.isActive) {
            if (stickyRestart) stopSelf() else foreground.stopBeforeForegroundWork()
            return
        }
        if (collection.collectingSessionId == session.localSessionId &&
            session.status == ActiveActivitySessionData.STATUS_RECORDING
        ) {
            return
        }
        // Rebase first: every failure below persists the session as failed,
        // and must not count the time the process was dead as active time.
        if (rebaseTime && session.status == ActiveActivitySessionData.STATUS_RECORDING) {
            SessionRecovery.rebaseAfterInterruption(store, session)
        }
        if (!hasAnyLocationPermission()) {
            failForLostPermission()
            if (stickyRestart) {
                notifications.postInterrupted()
                stopSelf()
            } else {
                foreground.stopBeforeForegroundWork()
            }
            return
        }
        // Android 14+ refuses a location foreground service started from the
        // background without background location, so a sticky restart can
        // fail here; the notification lets the user reopen and resume.
        if (!foreground.startOrFail(
            activeNotificationTitle ?: notifications.defaultTitle(),
            activeNotificationText ?: notifications.defaultText(),
            notifyInterrupted = stickyRestart,
        )) {
            return
        }
        if (session.requiresLocationMonitoring) {
            fixProcessor.resumedFromPause =
                session.status == ActiveActivitySessionData.STATUS_RECORDING &&
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
    private fun beginCollection(): Boolean =
        collection.begin(onFix = ::onLocationFix, onProviderToggled = ::handleProviderAvailabilityChanged)

    /** Stops the service after [beginCollection] failed (and reported why). */
    private fun stopAfterCollectionFailure() {
        stopCollection()
        stopSensorCapture()
        foreground.stop()
        stopSelf()
    }

    private fun persistFailure() = SessionRecovery.persistFailure(store)

    /** Persists and reports that location permission is gone. */
    private fun failForLostPermission() {
        persistFailure()
        ActivityRecorderCoordinator.emitFailed(ActivityRecorderCoordinator.REASON_PERMISSION_LOST)
    }

    private fun stopCollection() = collection.stop()

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
            collection.fail(failure)
            stopCollection()
            stopSelf()
            return
        }
        // Re-subscribe so a GPS<->network provider switch takes effect.
        if (!beginCollection()) {
            stopAfterCollectionFailure()
        }
    }

    private fun startSensorCapture() {
        sensors.start(store.loadSession())
    }

    private fun stopSensorCapture() {
        sensors.stop()
    }

    private fun onLocationFix(location: Location) {
        try {
            fixPipeline.onFix(LocationFix.from(location))
        } catch (error: Exception) {
            // A store that cannot be read or written ends the recording
            // cleanly, as a failed point append does.
            Log.w(TAG, "Could not process a location fix", error)
            failPersistence()
        }
    }

    /** Ends the recording after the store refused a write; Dart is told why. */
    private fun failPersistence() {
        persistFailure()
        ActivityRecorderCoordinator.emitFailed(
            ActivityRecorderCoordinator.REASON_PERSISTENCE_FAILED,
        )
        stopCollection()
        foreground.stop()
        stopSelf()
    }

    private fun hasAnyLocationPermission(): Boolean = hasLocationPermission(this)

    /** Swiping the app away ends a countdown's warm-up; a recording keeps running. */
    override fun onTaskRemoved(rootIntent: Intent?) {
        worker.run { warmUp.finish() }
        super.onTaskRemoved(rootIntent)
    }

    override fun onDestroy() {
        if (activeInstance === this) {
            activeInstance = null
        }
        // Torn down on the worker, after any command already queued, then the
        // thread ends; the release of the wake lock and listeners must not
        // race a fix in flight.
        worker.run { tearDown() }
        worker.quitWhenIdle()
        super.onDestroy()
    }

    private fun tearDown() {
        AudioAnnouncer.stop()
        if (store.loadSession()?.isActive == true) {
            announcements.flush()
        }
        stopCollection()
        warmUp.handOver()
        stopSensorCapture()
        wakeLock.release()
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

        private fun baseIntent(context: Context, action: String): Intent {
            return Intent(context, ActivityRecorderService::class.java).setAction(action)
        }

        /** Pauses collection in the running service, if any (see `recover`). */
        internal fun pauseActiveInstance() {
            activeInstance?.let { service -> service.worker.run { service.handlePause() } }
        }

        /** Whether the running service is already collecting [sessionId]. */
        internal fun isCollecting(sessionId: String): Boolean =
            activeInstance?.collection?.collectingSessionId == sessionId

        /**
         * Asks the service to reattach to the stored session. May throw a
         * [RuntimeException] when Android refuses the foreground start.
         */
        internal fun reconnect(context: Context) {
            ContextCompat.startForegroundService(context, baseIntent(context, ACTION_RECONNECT))
        }

        fun start(context: Context, title: String?, text: String?) {
            val warm = activeInstance
            if (warm != null && warm.warmUp.isActive) {
                // The countdown's service is already in the foreground with
                // location access: start recording in it, even if the app is
                // in the background by now. Posted so the channel reports the
                // start before the first point, as with a normal start.
                warm.worker.handler.post { warm.startRecording(title, text) }
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
            activeInstance?.let { service -> service.worker.run { service.warmUp.finish() } }
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
