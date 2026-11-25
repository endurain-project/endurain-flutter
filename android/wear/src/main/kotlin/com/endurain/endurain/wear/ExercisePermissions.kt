package com.endurain.endurain.wear

import android.Manifest

/** What a workout can measure; mapped to Health Services data types by [WorkoutRecorder]. */
enum class WorkoutMetric {
    HEART_RATE,
    LOCATION,
    DISTANCE,
}

/**
 * The runtime permission each [WorkoutMetric] needs, kept free of Android
 * types other than the permission names so it is testable on the JVM.
 *
 * Health Services rejects an exercise that requests a data type whose
 * permission is missing, so the start flow, which only insists on location,
 * must leave out what the user declined.
 */
object ExercisePermissions {
    /** API 36 replaced BODY_SENSORS with the Health Connect heart-rate permission. */
    fun heartRate(sdkInt: Int): String =
        if (sdkInt >= 36) "android.permission.health.READ_HEART_RATE" else Manifest.permission.BODY_SENSORS

    fun required(
        metric: WorkoutMetric,
        sdkInt: Int,
    ): String =
        when (metric) {
            WorkoutMetric.HEART_RATE -> heartRate(sdkInt)
            WorkoutMetric.LOCATION -> Manifest.permission.ACCESS_FINE_LOCATION
            WorkoutMetric.DISTANCE -> Manifest.permission.ACTIVITY_RECOGNITION
        }

    /** The metrics whose permission [isGranted] reports as granted. */
    fun permitted(
        sdkInt: Int,
        isGranted: (String) -> Boolean,
    ): Set<WorkoutMetric> = WorkoutMetric.entries.filter { isGranted(required(it, sdkInt)) }.toSet()
}
