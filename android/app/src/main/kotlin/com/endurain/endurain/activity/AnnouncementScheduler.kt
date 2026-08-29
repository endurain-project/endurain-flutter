package com.endurain.endurain.activity

import kotlin.math.roundToInt

/**
 * Advances the durable announcement state by one location fix and returns any
 * spoken announcements that fix triggered.
 *
 * Delegates the actual crossing detection to [AnnouncementThresholdCalculator]
 * (pure threshold math) and rendering to [AnnouncementSpeechBuilder] (pure
 * text formatting); this class only owns the sequencing: accumulate distance
 * since the last fix, pick the metric the configured interval unit tracks,
 * and persist the new "last announced" index so a threshold is never spoken
 * twice — including across a foreground-service restart, since the caller
 * persists the returned [Result.state] durably (see
 * `ActiveActivityStore.saveAnnouncementState`).
 */
object AnnouncementScheduler {

    data class Result(val state: AnnouncementStateData, val announcements: List<String>)

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

        val crossings = if (state.isTimeBased) {
            AnnouncementThresholdCalculator.crossedThresholds(
                intervalValue = state.timeIntervalSeconds.toDouble(),
                previousCumulative = previousElapsed.toDouble(),
                newCumulative = elapsedSeconds.toDouble(),
                lastAnnouncedIndex = state.lastAnnouncedTimeIndex,
            )
        } else {
            AnnouncementThresholdCalculator.crossedThresholds(
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
            lastElapsedSeconds = elapsedSeconds,
        )
        if (crossings.isEmpty()) {
            return Result(updated, emptyList())
        }

        val announcements = ArrayList<String>(crossings.size)
        val elapsedSpan = elapsedSeconds - previousElapsed
        for (crossing in crossings) {
            val interpolatedDistanceMeters: Double
            val interpolatedElapsedSeconds: Int
            if (state.isTimeBased) {
                interpolatedElapsedSeconds = crossing.thresholdValue.roundToInt()
                interpolatedDistanceMeters = state.cumulativeDistanceMeters +
                    crossing.interpolationFraction * deltaMeters
                updated = updated.copy(lastAnnouncedTimeIndex = crossing.thresholdIndex)
            } else {
                interpolatedDistanceMeters = crossing.thresholdValue
                interpolatedElapsedSeconds = (
                    previousElapsed + crossing.interpolationFraction * elapsedSpan
                    ).roundToInt()
                updated = updated.copy(lastAnnouncedDistanceIndex = crossing.thresholdIndex)
            }
            announcements.add(
                AnnouncementSpeechBuilder.build(
                    state,
                    interpolatedDistanceMeters,
                    interpolatedElapsedSeconds,
                ),
            )
        }
        return Result(updated, announcements)
    }
}
