package com.endurain.endurain.activity

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class GattReconnectControllerTest {
    private class FakeScheduler : ReconnectScheduler {
        val delays = mutableListOf<Long>()
        var pending: Runnable? = null

        override fun schedule(delayMillis: Long, task: Runnable): () -> Unit {
            delays += delayMillis
            pending = task
            return { pending = null }
        }

        fun fire() {
            val task = pending ?: return
            pending = null
            task.run()
        }
    }

    private fun controller(
        scheduler: FakeScheduler,
        onReconnect: () -> Unit = {},
        maxAttempts: Int = 4,
    ) = GattReconnectController(
        scheduler,
        onReconnect,
        initialDelayMillis = 1_000,
        maxDelayMillis = 5_000,
        maxAttempts = maxAttempts,
    )

    @Test
    fun backsOffExponentiallyUpToTheCap() {
        val scheduler = FakeScheduler()
        val controller = controller(scheduler, maxAttempts = 5)
        repeat(5) {
            assertTrue(controller.onFailure())
            scheduler.fire()
        }
        assertEquals(listOf(1_000L, 2_000L, 4_000L, 5_000L, 5_000L), scheduler.delays)
    }

    @Test
    fun givesUpAfterTheAttemptBudget() {
        val scheduler = FakeScheduler()
        var reconnects = 0
        val controller = controller(scheduler, { reconnects++ }, maxAttempts = 2)
        assertTrue(controller.onFailure())
        scheduler.fire()
        assertTrue(controller.onFailure())
        scheduler.fire()
        assertFalse(controller.onFailure())
        assertEquals(2, reconnects)
    }

    @Test
    fun ignoresAFailureWhileOneReconnectIsPending() {
        val scheduler = FakeScheduler()
        val controller = controller(scheduler)
        assertTrue(controller.onFailure())
        assertFalse(controller.onFailure())
        assertEquals(1, scheduler.delays.size)
    }

    @Test
    fun resetRestoresTheBudgetAndTheInitialDelay() {
        val scheduler = FakeScheduler()
        val controller = controller(scheduler, maxAttempts = 1)
        assertTrue(controller.onFailure())
        scheduler.fire()
        assertFalse(controller.onFailure())
        controller.reset()
        assertTrue(controller.onFailure())
        assertEquals(listOf(1_000L, 1_000L), scheduler.delays)
    }

    @Test
    fun cancelDropsThePendingReconnect() {
        val scheduler = FakeScheduler()
        var reconnects = 0
        val controller = controller(scheduler, { reconnects++ })
        controller.onFailure()
        controller.cancel()
        scheduler.fire()
        assertEquals(0, reconnects)
        assertTrue(controller.onFailure())
    }
}
