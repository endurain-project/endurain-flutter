package com.endurain.endurain.activity

import android.app.Application
import android.os.Looper
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [35], application = Application::class)
class RecorderWorkerTest {
    @After
    fun tearDown() {
        RecorderWorker.looperOverride = null
    }

    @Test
    fun runsPostedWorkOnADedicatedThreadNotTheMainThread() {
        val worker = RecorderWorker.create()
        try {
            val latch = CountDownLatch(1)
            var ranOn: Thread? = null

            worker.run {
                ranOn = Thread.currentThread()
                latch.countDown()
            }

            assertTrue(latch.await(5, TimeUnit.SECONDS))
            assertNotEquals(Looper.getMainLooper().thread, ranOn)
            assertEquals(worker.looper.thread, ranOn)
            assertEquals("endurain-recorder", ranOn?.name)
        } finally {
            worker.quitWhenIdle()
        }
    }

    @Test
    fun runsInlineWhenAlreadyOnTheWorkerSoOrderIsKept() {
        val worker = RecorderWorker.create()
        try {
            val done = CountDownLatch(1)
            val order = mutableListOf<String>()

            worker.run {
                order.add("outer-start")
                worker.run { order.add("nested") }
                order.add("outer-end")
                done.countDown()
            }

            assertTrue(done.await(5, TimeUnit.SECONDS))
            assertEquals(listOf("outer-start", "nested", "outer-end"), order)
        } finally {
            worker.quitWhenIdle()
        }
    }

    @Test
    fun quittingEndsTheThreadAfterQueuedWork() {
        val worker = RecorderWorker.create()
        val thread = worker.looper.thread
        val ran = CountDownLatch(1)
        worker.run { ran.countDown() }

        worker.quitWhenIdle()

        assertTrue(ran.await(5, TimeUnit.SECONDS))
        thread.join(5_000)
        assertFalse(thread.isAlive)
    }

    @Test
    fun aTestOverrideRunsEverythingInlineOnThatLooper() {
        RecorderWorker.looperOverride = Looper.getMainLooper()
        val worker = RecorderWorker.create()
        var ran = false

        worker.run { ran = true }
        worker.quitWhenIdle()

        assertSame(Looper.getMainLooper(), worker.looper)
        assertTrue(ran)
        assertTrue(Looper.getMainLooper().thread.isAlive)
    }
}
