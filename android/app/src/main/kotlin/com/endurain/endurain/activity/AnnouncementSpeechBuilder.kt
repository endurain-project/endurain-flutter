package com.endurain.endurain.activity

import java.util.Locale
import kotlin.math.roundToInt

/**
 * Builds the spoken sentence for one announcement from an
 * [AnnouncementStateData]'s localized templates and the concrete values at
 * the threshold instant.
 *
 * Every template was rendered by the Dart side from `AppLocalizations` (see
 * `AudioAnnouncementConfig.build`) with a sentinel placeholder still present
 * (`{value}` in unit templates and named fragments in the message template) —
 * see that class's doc comment for why a literal
 * substring replace here is sufficient for correct per-locale phrasing.
 * Numbers themselves are formatted with a fixed `Locale.US` decimal point:
 * text-to-speech engines read digits correctly regardless of the separator
 * glyph, so this avoids re-implementing 30+ locales' number formatting
 * natively.
 */
object AnnouncementSpeechBuilder {
    private const val METERS_PER_KILOMETER = 1000.0
    private const val METERS_PER_MILE = 1609.344

    /**
     * @param distanceMeters cumulative distance (in meters) at the
     *   announcement instant, already interpolated to the exact threshold.
     * @param elapsedSeconds cumulative elapsed recording time (in seconds) at
     *   the announcement instant, already interpolated to the exact
     *   threshold.
     */
    fun build(
        state: AnnouncementStateData,
        distanceMeters: Double,
        elapsedSeconds: Int,
    ): String {
        val displayDistance = if (state.useImperialUnits) {
            distanceMeters / METERS_PER_MILE
        } else {
            distanceMeters / METERS_PER_KILOMETER
        }
        val distanceText = state.distanceUnitTemplate.replace(
            PLACEHOLDER_VALUE,
            formatDecimal(displayDistance),
        )
        val durationText = formatClock(elapsedSeconds)
        val lapMetricText = buildMetricText(
            state,
            maxOf(0.0, distanceMeters - state.lastAnnouncementDistanceMeters),
            maxOf(0, elapsedSeconds - state.lastAnnouncementElapsedSeconds),
        )
        val overallMetricText = buildMetricText(
            state,
            distanceMeters,
            elapsedSeconds,
        )

        return state.messageTemplate
            .replace(PLACEHOLDER_DISTANCE, distanceText)
            .replace(PLACEHOLDER_DURATION, durationText)
            .replace(PLACEHOLDER_LAP_METRIC, lapMetricText)
            .replace(PLACEHOLDER_OVERALL_METRIC, overallMetricText)
    }

    private fun buildMetricText(
        state: AnnouncementStateData,
        distanceMeters: Double,
        elapsedSeconds: Int,
    ): String {
        val value = if (state.metric == AnnouncementStateData.METRIC_SPEED) {
            formatSpeed(state, distanceMeters, elapsedSeconds)
        } else {
            formatPace(state, distanceMeters, elapsedSeconds)
        }
        if (value == null) {
            return state.metricLabel
        }
        val valueWithUnit = state.metricUnitTemplate.replace(PLACEHOLDER_VALUE, value)
        return "${state.metricLabel} $valueWithUnit".trim()
    }

    private fun formatPace(
        state: AnnouncementStateData,
        distanceMeters: Double,
        elapsedSeconds: Int,
    ): String? {
        if (distanceMeters <= 0.0) {
            return null
        }
        val unitMeters = if (state.useImperialUnits) METERS_PER_MILE else METERS_PER_KILOMETER
        val secondsPerUnit = elapsedSeconds / (distanceMeters / unitMeters)
        if (!secondsPerUnit.isFinite() || secondsPerUnit < 0) {
            return null
        }
        return formatClock(secondsPerUnit.roundToInt())
    }

    private fun formatSpeed(
        state: AnnouncementStateData,
        distanceMeters: Double,
        elapsedSeconds: Int,
    ): String? {
        if (distanceMeters < 0.0 || elapsedSeconds <= 0) {
            return null
        }
        val unitMeters = if (state.useImperialUnits) METERS_PER_MILE else METERS_PER_KILOMETER
        val unitsPerHour = distanceMeters / unitMeters * 3600.0 / elapsedSeconds
        if (!unitsPerHour.isFinite() || unitsPerHour < 0.0) {
            return null
        }
        return formatDecimal(unitsPerHour)
    }

    /** One decimal place, fixed `Locale.US` (always a `.` separator). */
    private fun formatDecimal(value: Double): String {
        return String.format(Locale.US, "%.1f", value)
    }

    /** `H:MM:SS` once an hour has elapsed, otherwise `M:SS`. */
    private fun formatClock(totalSeconds: Int): String {
        val safeSeconds = maxOf(0, totalSeconds)
        val hours = safeSeconds / 3600
        val minutes = (safeSeconds % 3600) / 60
        val seconds = safeSeconds % 60
        return if (hours > 0) {
            String.format(Locale.US, "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            String.format(Locale.US, "%d:%02d", minutes, seconds)
        }
    }

    private const val PLACEHOLDER_VALUE = "{value}"
    private const val PLACEHOLDER_DISTANCE = "{distance}"
    private const val PLACEHOLDER_DURATION = "{duration}"
    private const val PLACEHOLDER_LAP_METRIC = "{lapMetric}"
    private const val PLACEHOLDER_OVERALL_METRIC = "{overallMetric}"
}
