package com.endurain.endurain.wear

import android.content.Context
import kotlin.math.ceil

/** The start countdown's choices and arithmetic, kept free of Android types. */
object StartCountdown {
    /** Countdown choices in seconds; 0 starts right away. */
    val OPTIONS = listOf(0, 3, 5, 10)

    /** The last seconds of the countdown that vibrate. */
    const val CUE_SECONDS = 3

    /** The choice after [current], wrapping around; unknown values restart at the first. */
    fun next(current: Int): Int {
        val index = OPTIONS.indexOf(current)
        return OPTIONS[(index + 1) % OPTIONS.size]
    }

    /** [stored] when it is a valid choice, otherwise off. */
    fun sanitize(stored: Int): Int = if (stored in OPTIONS) stored else 0

    /** Whole seconds left until [endsAtMillis], rounded up so "1" shows until the end. */
    fun remainingSeconds(
        endsAtMillis: Long,
        nowMillis: Long,
    ): Int {
        val leftMillis = endsAtMillis - nowMillis
        if (leftMillis <= 0) return 0
        return ceil(leftMillis / 1000.0).toInt()
    }
}

/** The countdown length chosen on the watch, kept in shared preferences. */
class StartCountdownSettings(context: Context) {
    private val preferences =
        context.applicationContext.getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE)

    var seconds: Int
        get() = StartCountdown.sanitize(preferences.getInt(KEY_SECONDS, 0))
        set(value) {
            preferences.edit().putInt(KEY_SECONDS, StartCountdown.sanitize(value)).apply()
        }

    private companion object {
        const val PREFERENCES_NAME = "endurain_wear_settings"
        const val KEY_SECONDS = "start_countdown_seconds"
    }
}
