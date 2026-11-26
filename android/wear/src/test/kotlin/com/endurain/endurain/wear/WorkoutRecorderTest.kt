package com.endurain.endurain.wear

import com.endurain.endurain.watchlink.WatchActivityType
import com.endurain.endurain.watchlink.WatchRecordedPoint
import com.endurain.endurain.watchlink.WatchRecording
import com.endurain.endurain.watchlink.WatchRecordingStore
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import java.io.File
import java.io.IOException
import java.nio.file.Files

private const val BASE_TIME = 1_800_000_000_000L

private class FakeGateway : ExerciseGateway {
    var supported: Set<WorkoutMetric>? = WorkoutMetric.entries.toSet()
    val ownership = ArrayDeque<Result<Boolean>>()
    var ownershipCalls = 0
    var prepared = 0
    var started = 0
    var paused = 0
    var ended = 0
    var startFailure: Exception? = null
    var endFailure: Exception? = null
    var registered: ExerciseListener? = null

    override suspend fun supportedMetrics(type: WatchActivityType) = supported

    override suspend fun prepare(type: WatchActivityType, metrics: Set<WorkoutMetric>) {
        prepared++
    }

    override suspend fun start(type: WatchActivityType, metrics: Set<WorkoutMetric>) {
        startFailure?.let { throw it }
        started++
    }

    override suspend fun pause() {
        paused++
    }

    override suspend fun resume() {}

    override suspend fun end() {
        ended++
        endFailure?.let { throw it }
        registered?.onUpdate(ExerciseSnapshot(GatewayExerciseState.ENDED))
    }

    override suspend fun ownsRunningExercise(): Boolean {
        ownershipCalls++
        return ownership.removeFirst().getOrThrow()
    }

    override fun setListener(listener: ExerciseListener) {
        registered = listener
    }

    override suspend fun clearListener() {
        registered = null
    }
}

private class FakePlatform(private val clock: () -> Long) : WorkoutPlatform {
    override val sdkInt = 34
    var services = 0
    var serviceStops = 0
    var ticks = 0
    var startVibrations = 0

    override fun isGranted(permission: String) = true

    override fun startService(countingDown: Boolean) {
        services++
    }

    override fun stopService() {
        serviceStops++
    }

    override fun vibrateTick() {
        ticks++
    }

    override fun vibrateStart() {
        startVibrations++
    }

    override fun nowMillis() = clock()
}

private class FakeCountdownSetting(override var seconds: Int = 0) : CountdownSetting

@OptIn(ExperimentalCoroutinesApi::class)
class WorkoutRecorderTest {
    private lateinit var directory: File
    private lateinit var store: WatchRecordingStore
    private val gateway = FakeGateway()
    private val handoffs = mutableListOf<String>()
    private val setting = FakeCountdownSetting()

    @Before
    fun setUp() {
        directory = File(Files.createTempDirectory("recorder").toFile(), "recording")
        store = WatchRecordingStore(directory)
    }

    @After
    fun tearDown() {
        directory.parentFile?.deleteRecursively()
    }

    private fun TestScope.recorder(
        scope: CoroutineScope,
        platform: FakePlatform = FakePlatform { BASE_TIME + testScheduler.currentTime },
        sink: HandoffSink = HandoffSink { _, sessionId -> handoffs += sessionId },
    ) = WorkoutRecorder(
        gateway = gateway,
        store = store,
        handoffs = sink,
        platform = platform,
        countdownSetting = setting,
        scope = scope,
        restoreBackoffMillis = listOf(1_000, 2_000, 4_000),
    )

    private fun saveRecording(distance: Double? = null, withPoint: Boolean = true): WatchRecording {
        val saved =
            WatchRecording(
                sessionId = "saved",
                activityType = WatchActivityType.RUN,
                startedAtMillis = BASE_TIME - 600_000,
                lastDistanceMeters = distance,
            )
        store.begin(saved)
        if (withPoint) {
            store.append(
                listOf(WatchRecordedPoint(BASE_TIME - 300_000, 38.7, -9.1, segmentIndex = 0)),
            )
        }
        return saved
    }

