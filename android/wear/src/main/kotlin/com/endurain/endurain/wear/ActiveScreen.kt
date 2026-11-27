package com.endurain.endurain.wear

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.wear.compose.foundation.pager.HorizontalPager
import androidx.wear.compose.foundation.pager.rememberPagerState
import androidx.wear.compose.material3.Button
import androidx.wear.compose.material3.ButtonDefaults
import androidx.wear.compose.material3.HorizontalPagerScaffold
import androidx.wear.compose.material3.MaterialTheme
import androidx.wear.compose.material3.ScreenScaffold
import androidx.wear.compose.material3.Text
import kotlinx.coroutines.delay

@Composable
internal fun ActiveScreen(
    state: WorkoutUiState,
    ambient: AmbientState,
    onPause: () -> Unit,
    onResume: () -> Unit,
    onEnd: () -> Unit,
) {
    val paused = (state.phase as? WorkoutPhase.Active)?.paused == true
    val ending = state.phase == WorkoutPhase.Ending
    var confirmingEnd by remember { mutableStateOf(false) }
    if (ambient.isAmbient) {
        // Only the elapsed time, dimmed: Health Services batches the other
        // metrics in ambient mode, so they could be stale, and there are no
        // buttons to press with the screen off.
        ScreenScaffold { MetricsPage(state, ambient, paused, ending) }
        return
    }
    if (confirmingEnd) {
        ConfirmScreen(
            message = stringResource(R.string.end_confirm),
            confirmLabel = stringResource(R.string.end_workout),
            onConfirm = {
                confirmingEnd = false
                onEnd()
            },
            onCancel = { confirmingEnd = false },
        )
        return
    }
    val pagerState = rememberPagerState(initialPage = 1, pageCount = { 2 })
    LaunchedEffect(paused) {
        if (!paused) pagerState.animateScrollToPage(1)
    }
    // The scaffold adds the page indicator that shows there is a second page.
    HorizontalPagerScaffold(pagerState = pagerState) {
        HorizontalPager(state = pagerState, modifier = Modifier.fillMaxSize()) { page ->
            ScreenScaffold {
                if (page == 0) {
                    CenteredColumn {
                        Button(
                            onClick = if (paused) onResume else onPause,
                            enabled = !ending,
                            modifier = Modifier.fillMaxWidth(),
                            label = { Text(stringResource(if (paused) R.string.resume else R.string.pause)) },
                        )
                        Button(
                            onClick = { confirmingEnd = true },
                            enabled = !ending,
                            colors = ButtonDefaults.filledTonalButtonColors(),
                            modifier = Modifier.fillMaxWidth(),
                            label = { Text(stringResource(R.string.end)) },
                        )
                    }
                } else {
                    MetricsPage(state, ambient, paused, ending)
                }
            }
        }
    }
}

@Composable
private fun MetricsPage(
    state: WorkoutUiState,
    ambient: AmbientState,
    paused: Boolean,
    ending: Boolean,
) {
    var now by remember { mutableLongStateOf(System.currentTimeMillis()) }
    // Ambient mode refreshes once per system update instead of every second.
    LaunchedEffect(ambient) {
        now = System.currentTimeMillis()
        while (!ambient.isAmbient) {
            delay(1_000)
            now = System.currentTimeMillis()
        }
    }
    val elapsed = state.recording?.elapsedMillis(now) ?: 0
    val dimmed = MaterialTheme.colorScheme.onSurfaceVariant
    CenteredColumn(Arrangement.Center) {
        state.activityType?.let {
            Text(stringResource(it.label), style = MaterialTheme.typography.labelMedium)
        }
        Text(
            WorkoutFormat.duration(elapsed),
            style = MaterialTheme.typography.displaySmall,
            color =
                when {
                    ambient.isAmbient -> dimmed
                    paused -> MaterialTheme.colorScheme.tertiary
                    else -> MaterialTheme.colorScheme.onSurface
                },
        )
        // Ambient mode shows the elapsed time only: the distance and heart rate
        // Health Services batches there could be stale.
        if (ambient.isAmbient) return@CenteredColumn
        Text(distanceText(state.distanceMeters), style = MaterialTheme.typography.titleMedium)
        HeartRateText(state.heartRateBpm)
        LocationStatusNote(state.locationStatus)
        if (state.heartRateStatus == SensorStatus.UNAVAILABLE) {
            FootnoteText(stringResource(R.string.hr_unavailable))
        }
        if (ending) {
            Text(stringResource(R.string.saving), style = MaterialTheme.typography.labelSmall)
        }
    }
}

@Composable
private fun HeartRateText(bpm: Int?) {
    val text =
        if (bpm != null) {
            stringResource(R.string.heart_rate_display, bpm)
        } else {
            stringResource(R.string.heart_rate_none)
        }
    val description =
        if (bpm != null) {
            stringResource(R.string.heart_rate_description, bpm)
        } else {
            stringResource(R.string.hr_unavailable)
        }
    Text(
        text,
        style = MaterialTheme.typography.titleMedium,
        modifier = Modifier.semantics { contentDescription = description },
    )
}
