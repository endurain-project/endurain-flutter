package com.endurain.endurain.wear

import android.Manifest
import android.os.Build
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.wear.compose.foundation.pager.HorizontalPager
import androidx.wear.compose.foundation.pager.rememberPagerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.wear.compose.foundation.lazy.ScalingLazyColumn
import androidx.wear.compose.foundation.lazy.rememberScalingLazyListState
import androidx.wear.compose.material3.Button
import androidx.wear.compose.material3.ButtonDefaults
import androidx.wear.compose.material3.HorizontalPagerScaffold
import androidx.wear.compose.material3.ListHeader
import androidx.wear.compose.material3.MaterialTheme
import androidx.wear.compose.material3.ScreenScaffold
import androidx.wear.compose.material3.Text
import com.endurain.endurain.watchlink.WatchActivityType
import kotlinx.coroutines.delay

private fun requiredPermissions(): Array<String> =
    buildList {
        // Android lets the user downgrade to approximate location, so both are
        // requested together; only the precise one is accepted to start.
        add(Manifest.permission.ACCESS_FINE_LOCATION)
        add(Manifest.permission.ACCESS_COARSE_LOCATION)
        add(Manifest.permission.ACTIVITY_RECOGNITION)
        add(ExercisePermissions.heartRate(Build.VERSION.SDK_INT))
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) add(Manifest.permission.POST_NOTIFICATIONS)
    }.toTypedArray()

@Composable
internal fun StartScreen(
    enabled: Boolean,
    waitingCount: Int,
    countdownSeconds: Int,
    onStart: (WatchActivityType) -> Unit,
    onCycleCountdown: () -> Unit,
) {
    var pendingType by remember { mutableStateOf<WatchActivityType?>(null) }
    var permissionsDenied by remember { mutableStateOf(false) }
    val launcher =
        rememberLauncherForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) { results ->
            val type = pendingType
            pendingType = null
            // Location is required for a route; the rest only adds data.
            if (results[Manifest.permission.ACCESS_FINE_LOCATION] == true && type != null) {
                permissionsDenied = false
                onStart(type)
            } else {
                permissionsDenied = true
            }
        }
    val listState = rememberScalingLazyListState()
    ScreenScaffold(scrollState = listState) {
        ScalingLazyColumn(state = listState, modifier = Modifier.fillMaxSize()) {
            item { ListHeader { Text(stringResource(R.string.app_name)) } }
            WatchActivityType.entries.forEach { type ->
                item {
                    Button(
                        onClick = {
                            pendingType = type
                            launcher.launch(requiredPermissions())
                        },
                        enabled = enabled,
                        modifier = Modifier.fillMaxWidth(),
                        label = { Text(stringResource(type.label)) },
                    )
                }
            }
            item {
                val value =
                    if (countdownSeconds == 0) {
                        stringResource(R.string.countdown_off)
                    } else {
                        stringResource(R.string.countdown_seconds, countdownSeconds)
                    }
                Button(
                    onClick = onCycleCountdown,
                    enabled = enabled,
                    colors = ButtonDefaults.filledTonalButtonColors(),
                    modifier = Modifier.fillMaxWidth(),
                    label = { Text(stringResource(R.string.countdown_setting, value)) },
                )
            }
            if (permissionsDenied) {
                item { FootnoteText(stringResource(R.string.permissions_needed)) }
            }
            if (waitingCount > 0) {
                item { FootnoteText(stringResource(R.string.waiting_for_phone, waitingCount)) }
            }
        }
    }
}

@Composable
internal fun CountdownScreen(
    state: WorkoutUiState,
    ambient: AmbientState,
    endsAtMillis: Long,
    onCancel: () -> Unit,
    onStartNow: () -> Unit,
) {
    var now by remember { mutableLongStateOf(System.currentTimeMillis()) }
    // Ambient mode refreshes once per system update instead of every 200 ms.
    LaunchedEffect(endsAtMillis, ambient) {
        now = System.currentTimeMillis()
        while (!ambient.isAmbient) {
            delay(200)
            now = System.currentTimeMillis()
        }
    }
    val remaining = StartCountdown.remainingSeconds(endsAtMillis, now)
    val remainingDescription = stringResource(R.string.countdown_seconds_left, remaining)
    ScreenScaffold {
        CenteredColumn(Arrangement.spacedBy(4.dp, Alignment.CenterVertically)) {
            state.activityType?.let {
                Text(stringResource(it.label), style = MaterialTheme.typography.labelMedium)
            }
            Text(stringResource(R.string.countdown_starts_in), style = MaterialTheme.typography.labelSmall)
            Text(
                "$remaining",
                style = MaterialTheme.typography.displayLarge,
                modifier =
                    Modifier.semantics {
                        contentDescription = remainingDescription
                        liveRegion = LiveRegionMode.Polite
                    },
            )
            LocationStatusNote(state.locationStatus)
            Button(
                onClick = onStartNow,
                modifier = Modifier.fillMaxWidth(),
                label = { Text(stringResource(R.string.countdown_start_now)) },
            )
            Button(
                onClick = onCancel,
                colors = ButtonDefaults.filledTonalButtonColors(),
                modifier = Modifier.fillMaxWidth(),
                label = { Text(stringResource(R.string.cancel)) },
            )
        }
    }
}

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