    @Test
    fun startBeginsAnActiveRecording() =
        runTest {
            val platform = FakePlatform { BASE_TIME + testScheduler.currentTime }
            val recorder = recorder(this, platform)
            recorder.start(WatchActivityType.RIDE)
            runCurrent()

            assertEquals(WorkoutPhase.Active(paused = false), recorder.state.value.phase)
            assertEquals(1, gateway.started)
            assertEquals(1, platform.services)
            assertTrue(store.hasRecording())
        }

    @Test
    fun startFailsWhenTheActivityIsUnsupported() =
        runTest {
            gateway.supported = null
            val recorder = recorder(this)
            recorder.start(WatchActivityType.RUN)
            runCurrent()

            assertEquals(WorkoutPhase.Idle, recorder.state.value.phase)
            assertEquals(R.string.exercise_unsupported, recorder.state.value.errorMessage)
            assertEquals(0, gateway.started)
        }

    @Test
    fun aFailedStartClearsTheStoreAndShowsAnError() =
        runTest {
            gateway.startFailure = IllegalStateException("boom")
            val recorder = recorder(this)
            recorder.start(WatchActivityType.RUN)
            runCurrent()

            assertEquals(R.string.start_failed, recorder.state.value.errorMessage)
            assertEquals(false, store.hasRecording())
            // Nothing was prepared or started, so there is nothing to end.
            assertEquals(0, gateway.ended)
        }

    @Test
    fun pauseAndResumeFollowTheExerciseState() =
        runTest {
            val recorder = recorder(this)
            recorder.start(WatchActivityType.RUN)
            runCurrent()

            recorder.pause()
            runCurrent()
            assertEquals(1, gateway.paused)
            gateway.registered!!.onUpdate(ExerciseSnapshot(GatewayExerciseState.PAUSED))
            assertEquals(WorkoutPhase.Active(paused = true), recorder.state.value.phase)
            assertTrue(store.load()!!.first.isPaused)

            gateway.registered!!.onUpdate(ExerciseSnapshot(GatewayExerciseState.ACTIVE))
            assertEquals(WorkoutPhase.Active(paused = false), recorder.state.value.phase)
            assertEquals(1, store.load()!!.first.segmentIndex)
        }

    @Test
    fun endFinishesAndQueuesTheHandoff() =
        runTest {
            val platform = FakePlatform { BASE_TIME + testScheduler.currentTime }
            val recorder = recorder(this, platform)
            recorder.start(WatchActivityType.RUN)
            runCurrent()
            gateway.registered!!.onUpdate(
                ExerciseSnapshot(GatewayExerciseState.ACTIVE, distanceTotalMeters = 1234.0),
            )

            recorder.end()
            runCurrent()

            val phase = recorder.state.value.phase
            assertTrue(phase is WorkoutPhase.Finished)
            assertEquals(1234.0, (phase as WorkoutPhase.Finished).summary.distanceMeters)
            assertEquals(1, handoffs.size)
            assertEquals(false, store.hasRecording())
            assertEquals(1, platform.serviceStops)
        }

    @Test
    fun endFinishesWithWhatWasRecordedWhenTheExerciseIsGone() =
        runTest {
            gateway.endFailure = IllegalStateException("gone")
            val recorder = recorder(this)
            recorder.start(WatchActivityType.RUN)
            runCurrent()

            recorder.end()
            runCurrent()

            assertTrue(recorder.state.value.phase is WorkoutPhase.Finished)
            assertEquals(1, handoffs.size)
        }

    @Test
    fun countdownVibratesThenStarts() =
        runTest {
            setting.seconds = 3
            val platform = FakePlatform { BASE_TIME + testScheduler.currentTime }
            val recorder = recorder(this, platform)
            recorder.start(WatchActivityType.RUN)
            runCurrent()
            assertTrue(recorder.state.value.phase is WorkoutPhase.CountingDown)
            assertEquals(1, gateway.prepared)
            assertEquals(0, gateway.started)

            advanceTimeBy(3_500)
            runCurrent()

            assertEquals(WorkoutPhase.Active(paused = false), recorder.state.value.phase)
            assertEquals(3, platform.ticks)
            assertEquals(1, platform.startVibrations)
        }

