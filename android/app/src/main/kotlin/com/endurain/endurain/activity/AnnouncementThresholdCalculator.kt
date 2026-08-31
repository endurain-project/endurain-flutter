package com.endurain.endurain.activity

import kotlin.math.floor

/**
 * Pure, stateless calculation of the latest announcement threshold a
 * cumulative value (distance in meters, or elapsed time in seconds) crossed.
 *
 * Thresholds are multiples of [intervalValue]: 1x, 2x, 3x, ... A threshold is
 * "crossed" the first time the cumulative value reaches or passes it. Callers
 * persist [Crossing.thresholdIndex] as the new `lastAnnouncedIndex` so a
 * threshold is never announced twice, even across a process restart (the
 * index is durable state owned by the caller, not this object).
 *
 * [Crossing.interpolationFraction] is where, between `previousCumulative` and
 * `newCumulative`, the threshold actually falls (0 = at the previous sample,
 * 1 = at the new sample). Callers use it to linearly interpolate the *other*
 * metric (elapsed time when thresholds are distance-based, or distance when
 * time-based) so an announcement reports the value at the threshold instant
 * rather than at the next arbitrary GPS fix — otherwise a slow GPS update rate
 * would make "every 1 km" announcements drift later and later.
 *
 * When a gap skips several thresholds, only the latest is returned. Older
 * milestones are stale and must not form a speech backlog.
 */
object AnnouncementThresholdCalculator {

    data class Crossing(
        val thresholdIndex: Int,
        val thresholdValue: Double,
        val interpolationFraction: Double,
    )

    fun latestCrossing(
        intervalValue: Double,
        previousCumulative: Double,
        newCumulative: Double,
        lastAnnouncedIndex: Int,
    ): Crossing? {
        if (intervalValue <= 0.0 || !intervalValue.isFinite()) {
            return null
        }
        if (newCumulative <= previousCumulative) {
            return null
        }
        if (!previousCumulative.isFinite() || !newCumulative.isFinite()) {
            return null
        }

        // The highest threshold multiple already covered by newCumulative.
        val newIndex = floor(newCumulative / intervalValue).toInt()
        val startIndex = maxOf(lastAnnouncedIndex + 1, 1)
        if (newIndex < startIndex) {
            return null
        }

        val span = newCumulative - previousCumulative
        val thresholdValue = intervalValue * newIndex
        val fraction = if (span > 0.0) {
            ((thresholdValue - previousCumulative) / span).coerceIn(0.0, 1.0)
        } else {
            0.0
        }
        return Crossing(newIndex, thresholdValue, fraction)
    }
}
