package com.endurain.endurain.wear

import org.junit.Assert.assertEquals
import org.junit.Test

class ExercisePermissionsTest {
    private val location = "android.permission.ACCESS_FINE_LOCATION"
    private val activityRecognition = "android.permission.ACTIVITY_RECOGNITION"
    private val bodySensors = "android.permission.BODY_SENSORS"
    private val readHeartRate = "android.permission.health.READ_HEART_RATE"

    @Test
    fun heartRateUsesTheHealthPermissionFromApi36() {
        assertEquals(bodySensors, ExercisePermissions.heartRate(35))
        assertEquals(readHeartRate, ExercisePermissions.heartRate(36))
    }

    @Test
    fun locationOnlyLeavesOutHeartRateAndDistance() {
        val permitted = ExercisePermissions.permitted(34) { it == location }
        assertEquals(setOf(WorkoutMetric.LOCATION), permitted)
    }

    @Test
    fun everyGrantedPermissionKeepsItsMetric() {
        val granted = setOf(location, activityRecognition, bodySensors)
        assertEquals(WorkoutMetric.entries.toSet(), ExercisePermissions.permitted(34, granted::contains))
    }

    @Test
    fun bodySensorsDoesNotCoverHeartRateFromApi36() {
        val granted = setOf(location, activityRecognition, bodySensors)
        assertEquals(
            setOf(WorkoutMetric.LOCATION, WorkoutMetric.DISTANCE),
            ExercisePermissions.permitted(36, granted::contains),
        )
        assertEquals(
            WorkoutMetric.entries.toSet(),
            ExercisePermissions.permitted(36, (granted + readHeartRate)::contains),
        )
    }
}
