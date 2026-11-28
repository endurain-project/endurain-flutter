package com.endurain.endurain.health

import android.app.Application
import androidx.work.Configuration
import androidx.work.WorkInfo
import androidx.work.WorkManager
import androidx.work.testing.SynchronousExecutor
import androidx.work.testing.WorkManagerTestInitHelper
import java.time.Duration
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [35], application = Application::class)
class HealthBackgroundSyncWorkerTest {
    private val context = RuntimeEnvironment.getApplication()

    @Before
    fun setUp() {
        WorkManagerTestInitHelper.initializeTestWorkManager(
            context,
            Configuration.Builder().setExecutor(SynchronousExecutor()).build(),
        )
    }

    private fun work(): List<WorkInfo> =
        WorkManager.getInstance(context)
            .getWorkInfosForUniqueWork(HealthBackgroundSyncWorker.WORK_NAME)
            .get()

    @Test
    fun schedulingKeepsOneHourlyWorkThatSparesALowBattery() {
        HealthBackgroundSyncWorker.schedule(context, true)
        HealthBackgroundSyncWorker.schedule(context, true)

        val info = work().single()
        assertEquals(WorkInfo.State.ENQUEUED, info.state)
        assertEquals(
            Duration.ofHours(1).toMillis(),
            info.periodicityInfo?.repeatIntervalMillis,
        )
        assertTrue(info.constraints.requiresBatteryNotLow())
    }

    @Test
    fun cancellingStopsTheWork() {
        HealthBackgroundSyncWorker.schedule(context, true)

        HealthBackgroundSyncWorker.schedule(context, false)

        assertEquals(WorkInfo.State.CANCELLED, work().single().state)
    }
}
