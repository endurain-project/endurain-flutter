package com.endurain.endurain.wear

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat
import androidx.core.content.ContextCompat
import androidx.wear.ongoing.OngoingActivity
import androidx.wear.ongoing.Status

/**
 * Foreground service that keeps the process alive while a workout records (or
 * counts down to its start), and shows it as an ongoing activity on the watch
 * face.
 */
class ExerciseService : Service() {
    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent == null && !(application as EndurainWearApplication).recorder.hasSavedRecording()) {
            // Restarted after the process died, with no workout on disk: it was
            // a countdown, which only lived in memory. Nothing is recording, so
            // show nothing instead of "Recording a workout".
            stopSelf()
            return START_NOT_STICKY
        }
        val title =
            getString(
                if (intent?.getBooleanExtra(EXTRA_COUNTING_DOWN, false) == true) {
                    R.string.notification_starting
                } else {
                    R.string.notification_recording
                },
            )
        val openApp =
            PendingIntent.getActivity(
                this,
                0,
                Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )
        val notification =
            NotificationCompat.Builder(this, CHANNEL_ID)
                .setSmallIcon(R.drawable.ic_workout)
                .setContentTitle(title)
                .setCategory(NotificationCompat.CATEGORY_WORKOUT)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setOngoing(true)
                .setContentIntent(openApp)
        OngoingActivity.Builder(applicationContext, NOTIFICATION_ID, notification)
            .setStaticIcon(R.drawable.ic_workout)
            .setTouchIntent(openApp)
            .setStatus(Status.Builder().addTemplate(title).build())
            .build()
            .apply(applicationContext)

        try {
            ServiceCompat.startForeground(this, NOTIFICATION_ID, notification.build(), foregroundTypes())
        } catch (error: Exception) {
            // Starting from the background (for example a relaunch by Play
            // Services) can be refused; Health Services keeps recording.
            Log.w(TAG, "Could not start the workout foreground service", error)
            stopSelf()
        }
        return START_STICKY
    }

    private fun foregroundTypes(): Int {
        var types = 0
        if (granted(Manifest.permission.ACCESS_FINE_LOCATION)) {
            types = types or ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION
        }
        val heartRatePermission = ExercisePermissions.heartRate(Build.VERSION.SDK_INT)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE &&
            (granted(heartRatePermission) || granted(Manifest.permission.ACTIVITY_RECOGNITION))
        ) {
            types = types or ServiceInfo.FOREGROUND_SERVICE_TYPE_HEALTH
        }
        return types
    }

    private fun granted(permission: String): Boolean =
        ContextCompat.checkSelfPermission(this, permission) == PackageManager.PERMISSION_GRANTED

    companion object {
        private const val TAG = "EndurainWear"
        private const val CHANNEL_ID = "workout"
        private const val NOTIFICATION_ID = 1
        private const val EXTRA_COUNTING_DOWN = "countingDown"

        /** Creates the notification channel; once per process, from the Application. */
        fun createNotificationChannel(context: Context) {
            context.getSystemService(NotificationManager::class.java).createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID,
                    context.getString(R.string.notification_channel),
                    NotificationManager.IMPORTANCE_LOW,
                ),
            )
        }

        fun start(
            context: Context,
            countingDown: Boolean = false,
        ) {
            val intent = Intent(context, ExerciseService::class.java).putExtra(EXTRA_COUNTING_DOWN, countingDown)
            ContextCompat.startForegroundService(context, intent)
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, ExerciseService::class.java))
        }
    }
}