@Composable
private fun LocationStatusNote(status: SensorStatus) {
    when (status) {
        SensorStatus.ACQUIRING -> FootnoteText(stringResource(R.string.gps_acquiring))
        SensorStatus.UNAVAILABLE -> FootnoteText(stringResource(R.string.gps_lost))
        else -> Unit
    }
}

/** A question with a confirming and a cancelling button. */
@Composable
internal fun ConfirmScreen(
    message: String,
    confirmLabel: String,
    onConfirm: () -> Unit,
    onCancel: () -> Unit,
) {
    ScreenScaffold {
        CenteredColumn {
            Text(message, textAlign = TextAlign.Center)
            Button(
                onClick = onConfirm,
                modifier = Modifier.fillMaxWidth(),
                label = { Text(confirmLabel) },
            )
            Button(
                onClick = onCancel,
                colors = ButtonDefaults.filledTonalButtonColors(),
                modifier = Modifier.fillMaxWidth(),
                label = { Text(stringResource(R.string.cancel)) },
            )
        }
    }
}

@Composable
internal fun SummaryScreen(
    summary: WorkoutSummary,
    onDone: () -> Unit,
) {
    val listState = rememberScalingLazyListState()
    ScreenScaffold(scrollState = listState) {
        ScalingLazyColumn(state = listState, modifier = Modifier.fillMaxSize()) {
            item { ListHeader { Text(stringResource(R.string.workout_saved)) } }
            item { Text(WorkoutFormat.duration(summary.elapsedMillis), style = MaterialTheme.typography.displaySmall) }
            if (summary.distanceMeters != null) {
                item { Text(distanceText(summary.distanceMeters), style = MaterialTheme.typography.titleMedium) }
            }
            item {
                FootnoteText(
                    stringResource(if (summary.hasRoute) R.string.summary_uploads else R.string.summary_no_route),
                )
            }
            item {
                Button(onClick = onDone, modifier = Modifier.fillMaxWidth(), label = { Text(stringResource(R.string.done)) })
            }
        }
    }
}

@Composable
internal fun MessageScreen(
    message: String,
    onDismiss: () -> Unit,
) {
    ScreenScaffold {
        CenteredColumn {
            Text(message, textAlign = TextAlign.Center)
            Button(onClick = onDismiss, label = { Text(stringResource(android.R.string.ok)) })
        }
    }
}

/** The full-screen, centered layout of the workout screens. */
@Composable
private fun CenteredColumn(
    verticalArrangement: Arrangement.Vertical = Arrangement.spacedBy(8.dp, Alignment.CenterVertically),
    content: @Composable ColumnScope.() -> Unit,
) {
    Column(
        modifier = Modifier.fillMaxSize().padding(horizontal = 24.dp),
        verticalArrangement = verticalArrangement,
        horizontalAlignment = Alignment.CenterHorizontally,
        content = content,
    )
}

@Composable
private fun FootnoteText(text: String) {
    Text(
        text,
        style = MaterialTheme.typography.labelSmall,
        color = MaterialTheme.colorScheme.onSurfaceVariant,
        textAlign = TextAlign.Center,
        modifier = Modifier.fillMaxWidth(),
    )
}

/** [WorkoutFormat.distance] with its localized unit, such as "1.50 km". */
@Composable
private fun distanceText(meters: Double?): String {
    val distance = WorkoutFormat.distance(meters)
    return stringResource(if (distance.imperial) R.string.distance_mi else R.string.distance_km, distance.value)
}

private val WatchActivityType.label: Int
    get() =
        when (this) {
            WatchActivityType.RUN -> R.string.activity_run
            WatchActivityType.RIDE -> R.string.activity_ride
            WatchActivityType.WALK -> R.string.activity_walk
            WatchActivityType.HIKE -> R.string.activity_hike
        }
