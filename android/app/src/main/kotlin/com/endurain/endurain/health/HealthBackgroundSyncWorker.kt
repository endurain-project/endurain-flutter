package com.endurain.endurain.health

import android.content.Context
import androidx.work.Constraints
import androidx.work.CoroutineWorker
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequest
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import java.time.Duration

/**
 * Periodic WorkManager work that imports new Health Connect workouts while
 * the app is not in the foreground, under `READ_HEALTH_DATA_IN_BACKGROUND`.
 *
 * The import itself is the Dart automatic-import pass, run by
 * [HealthBackgroundSyncRunner]; Dart schedules and cancels this work through
 * [HealthBackgroundSyncChannel].
 */
class HealthBackgroundSyncWorker(
    context: Context,
    params: WorkerParameters,
) : CoroutineWorker(context, params) {
    override suspend fun doWork(): Result {
        HealthBackgroundSyncRunner.run(applicationContext)
        // The Dart pass records its own failures and keeps what failed for the
        // next pass, so the next period retries it; a WorkManager retry with
        // backoff would only add runs.
        return Result.success()
    }

    companion object {
        internal const val WORK_NAME = "endurain.health_background_sync"

        /**
         * Hourly: new workouts show up within the hour without spending the
         * battery or the Health Connect read quota on frequent empty passes.
         */
        internal val REPEAT_INTERVAL: Duration = Duration.ofHours(1)

        /** Schedules the work, or cancels it. Idempotent. */
        fun schedule(context: Context, scheduled: Boolean) {
            val workManager = WorkManager.getInstance(context)
            if (scheduled) {
                // UPDATE keeps the period already running instead of starting a
                // new one each time the app resumes.
                workManager.enqueueUniquePeriodicWork(
                    WORK_NAME,
                    ExistingPeriodicWorkPolicy.UPDATE,
                    request(),
                )
            } else {
                workManager.cancelUniqueWork(WORK_NAME)
            }
        }

        internal fun request(): PeriodicWorkRequest =
            PeriodicWorkRequestBuilder<HealthBackgroundSyncWorker>(REPEAT_INTERVAL)
                .setConstraints(Constraints.Builder().setRequiresBatteryNotLow(true).build())
                .build()
    }
}
