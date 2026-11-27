package com.endurain.endurain.activity

import android.content.Context
import java.util.Date

/**
 * Brings a stored recording back after the app (re)attaches or the process
 * died, and records failures durably. Shared by the channel's `recover`, the
 * service's sticky restart and its failure paths; all state lives in the
 * [ActiveActivityStore], so any thread may call it.
 */
internal object SessionRecovery {
    /**
     * Brings the stored session back after the app (re)attaches.
     *
     * A failed session becomes a paused one that the user can resume. An
     * interrupted recording is rebased past the time the process was dead and
     * the service is asked to reattach; if Android refuses, the session is
     * left paused and the failure is reported.
     */
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
            ActivityRecorderService.pauseActiveInstance()
            return paused
        }
        if (!session.requiresLocationMonitoring ||
            ActivityRecorderService.isCollecting(session.localSessionId)
        ) {
            return session
        }
        val recovered = rebaseAfterInterruption(store, session)
        // Checked before `startForegroundService`: without location the
        // service could not enter the foreground on Android 14+, and the
        // app would crash for not calling `startForeground` in time.
        val failureReason = if (!ActivityRecorderService.hasLocationPermission(context)) {
            ActivityRecorderCoordinator.REASON_PERMISSION_LOST
        } else {
            try {
                ActivityRecorderService.reconnect(context)
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

    /**
     * Saves [session] without the time the process was dead counted as active
     * time (see [SessionTiming.afterInterruption]) and returns it.
     */
    fun rebaseAfterInterruption(
        store: ActiveActivityStore,
        session: ActiveActivitySessionData,
    ): ActiveActivitySessionData {
        val rebased = SessionTiming.afterInterruption(
            session,
            store.lastPoint()?.timestamp?.let(IsoTime::toEpochMillis),
            System.currentTimeMillis(),
        )
        store.saveSession(rebased)
        return rebased
    }

    /**
     * Persists [ActiveActivitySessionData.STATUS_FAILED] for any active session
     * so recovery requires explicit user action even if the failure event was
     * dropped while Flutter was detached. Points and session ownership remain.
     * Best effort: a store that cannot be written must not turn a failure
     * path into a crash.
     */
    fun persistFailure(store: ActiveActivityStore) {
        try {
            store.updateSession { session ->
                if (!session.isActive) {
                    return@updateSession null
                }
                val nowMillis = System.currentTimeMillis()
                session.copy(
                    status = ActiveActivitySessionData.STATUS_FAILED,
                    pausedAt = IsoTime.format(Date(nowMillis)),
                    elapsedDurationSeconds = SessionTiming.elapsedSeconds(session, nowMillis),
                )
            }
        } catch (_: Exception) {
            // Nothing more can be persisted; the failure event still goes out.
        }
    }
}
