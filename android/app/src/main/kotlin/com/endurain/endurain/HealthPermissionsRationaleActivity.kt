package com.endurain.endurain

import android.app.Activity
import android.os.Bundle
import android.widget.TextView

/** Displays the Health Connect privacy rationale entry point. */
class HealthPermissionsRationaleActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(TextView(this).apply {
            text = """
                Endurain health data

                Endurain reads workouts, routes, heart rate, distance,
                calories, and steps only to import selected activities.

                Selected route data is stored on this device and uploaded only
                to the Endurain server you connect.
            """.trimIndent()
            setPadding(48, 48, 48, 48)
        })
    }
}