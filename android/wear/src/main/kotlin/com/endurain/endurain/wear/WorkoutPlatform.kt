package com.endurain.endurain.wear

import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import androidx.core.content.ContextCompat

/** What the recorder needs from the Android framework, so its state machine runs on the JVM. */
interface WorkoutPlatform {
    val sdkInt: Int

    fun isGranted(permission: String): Boolean

    /** Puts [ExerciseService] in the foreground (or only switches its notification). */
    fun startService(countingDown: Boolean = false)

    fun stopService()

    fun vibrateTick()

    fun vibrateStart()

    fun nowMillis(): Long
}

class AndroidWorkoutPlatform(context: Context) : WorkoutPlatform {
    private val appContext = context.applicationContext

    private val vibrator: Vibrator? by lazy {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            appContext.getSystemService(VibratorManager::class.java)?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            appContext.getSystemService(Vibrator::class.java)
        }
    }

    override val sdkInt: Int = Build.VERSION.SDK_INT

    override fun isGranted(permission: String): Boolean =
        ContextCompat.checkSelfPermission(appContext, permission) == PackageManager.PERMISSION_GRANTED

    override fun startService(countingDown: Boolean) = ExerciseService.start(appContext, countingDown)

    override fun stopService() = ExerciseService.stop(appContext)

    override fun vibrateTick() = vibrate(VibrationEffect.createPredefined(VibrationEffect.EFFECT_TICK))

    override fun vibrateStart() =
        vibrate(VibrationEffect.createOneShot(START_VIBRATION_MILLIS, VibrationEffect.DEFAULT_AMPLITUDE))

    override fun nowMillis(): Long = System.currentTimeMillis()

    private fun vibrate(effect: VibrationEffect) {
        runCatching { vibrator?.vibrate(effect) }
    }

    private companion object {
        const val START_VIBRATION_MILLIS = 400L
    }
}
