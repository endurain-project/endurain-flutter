package com.endurain.endurain

import android.os.Bundle
import android.widget.ScrollView
import android.widget.TextView
import androidx.activity.ComponentActivity
import androidx.activity.enableEdgeToEdge
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat

/** Displays the Health Connect privacy rationale entry point. */
class HealthPermissionsRationaleActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
        val text = TextView(this).apply {
            text = """
                Endurain health data

                Endurain reads workouts, routes, heart rate, distance,
                calories, and steps only to import selected activities.

                Selected route data is stored on this device and uploaded only
                to the Endurain server you connect.
            """.trimIndent()
        }
        val content = ScrollView(this).apply { addView(text) }
        // Edge-to-edge draws behind the system bars, so keep the text clear of
        // them (and of a display cutout) on top of the base padding.
        ViewCompat.setOnApplyWindowInsetsListener(content) { view, insets ->
            val bars = insets.getInsets(
                WindowInsetsCompat.Type.systemBars() or WindowInsetsCompat.Type.displayCutout(),
            )
            view.setPadding(
                bars.left + PADDING,
                bars.top + PADDING,
                bars.right + PADDING,
                bars.bottom + PADDING,
            )
            WindowInsetsCompat.CONSUMED
        }
        setContentView(content)
    }

    private companion object {
        private const val PADDING = 48
    }
}
