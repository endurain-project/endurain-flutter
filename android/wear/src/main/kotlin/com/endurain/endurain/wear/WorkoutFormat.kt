package com.endurain.endurain.wear

import java.util.Locale

object WorkoutFormat {
    fun duration(millis: Long): String {
        val total = maxOf(0L, millis / 1000)
        val hours = total / 3600
        val minutes = (total % 3600) / 60
        val seconds = total % 60
        return if (hours > 0) {
            String.format(Locale.ROOT, "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            String.format(Locale.ROOT, "%02d:%02d", minutes, seconds)
        }
    }

    /** A distance formatted without its unit, which the string resources add. */
    data class Distance(val value: String, val imperial: Boolean)

    /** Kilometres, or miles in the regions that use them. */
    fun distance(
        meters: Double?,
        locale: Locale = Locale.getDefault(),
    ): Distance {
        val value = meters ?: 0.0
        val imperial = locale.country in IMPERIAL_REGIONS
        val converted = if (imperial) value / 1609.344 else value / 1000
        return Distance(String.format(locale, "%.2f", converted), imperial)
    }

    // Mirrors MeasurementSystem.forLocale in the phone app; both are checked
    // against test/fixtures/imperial_regions.json.
    internal val IMPERIAL_REGIONS = setOf("US", "AS", "GU", "MP", "PR", "VI", "LR", "MM", "GB")
}
