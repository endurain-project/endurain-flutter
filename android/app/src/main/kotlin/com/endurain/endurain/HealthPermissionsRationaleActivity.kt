package com.endurain.endurain

import android.content.ActivityNotFoundException
import android.content.Intent
import android.os.Bundle
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import androidx.activity.ComponentActivity
import androidx.activity.enableEdgeToEdge
import androidx.core.net.toUri
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat

/** Displays the Health Connect privacy rationale entry point. */
class HealthPermissionsRationaleActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
        val text = TextView(this).apply {
            text = listOf(
                R.string.health_rationale_title,
                R.string.health_rationale_usage,
                R.string.health_rationale_storage,
            ).joinToString(separator = "\n\n") { getString(it) }
        }
        val policyLink = TextView(this).apply {
            setText(R.string.health_rationale_privacy_policy)
            setPadding(0, PADDING / 2, 0, 0)
            setTextColor(getColor(android.R.color.holo_blue_dark))
            setOnClickListener { openPrivacyPolicy() }
        }
        val column = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            addView(text)
            addView(policyLink)
        }
        val content = ScrollView(this).apply { addView(column) }
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

    private fun openPrivacyPolicy() {
        try {
            startActivity(Intent(Intent.ACTION_VIEW, PRIVACY_POLICY_URL.toUri()))
        } catch (_: ActivityNotFoundException) {
            // No browser installed; nothing to open the link with.
        }
    }

    private companion object {
        private const val PADDING = 48
        private const val PRIVACY_POLICY_URL =
            "https://docs.endurain.com/privacy/mobile-app-privacy-policy/"
    }
}
