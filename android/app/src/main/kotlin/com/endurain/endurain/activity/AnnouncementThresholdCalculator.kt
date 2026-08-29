package com.endurain.endurain.activity

import kotlin.math.floor

/**
 * Pure, stateless calculation of which announcement thresholds a cumulative
 * value (distance in meters, or elapsed time in seconds) has newly crossed.
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
 * A single call can return more than one [Crossing] when a GPS gap or a large
 * jump skips past several thresholds at once (e.g. the app was suspended for
 * two minutes); [maxCrossingsPerUpdate] bounds that list so a corrupt or
 * absurd interval can never spin this into an unbounded loop.
 */
object AnnouncementThresholdCalculator {

    data class Crossing(
        val thresholdIndex: Int,
        val thresholdValue: Double,
        val interpolationFraction: Double,
    )

    fun crossedThresholds(
        intervalValue: Double,
        previousCumulative: Double,
        newCumulative: Double,
        lastAnnouncedIndex: Int,
        maxCrossingsPerUpdate: Int = 20,
    ): List<Crossing> {
        if (intervalValue <= 0.0 || !intervalValue.isFinite()) {
            return emptyList()
        }
        if (newCumulative <= previousCumulative) {
            return emptyList()
        }
        if (!previousCumulative.isFinite() || !newCumulative.isFinite()) {
            return emptyList()
        }

        // The highest threshold multiple already covered by newCumulative.
        val newIndex = floor(newCumulative / intervalValue).toInt()
        val startIndex = maxOf(lastAnnouncedIndex + 1, 1)
        if (newIndex < startIndex) {
            return emptyList()
        }

        val result = ArrayList<Crossing>()
        val span = newCumulative - previousCumulative
        var index = startIndex
        while (index <= newIndex && result.size < maxCrossingsPerUpdate) {
            val thresholdValue = intervalValue * index
            val fraction = if (span > 0.0) {
                ((thresholdValue - previousCumulative) / span).coerceIn(0.0, 1.0)
            } else {
                0.0
            }
            result.add(Crossing(index, thresholdValue, fraction))
            index++
        }
        return result
    }
}