    @Test
    fun cancellingTheCountdownEndsThePreparedExercise() =
        runTest {
            setting.seconds = 5
            val recorder = recorder(this)
            recorder.start(WatchActivityType.RUN)
            runCurrent()

            recorder.cancelCountdown()
            advanceUntilIdle()

            assertEquals(WorkoutPhase.Idle, recorder.state.value.phase)
            assertEquals(1, gateway.ended)
            assertEquals(0, gateway.started)
        }

    @Test
    fun restoreReattachesToAnOwnedExerciseAndKeepsTheDistance() =
        runTest {
            saveRecording(distance = 4200.0)
            gateway.ownership += Result.success(true)
            val recorder = recorder(this)

            recorder.restoreUnfinishedRecording()
            runCurrent()

            assertEquals(WorkoutPhase.Active(paused = false), recorder.state.value.phase)
            assertEquals(4200.0, recorder.state.value.distanceMeters)
            assertTrue(store.hasRecording())
            assertTrue(handoffs.isEmpty())
        }

    @Test
    fun restoreFinishesARecordingWhoseExerciseIsGone() =
        runTest {
            saveRecording()
            gateway.ownership += Result.success(false)
            val recorder = recorder(this)

            recorder.restoreUnfinishedRecording()
            runCurrent()

            assertEquals(WorkoutPhase.Idle, recorder.state.value.phase)
            assertEquals(listOf("saved"), handoffs)
            assertEquals(false, store.hasRecording())
        }

    @Test
    fun restoreRetriesATemporaryErrorBeforeDecidingOwnership() =
        runTest {
            saveRecording()
            gateway.ownership += Result.failure(IOException("busy"))
            gateway.ownership += Result.failure(IOException("busy"))
            gateway.ownership += Result.success(true)
            val recorder = recorder(this)

            recorder.restoreUnfinishedRecording()
            runCurrent()
            assertEquals(WorkoutPhase.Starting, recorder.state.value.phase)
            advanceUntilIdle()

            assertEquals(3, gateway.ownershipCalls)
            assertEquals(WorkoutPhase.Active(paused = false), recorder.state.value.phase)
            assertTrue(handoffs.isEmpty())
            assertTrue(store.hasRecording())
        }

    @Test
    fun restoreKeepsTheRecordingWhenOwnershipStaysUnknown() =
        runTest {
            saveRecording()
            repeat(4) { gateway.ownership += Result.failure(IOException("down")) }
            val recorder = recorder(this)

            recorder.restoreUnfinishedRecording()
            advanceUntilIdle()

            assertEquals(4, gateway.ownershipCalls)
            assertEquals(R.string.restore_failed, recorder.state.value.errorMessage)
            assertEquals(WorkoutPhase.Idle, recorder.state.value.phase)
            assertTrue(handoffs.isEmpty())
            assertNotNull(store.load())

            // A new workout must not overwrite the saved one while it is unrestored.
            val savedBefore = store.load()
            recorder.start(WatchActivityType.RUN)
            runCurrent()
            assertEquals(WorkoutPhase.Idle, recorder.state.value.phase)
            assertEquals(savedBefore, store.load())

            // Dismissing the message tries again, and a healthy answer re-attaches.
            gateway.ownership += Result.success(true)
            recorder.dismissError()
            advanceUntilIdle()

            assertEquals(WorkoutPhase.Active(paused = false), recorder.state.value.phase)
            assertNull(recorder.state.value.errorMessage)
        }

    @Test
    fun availabilityChangesReachTheState() =
        runTest {
            val recorder = recorder(this)
            recorder.start(WatchActivityType.RUN)
            runCurrent()

            gateway.registered!!.onAvailabilityChanged(WorkoutMetric.LOCATION, SensorStatus.ACQUIRING)
            gateway.registered!!.onAvailabilityChanged(WorkoutMetric.HEART_RATE, SensorStatus.UNAVAILABLE)

            assertEquals(SensorStatus.ACQUIRING, recorder.state.value.locationStatus)
            assertEquals(SensorStatus.UNAVAILABLE, recorder.state.value.heartRateStatus)
        }
}
