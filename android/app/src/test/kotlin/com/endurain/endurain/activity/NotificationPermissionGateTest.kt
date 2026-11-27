package com.endurain.endurain.activity

import android.os.Build
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class NotificationPermissionGateTest {
    private var granted = false
    private var launches = 0
    private var launchFails = false

    private fun gate(sdkInt: Int = Build.VERSION_CODES.TIRAMISU) = NotificationPermissionGate(
        sdkInt = sdkInt,
        isGranted = { granted },
        launch = {
            launches++
            if (launchFails) throw IllegalStateException("no activity")
        },
    )

    @Test
    fun belowAndroid13NothingIsAskedAndItCountsAsGranted() {
        val answers = mutableListOf<Boolean>()

        gate(sdkInt = Build.VERSION_CODES.S_V2).request { answers.add(it) }

        assertEquals(listOf(true), answers)
        assertEquals(0, launches)
    }

    @Test
    fun anAlreadyGrantedPermissionIsNotAskedAgain() {
        granted = true
        val answers = mutableListOf<Boolean>()

        gate().request { answers.add(it) }

        assertEquals(listOf(true), answers)
        assertEquals(0, launches)
    }

    @Test
    fun aDeniedPermissionIsAskedThroughTheSystemAgain() {
        // The system decides whether a dialog still shows; the gate always defers to it.
        val gate = gate()
        val answers = mutableListOf<Boolean>()
        gate.request { answers.add(it) }
        gate.onResult(false)

        gate.request { answers.add(it) }

        assertEquals(listOf(false), answers)
        assertEquals(2, launches)
    }

    @Test
    fun theDialogAnswerReachesEveryWaitingCallerFromOneLaunch() {
        val gate = gate()
        val answers = mutableListOf<Boolean>()

        gate.request { answers.add(it) }
        gate.request { answers.add(it) }
        assertEquals(1, launches)
        assertTrue(answers.isEmpty())

        gate.onResult(true)

        assertEquals(listOf(true, true), answers)
        // Asking again later starts a new prompt.
        gate.request { answers.add(it) }
        assertEquals(2, launches)
    }

    @Test
    fun aLaunchThatCannotShowAnswersNo() {
        launchFails = true
        val answers = mutableListOf<Boolean>()

        gate().request { answers.add(it) }

        assertEquals(listOf(false), answers)
    }

    @Test
    fun cancellingAnswersNoToWaitingCallers() {
        val gate = gate()
        val answers = mutableListOf<Boolean>()
        gate.request { answers.add(it) }

        gate.cancelPending()

        assertEquals(listOf(false), answers)
    }
}
