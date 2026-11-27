package com.endurain.endurain.activity

import android.app.Application
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [35], application = Application::class)
class ActiveActivityStoreTest {
    private lateinit var store: ActiveActivityStore

    private fun session(status: String) = ActiveActivitySessionData(
        localSessionId = "s1",
        activityType = "run",
        status = status,
        startedAt = "2026-07-15T10:00:00.000Z",
    )

    @Before
    fun setUp() {
        store = ActiveActivityStore.of(RuntimeEnvironment.getApplication())
        store.clear()
    }

    @After
    fun tearDown() {
        store.clear()
    }

    @Test
    fun loadSessionReturnsTheLastSavedSession() {
        store.saveSession(session(ActiveActivitySessionData.STATUS_RECORDING))
        val paused = session(ActiveActivitySessionData.STATUS_PAUSED)
        store.saveSession(paused)

        assertEquals(paused, store.loadSession())
    }

    @Test
    fun loadSessionIsNullAfterClear() {
        store.saveSession(session(ActiveActivitySessionData.STATUS_RECORDING))
        store.loadSession()

        store.clear()

        assertNull(store.loadSession())
    }

    @Test
    fun loadSessionIgnoresACopyWhoseFileWasRemovedBehindTheStore() {
        store.saveSession(session(ActiveActivitySessionData.STATUS_RECORDING))
        store.loadSession()

        val file = java.io.File(
            RuntimeEnvironment.getApplication().filesDir,
            "${ActiveActivityStore.ROOT_DIR}/${ActiveActivityStore.ACTIVE_DIR}/" +
                ActiveActivityStore.SESSION_FILE,
        )
        file.delete()

        assertNull(store.loadSession())
    }
}
