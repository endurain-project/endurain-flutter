package com.endurain.endurain.activity

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Bundle
import android.os.Looper
import androidx.core.content.ContextCompat

/** Forwards fixes and provider toggles; the status callback is a legacy no-op. */
private class ForwardingLocationListener(
    private val onFix: (Location) -> Unit,
    private val onProviderToggled: () -> Unit,
) : LocationListener {
    override fun onLocationChanged(location: Location) = onFix(location)

    override fun onProviderEnabled(provider: String) = onProviderToggled()

    override fun onProviderDisabled(provider: String) = onProviderToggled()

    @Deprecated("Deprecated in Android API 29")
    override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}
}

/**
 * Owns the platform location subscriptions of the recorder: the start-countdown
 * warm-up (fixes dropped) and the active collection. It knows nothing about
 * sessions; the service decides what a failed [startActive] means.
 */
internal class RecorderLocationCollector(
    private val context: Context,
    private val manager: LocationManager?,
) {
    /** Why a subscription could not start. */
    enum class Failure { PERMISSION_LOST, LOCATION_UNAVAILABLE }

    private var warmUpListener: LocationListener? = null
    private var activeListener: LocationListener? = null

    fun hasFine(): Boolean = hasPermission(Manifest.permission.ACCESS_FINE_LOCATION)

    fun hasCoarse(): Boolean = hasPermission(Manifest.permission.ACCESS_COARSE_LOCATION)

    /** The reason no subscription is possible right now, or `null` when one is. */
    fun unavailability(): Failure? {
        val manager = manager ?: return Failure.LOCATION_UNAVAILABLE
        val hasFine = hasFine()
        val hasCoarse = hasCoarse()
        if (!hasFine && !hasCoarse) {
            return Failure.PERMISSION_LOST
        }
        return if (selectProviders(manager, hasFine, hasCoarse).isEmpty()) {
            Failure.LOCATION_UNAVAILABLE
        } else {
            null
        }
    }

    /** Runs GPS during the countdown so the first recorded point is accurate. */
    fun startWarmUp() {
        val manager = manager ?: return
        // Dropped on purpose: nothing is recorded before the countdown ends.
        val listener = ForwardingLocationListener(onFix = {}, onProviderToggled = {})
        for (provider in selectProviders(manager, hasFine(), hasCoarse())) {
            try {
                manager.requestLocationUpdates(
                    provider,
                    MIN_UPDATE_INTERVAL_MS,
                    0f,
                    listener,
                    Looper.getMainLooper(),
                )
                warmUpListener = listener
            } catch (_: SecurityException) {
                // The foreground service alone still keeps the countdown alive.
            } catch (_: IllegalArgumentException) {
                // Provider disappeared between discovery and subscription.
            }
        }
    }

    fun stopWarmUp() {
        val listener = warmUpListener ?: return
        warmUpListener = null
        try {
            manager?.removeUpdates(listener)
        } catch (_: Exception) {
            // Best effort; nothing to recover here.
        }
    }

    /**
     * Subscribes to the preferred provider. Returns `null` on success, or why
     * no provider accepted the subscription.
     */
    fun startActive(
        minDistanceMeters: Float,
        onFix: (Location) -> Unit,
        onProviderToggled: () -> Unit,
    ): Failure? {
        val manager = manager ?: return Failure.LOCATION_UNAVAILABLE
        val listener = ForwardingLocationListener(onFix, onProviderToggled)
        var registered = false
        var permissionFailure = false
        for (provider in selectProviders(manager, hasFine(), hasCoarse())) {
            try {
                manager.requestLocationUpdates(
                    provider,
                    MIN_UPDATE_INTERVAL_MS,
                    minDistanceMeters,
                    listener,
                    Looper.getMainLooper(),
                )
                registered = true
            } catch (_: SecurityException) {
                permissionFailure = true
            } catch (_: IllegalArgumentException) {
                // Provider disappeared between discovery and subscription.
            }
        }
        if (!registered) {
            return if (permissionFailure) Failure.PERMISSION_LOST else Failure.LOCATION_UNAVAILABLE
        }
        activeListener = listener
        return null
    }

    fun stopActive() {
        val listener = activeListener ?: return
        activeListener = null
        try {
            manager?.removeUpdates(listener)
        } catch (_: Exception) {
            // Best effort; nothing to recover here.
        }
    }

    /**
     * Selects a single location provider, preferring GPS for its precision.
     *
     * The network provider is used only as a fallback when GPS is unavailable.
     * Subscribing to both simultaneously interleaves a precise GPS stream with
     * low-accuracy WiFi/cell triangulation, which surfaces as "ghost" points
     * hundreds of meters to kilometers off the real track (the network fixes
     * also lack altitude). Picking one provider avoids that artifact; the
     * accuracy gate in the service guards the remaining fallback case.
     */
    private fun selectProviders(
        manager: LocationManager,
        hasFine: Boolean,
        hasCoarse: Boolean,
    ): List<String> {
        if (hasFine && isProviderEnabled(manager, LocationManager.GPS_PROVIDER)) {
            return listOf(LocationManager.GPS_PROVIDER)
        }
        if ((hasFine || hasCoarse) &&
            isProviderEnabled(manager, LocationManager.NETWORK_PROVIDER)
        ) {
            return listOf(LocationManager.NETWORK_PROVIDER)
        }
        return emptyList()
    }

    private fun isProviderEnabled(manager: LocationManager, provider: String): Boolean {
        return try {
            manager.isProviderEnabled(provider)
        } catch (_: Exception) {
            false
        }
    }

    private fun hasPermission(permission: String): Boolean =
        ContextCompat.checkSelfPermission(context, permission) ==
            PackageManager.PERMISSION_GRANTED

    private companion object {
        // Mirrors the Dart location policy.
        const val MIN_UPDATE_INTERVAL_MS = 1000L
    }
}
