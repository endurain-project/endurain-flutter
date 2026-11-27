package com.endurain.endurain.activity

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import com.endurain.endurain.MainActivity
import com.endurain.endurain.R

/**
 * Notifications of the recording foreground service: the ongoing recording
 * notification plus the alert posted when a recording was interrupted while no
 * Flutter engine was around to report it.
 */
internal class RecorderNotifications(private val context: Context) {
    fun defaultTitle(): String = context.getString(R.string.activity_recording_notification_title)

    fun defaultText(): String = context.getString(R.string.activity_recording_notification_text)

    fun startingText(): String =
        context.getString(R.string.activity_recording_notification_starting)

    fun build(title: String, text: String): Notification {
        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        val contentIntent = launchIntent?.let {
            PendingIntent.getActivity(
                context,
                0,
                it,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }
        return NotificationCompat.Builder(context, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(text)
            .setSmallIcon(R.drawable.ic_stat_recording)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            .apply { contentIntent?.let { setContentIntent(it) } }
            .build()
    }

    fun createChannel() {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (manager.getNotificationChannel(CHANNEL_ID) != null) {
            return
        }
        val channel = NotificationChannel(
            CHANNEL_ID,
            context.getString(R.string.activity_recording_channel_name),
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = context.getString(R.string.activity_recording_channel_description)
            setShowBadge(false)
        }
        manager.createNotificationChannel(channel)
    }

    /**
     * Tells the user a recording stopped while the app was in the background.
     * Tapping it opens the app, whose recovery offers to resume.
     */
    fun postInterrupted() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            return
        }
        val manager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return
        try {
            createAlertChannel(manager)
            val openApp = PendingIntent.getActivity(
                context,
                0,
                Intent(context, MainActivity::class.java)
                    .setAction(Intent.ACTION_MAIN)
                    .addCategory(Intent.CATEGORY_LAUNCHER)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            val notification = NotificationCompat.Builder(context, ALERT_CHANNEL_ID)
                .setContentTitle(context.getString(R.string.activity_recording_interrupted_title))
                .setContentText(context.getString(R.string.activity_recording_interrupted_text))
                .setSmallIcon(R.drawable.ic_stat_recording)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setCategory(NotificationCompat.CATEGORY_STATUS)
                .setAutoCancel(true)
                .setContentIntent(openApp)
                .build()
            manager.notify(INTERRUPTED_NOTIFICATION_ID, notification)
        } catch (_: RuntimeException) {
            // Best effort: the failed session is persisted either way.
        }
    }

    fun cancelInterrupted() {
        val manager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return
        try {
            manager.cancel(INTERRUPTED_NOTIFICATION_ID)
        } catch (_: RuntimeException) {
            // Best effort.
        }
    }

    private fun createAlertChannel(manager: NotificationManager) {
        if (manager.getNotificationChannel(ALERT_CHANNEL_ID) != null) {
            return
        }
        val channel = NotificationChannel(
            ALERT_CHANNEL_ID,
            context.getString(R.string.activity_recording_alert_channel_name),
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = context.getString(R.string.activity_recording_alert_channel_description)
        }
        manager.createNotificationChannel(channel)
    }

    companion object {
        private const val CHANNEL_ID = "activity_recording"
        const val NOTIFICATION_ID = 4711
        private const val ALERT_CHANNEL_ID = "activity_recording_alerts"
        private const val INTERRUPTED_NOTIFICATION_ID = 4712
    }
}
