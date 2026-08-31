package com.endurain.endurain.activity

import kotlin.math.roundToInt

/**
 * Advances durable distance and elapsed-time announcement state.
 *
 * Delegates the actual crossing detection to [AnnouncementThresholdCalculator]
 * (pure threshold math) and rendering to [AnnouncementSpeechBuilder] (pure
 * text formatting). [onFix] accumulates distance from accepted GPS samples;
 * [onElapsedTime] advances time milestones independently while stationary.
 * Both return the new "last announced" index so a threshold is never spoken
 * twice, including across a foreground-service restart.
 */
object AnnouncementScheduler {

    data class Result(val state: AnnouncementStateData, val announcements: List<String>)

    /**
     * Advances a time-based schedule without requiring a location fix.
     *
     * The caller supplies elapsed *recording* time from [SessionTiming], so
     * paused time is already excluded. Distance remains at the latest value
     * accumulated by [onFix], allowing a stationary recording to announce on
     * time while preserving its last known overall pace.
     */
    fun onElapsedTime(
        state: AnnouncementStateData,
        elapsedSeconds: Int,
    ): Result {
        if (!state.enabled || !state.isTimeBased) {
            return Result(state, emptyList())
        }
        val monotonicElapsedSeconds = maxOf(state.lastElapsedSeconds, elapsedSeconds)
        val crossing = AnnouncementThresholdCalculator.latestCrossing(
            intervalValue = state.timeIntervalSeconds.toDouble(),
            // The durable index is authoritative. Elapsed state may already
            // have advanced past an unannounced threshold on a resumed GPS fix.
            previousCumulative = 0.0,
            newCumulative = monotonicElapsedSeconds.toDouble(),
            lastAnnouncedIndex = state.lastAnnouncedTimeIndex,
        )
        var updated = state.copy(lastElapsedSeconds = monotonicElapsedSeconds)
        if (crossing == null) {
            return Result(updated, emptyList())
        }

        val crossingElapsedSeconds = crossing.thresholdValue.roundToInt()
        updated = updated.copy(
            lastAnnouncedTimeIndex = crossing.thresholdIndex,
            lastAnnouncementDistanceMeters = state.cumulativeDistanceMeters,
            lastAnnouncementElapsedSeconds = crossingElapsedSeconds,
        )
        val announcement = AnnouncementSpeechBuilder.build(
            state,
            state.cumulativeDistanceMeters,
            crossingElapsedSeconds,
        )
        return Result(updated, listOf(announcement))
    }

    /**
     * @param isNewSegment true when this fix starts a new track segment (a
     *   pause/resume boundary or a large time gap). The distance/time seed is
     *   reset without computing a delta so a segment break can never be
     *   mistaken for real distance covered.
     */
    fun onFix(
        state: AnnouncementStateData,
        latitude: Double,
        longitude: Double,
        elapsedSeconds: Int,
        isNewSegment: Boolean,
    ): Result {
        if (!state.enabled) {
            return Result(state, emptyList())
        }
        if (isNewSegment || state.lastLatitude == null || state.lastLongitude == null) {
            return Result(
                state.copy(
                    lastLatitude = latitude,
                    lastLongitude = longitude,
                    lastElapsedSeconds = elapsedSeconds,
                ),
                emptyList(),
            )
        }

        val deltaMeters = GeoDistance.haversineMeters(
            state.lastLatitude,
            state.lastLongitude,
            latitude,
            longitude,
        )
        val newCumulativeDistance = state.cumulativeDistanceMeters + deltaMeters
        val previousElapsed = state.lastElapsedSeconds
        val monotonicElapsedSeconds = maxOf(previousElapsed, elapsedSeconds)

        val crossing = if (state.isTimeBased) {
            AnnouncementThresholdCalculator.latestCrossing(
                intervalValue = state.timeIntervalSeconds.toDouble(),
                previousCumulative = previousElapsed.toDouble(),
                newCumulative = monotonicElapsedSeconds.toDouble(),
                lastAnnouncedIndex = state.lastAnnouncedTimeIndex,
            )
        } else {
            AnnouncementThresholdCalculator.latestCrossing(
                intervalValue = state.distanceIntervalMeters,
                previousCumulative = state.cumulativeDistanceMeters,
                newCumulative = newCumulativeDistance,
                lastAnnouncedIndex = state.lastAnnouncedDistanceIndex,
            )
        }

        var updated = state.copy(
            cumulativeDistanceMeters = newCumulativeDistance,
            lastLatitude = latitude,
            lastLongitude = longitude,
            lastElapsedSeconds = monotonicElapsedSeconds,
        )
        if (crossing == null) {
            return Result(updated, emptyList())
        }

        val elapsedSpan = monotonicElapsedSeconds - previousElapsed
        val interpolatedDistanceMeters: Double
        val interpolatedElapsedSeconds: Int
        if (state.isTimeBased) {
            interpolatedElapsedSeconds = crossing.thresholdValue.roundToInt()
            interpolatedDistanceMeters = state.cumulativeDistanceMeters +
                crossing.interpolationFraction * deltaMeters
            updated = updated.copy(
                lastAnnouncedTimeIndex = crossing.thresholdIndex,
                lastAnnouncementDistanceMeters = interpolatedDistanceMeters,
                lastAnnouncementElapsedSeconds = interpolatedElapsedSeconds,
            )
        } else {
            interpolatedDistanceMeters = crossing.thresholdValue
            interpolatedElapsedSeconds = (
                previousElapsed + crossing.interpolationFraction * elapsedSpan
                ).roundToInt()
            updated = updated.copy(
                lastAnnouncedDistanceIndex = crossing.thresholdIndex,
                lastAnnouncementDistanceMeters = interpolatedDistanceMeters,
                lastAnnouncementElapsedSeconds = interpolatedElapsedSeconds,
            )
        }
        val announcement = AnnouncementSpeechBuilder.build(
            state,
            interpolatedDistanceMeters,
            interpolatedElapsedSeconds,
        )
        return Result(updated, listOf(announcement))
    }
}
