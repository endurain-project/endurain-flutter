package com.endurain.endurain.wear

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.res.stringResource
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.wear.ambient.AmbientLifecycleObserver
import androidx.wear.compose.material3.AppScaffold
import androidx.wear.compose.material3.MaterialTheme
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.update

/**
 * Whether the watch is in ambient mode. [updateCount] changes with every
 * enter, exit and ambient update, so the ambient layout redraws once per
 * system update instead of on its own timers.
 */
data class AmbientState(
    val isAmbient: Boolean = false,
    val updateCount: Int = 0,
)

class MainActivity : ComponentActivity() {
    private val ambient = MutableStateFlow(AmbientState())

    private val ambientObserver =
        AmbientLifecycleObserver(
            this,
            object : AmbientLifecycleObserver.AmbientLifecycleCallback {
                override fun onEnterAmbient(ambientDetails: AmbientLifecycleObserver.AmbientDetails) {
                    ambient.update { AmbientState(isAmbient = true, updateCount = it.updateCount + 1) }
                }

                override fun onExitAmbient() {
                    ambient.update { AmbientState(isAmbient = false, updateCount = it.updateCount + 1) }
                }

                override fun onUpdateAmbient() {
                    ambient.update { it.copy(updateCount = it.updateCount + 1) }
                }
            },
        )

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        lifecycle.addObserver(ambientObserver)
        val app = application as EndurainWearApplication
        setContent {
            MaterialTheme {
                AppScaffold {
                    EndurainWearScreen(app.recorder, app.phoneLink, ambient)
                }
            }
        }
    }
}

@Composable
private fun EndurainWearScreen(
    recorder: WorkoutRecorder,
    phoneLink: PhoneLink,
    ambientState: StateFlow<AmbientState>,
) {
    val state by recorder.state.collectAsStateWithLifecycle()
    val ambient by ambientState.collectAsStateWithLifecycle()
    val waiting by phoneLink.waitingCount.collectAsStateWithLifecycle()
    val countdownSeconds by recorder.countdownSeconds.collectAsStateWithLifecycle()
    val error = state.errorMessage
    when {
        error != null -> MessageScreen(stringResource(error)) { recorder.dismissError() }
        else ->
            when (val phase = state.phase) {
                WorkoutPhase.Idle, WorkoutPhase.Starting ->
                    StartScreen(
                        enabled = phase == WorkoutPhase.Idle,
                        waitingCount = waiting,
                        countdownSeconds = countdownSeconds,
                        onStart = recorder::start,
                        onCycleCountdown = recorder::cycleCountdown,
                    )
                WorkoutPhase.ConfirmingTakeover ->
                    ConfirmScreen(
                        message = stringResource(R.string.takeover_confirm),
                        confirmLabel = stringResource(R.string.takeover_start),
                        onConfirm = recorder::confirmTakeover,
                        onCancel = recorder::cancelTakeover,
                    )
                is WorkoutPhase.CountingDown ->
                    CountdownScreen(
                        state = state,
                        ambient = ambient,
                        endsAtMillis = phase.endsAtMillis,
                        onCancel = recorder::cancelCountdown,
                        onStartNow = recorder::skipCountdown,
                    )
                is WorkoutPhase.Active, WorkoutPhase.Ending ->
                    ActiveScreen(
                        state = state,
                        ambient = ambient,
                        onPause = recorder::pause,
                        onResume = recorder::resume,
                        onEnd = recorder::end,
                    )
                is WorkoutPhase.Finished -> SummaryScreen(phase.summary, recorder::dismissSummary)
            }
    }
}
