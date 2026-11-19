package com.endurain.endurain.activity

import kotlin.math.max

/**
 * Accumulated elapsed-recording-seconds for a session, shared by
 * [ActivityRecorderChannel] (pause/resume/stop/recover) and
 * [ActivityRecorderService] (GPS and timer announcement scheduling) so the two
 * never drift apart.
 *
 * Mirrors the Dart geolocator recorder: a paused session keeps its stored
 * value; an active one adds the current segment's running time measured from
 * `resumedAt ?? startedAt`.
 */
object SessionTiming {
    fun elapsedSeconds(
        session: ActiveActivitySessionData,
        referenceMillis: Long,
    ): Int {
        if (session.status != ActiveActivitySessionData.STATUS_RECORDING) {
            return session.elapsedDurationSeconds
        }
        val anchor = IsoTime.toEpochMillis(session.resumedAt ?: session.startedAt)
            ?: return session.elapsedDurationSeconds
        val segmentSeconds = ((referenceMillis - anchor) / 1000L).toInt()
        return session.elapsedDurationSeconds + max(0, segmentSeconds)
    }

    fun afterInterruption(
        session: ActiveActivitySessionData,
        lastPointMillis: Long?,
        nowMillis: Long,
    ): ActiveActivitySessionData {
        if (session.status != ActiveActivitySessionData.STATUS_RECORDING) {
            return session
        }
        val referenceMillis = lastPointMillis
            ?: IsoTime.toEpochMillis(session.resumedAt ?: session.startedAt)
            ?: nowMillis
        return session.copy(
            resumedAt = IsoTime.format(java.util.Date(nowMillis)),
            pausedAt = null,
            endedAt = null,
            elapsedDurationSeconds = elapsedSeconds(session, referenceMillis),
        )
    }
}
