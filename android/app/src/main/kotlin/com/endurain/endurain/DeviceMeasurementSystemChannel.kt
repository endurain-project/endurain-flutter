package com.endurain.endurain

import android.icu.util.LocaleData
import android.icu.util.ULocale
import android.os.Build
import androidx.annotation.VisibleForTesting
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

/** Resolves Android's locale measurement system for the Flutter client. */
class DeviceMeasurementSystemChannel(
    private val measurementSystemProvider: () -> String? = ::readMeasurementSystem,
) : MethodChannel.MethodCallHandler {
    private var channel: MethodChannel? = null

    fun register(messenger: BinaryMessenger) {
        channel = MethodChannel(messenger, CHANNEL_NAME).also {
            it.setMethodCallHandler(this)
        }
    }

    fun unregister() {
        channel?.setMethodCallHandler(null)
        channel = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != METHOD_GET_MEASUREMENT_SYSTEM) {
            result.notImplemented()
            return
        }

        val measurementSystem = try {
            measurementSystemProvider()
        } catch (_: RuntimeException) {
            null
        }
        result.success(measurementSystem)
    }

    internal companion object {
        private const val CHANNEL_NAME = "endurain/device_settings"
        private const val METHOD_GET_MEASUREMENT_SYSTEM = "getMeasurementSystem"

        private fun readMeasurementSystem(): String? {
            // LocaleData.getMeasurementSystem is API 28+; calling it on
            // Android 8.x throws NoSuchMethodError, which is not caught as a
            // RuntimeException.
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) {
                return measurementSystemForCountry(Locale.getDefault().country)
            }
            val locale = ULocale.forLocale(Locale.getDefault())
            return when (LocaleData.getMeasurementSystem(locale)) {
                LocaleData.MeasurementSystem.SI -> "metric"
                LocaleData.MeasurementSystem.UK,
                LocaleData.MeasurementSystem.US,
                -> "imperial"
                else -> null
            }
        }

        /**
         * The ICU measurement system by region for Android 8.x: the US
         * system in the United States, Liberia and Myanmar, the UK system in
         * the United Kingdom, metric elsewhere. Null without a region.
         */
        @VisibleForTesting
        fun measurementSystemForCountry(country: String): String? =
            when (country.uppercase(Locale.ROOT)) {
                "" -> null
                "US", "LR", "MM", "GB" -> "imperial"
                else -> "metric"
            }
    }
}