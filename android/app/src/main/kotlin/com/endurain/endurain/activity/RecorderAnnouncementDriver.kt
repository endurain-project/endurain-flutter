package com.endurain.endurain.activity

import android.content.Context
import android.location.Location
import android.os.Handler
import android.os.Looper
import android.os.SystemClock

/**
 * Drives spoken announcements for an active recording: distance progress on
 * every fix, time-based thresholds on a one-shot main-looper timer, and the
 * auto-pause/resume cues. Progress is cached in memory and persisted through
 * [ActiveActivityStore] (see [AnnouncementStateCache]).
 */
internal class RecorderAnnouncementDriver(
    private val context: Context,
    private val store: ActiveActivityStore,
) {
    private val cache = AnnouncementStateCache()
    private val handler = Handler(Looper.getMainLooper())
    private val timeRunnable = Runnable {
        announceTimeIfDue(System.currentTimeMillis())
        scheduleNextTimeAnnouncement()
    }

    /** Starts a recording's announcements from a clean state. */
    fun reset() {
        cache.reset()
    }

    /** Cancels the pending time-based announcement. */
    fun cancelScheduled() {
        handler.removeCallbacks(timeRunnable)
    }

    /** Advances announcement progress and speaks threshold crossings. */
    fun onFix(nowMillis: Long, location: Location, isNewSegment: Boolean) {
        val announcementState = currentState() ?: return
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
        if (!cacheState(result.state, persistBeforeSpeech = result.announcements.isNotEmpty())) {
            return
        }
        speakAll(result.announcements, announcementState)
    }

    /**
     * Schedules one main-looper callback at the next elapsed-time threshold.
     * One-shot scheduling avoids polling and serializes state with GPS fixes.
     */
    fun scheduleNextTimeAnnouncement() {
        handler.removeCallbacks(timeRunnable)
        val announcementState = currentState() ?: return
        if (!announcementState.enabled || !announcementState.isTimeBased ||
            announcementState.timeIntervalSeconds !in
            MIN_TIME_INTERVAL_SECONDS..MAX_TIME_INTERVAL_SECONDS
        ) {
            return
        }
        val session = store.loadSession() ?: return
        if (session.status != ActiveActivitySessionData.STATUS_RECORDING) {
            return
        }
        val elapsedSeconds = SessionTiming.elapsedSeconds(session, System.currentTimeMillis())
        val nextIndex = maxOf(1L, announcementState.lastAnnouncedTimeIndex.toLong() + 1L)
        val nextThresholdSeconds = nextIndex * announcementState.timeIntervalSeconds.toLong()
        val remainingSeconds = nextThresholdSeconds - elapsedSeconds.toLong()
        val delayMillis = maxOf(TIME_RETRY_MILLIS, remainingSeconds * 1000L)
        handler.postDelayed(timeRunnable, delayMillis)
    }

    /** Persists pending progress so pause, auto-pause and teardown lose nothing. */
    fun flush() {
        val uptimeMillis = SystemClock.elapsedRealtime()
        val state = cache.stateToPersist(uptimeMillis, force = true) ?: return
        try {
            store.saveAnnouncementState(state)
            cache.markPersisted(uptimeMillis)
        } catch (_: Exception) {
            // Announcement progress must never make recording teardown fail.
        }
    }

    /** Speaks the state-change cue for an auto-pause or auto-resume, if enabled. */
    fun speakTransitionCue(autoPaused: Boolean) {
        val announcementState = currentState() ?: return
        val message = announcementState.transitionMessage(autoPaused) ?: return
        speakAll(listOf(message), announcementState)
    }

    /** Advances a time-based schedule without waiting for another GPS fix. */
    private fun announceTimeIfDue(referenceMillis: Long) {
        val announcementState = currentState() ?: return
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
        if (!cacheState(result.state, persistBeforeSpeech = result.announcements.isNotEmpty())) {
            return
        }
        speakAll(result.announcements, announcementState)
    }

    private fun speakAll(texts: List<String>, state: AnnouncementStateData) {
        for (text in texts) {
            AudioAnnouncer.speak(context, text, state.duckOtherAudio, state.languageTag)
        }
    }

    private fun currentState(): AnnouncementStateData? {
        cache.state?.let { return it }
        val state = store.loadAnnouncementState() ?: return null
        cache.restore(state, SystemClock.elapsedRealtime())
        return state
    }

    /**
     * Keeps normal GPS progress in memory, checkpoints it periodically, and
     * makes threshold progress durable before the corresponding speech.
     */
    private fun cacheState(state: AnnouncementStateData, persistBeforeSpeech: Boolean): Boolean {
        val previousState = cache.state
        cache.update(state)
        val uptimeMillis = SystemClock.elapsedRealtime()
        val stateToPersist = cache.stateToPersist(uptimeMillis, force = persistBeforeSpeech)
            ?: return true
        return try {
            store.saveAnnouncementState(stateToPersist)
            cache.markPersisted(uptimeMillis)
            true
        } catch (_: Exception) {
            if (persistBeforeSpeech && previousState != null) {
                cache.update(previousState)
            }
            !persistBeforeSpeech
        }
    }

    private companion object {
        const val MIN_TIME_INTERVAL_SECONDS = 60
        const val MAX_TIME_INTERVAL_SECONDS = 3600
        const val TIME_RETRY_MILLIS = 1000L
    }
}
