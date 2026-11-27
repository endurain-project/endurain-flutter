package com.endurain.endurain.wear

import android.util.Log
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.delay

/**
 * Whether Health Services runs our exercise, or null when it could not be
 * asked after retrying with the [backoffMillis] waits.
 */
internal suspend fun ExerciseGateway.readOwnership(backoffMillis: List<Long>): Boolean? {
    var attempt = 0
    while (true) {
        try {
            return ownsRunningExercise()
        } catch (error: CancellationException) {
            throw error
        } catch (error: Exception) {
            Log.w(TAG, "Could not read the current exercise", error)
        }
        if (attempt >= backoffMillis.size) return null
        delay(backoffMillis[attempt++])
    }
}

/** Whether another app records a workout; when Health Services cannot tell, start and let it decide. */
internal suspend fun ExerciseGateway.otherAppHasExerciseOrFalse(): Boolean =
    try {
        otherAppHasExercise()
    } catch (error: CancellationException) {
        throw error
    } catch (error: Exception) {
        Log.w(TAG, "Could not check for another workout", error)
        false
    }
