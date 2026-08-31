package com.endurain.endurain.activity

import java.text.DecimalFormatSymbols
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
 *
 * Decimal numbers carry the announcement locale's decimal separator: a
 * text-to-speech engine reading German text pronounces `1.5` using `.` as a
 * *thousands* separator, so a fixed `Locale.US` point would speak "1.5 km" as
 * fifteen kilometres. Only the separator glyph is localized — digits stay
 * ASCII and no grouping separator is ever inserted, since grouped digits are
 * another common source of engine misreadings.
 */
object AnnouncementSpeechBuilder {
    private const val METERS_PER_KILOMETER = 1000.0
    private const val METERS_PER_MILE = 1609.344

    /** Roughly 10.8 km/h; only ever used to render a settings preview. */
    private const val SAMPLE_SPEED_METERS_PER_SECOND = 3.0

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
            formatDecimal(displayDistance, state.languageTag),
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

    /**
     * Builds the sample sentence spoken by the settings preview action.
     *
     * The milestone is the user's own configured interval, so the preview
     * states what a real announcement will state. The other axis is derived
     * from [SAMPLE_SPEED_METERS_PER_SECOND] purely so the pace/speed fragments
     * are self-consistent — a preview has no recorded data to report.
     */
    fun buildPreview(state: AnnouncementStateData): String {
        val distanceMeters: Double
        val elapsedSeconds: Int
        if (state.isTimeBased) {
            elapsedSeconds = state.timeIntervalSeconds
            distanceMeters = SAMPLE_SPEED_METERS_PER_SECOND * elapsedSeconds
        } else {
            distanceMeters = state.distanceIntervalMeters
            elapsedSeconds = (distanceMeters / SAMPLE_SPEED_METERS_PER_SECOND).roundToInt()
        }
        return build(state, distanceMeters, elapsedSeconds)
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
        return formatDecimal(unitsPerHour, state.languageTag)
    }

    /** One decimal place, using [languageTag]'s decimal separator. */
    private fun formatDecimal(value: Double, languageTag: String): String {
        val locale = if (languageTag.isBlank()) {
            Locale.US
        } else {
            Locale.forLanguageTag(languageTag)
        }
        val separator = DecimalFormatSymbols.getInstance(locale).decimalSeparator
        return String.format(Locale.US, "%.1f", value).replace('.', separator)
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
