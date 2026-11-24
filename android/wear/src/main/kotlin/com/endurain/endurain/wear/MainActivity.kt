package com.endurain.endurain.wear

import android.Manifest
import android.os.Build
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.wear.compose.foundation.lazy.ScalingLazyColumn
import androidx.wear.compose.foundation.lazy.rememberScalingLazyListState
import androidx.wear.compose.material3.AppScaffold
import androidx.wear.compose.material3.Button
import androidx.wear.compose.material3.ButtonDefaults
import androidx.wear.compose.material3.ListHeader
import androidx.wear.compose.material3.MaterialTheme
import androidx.wear.compose.material3.ScreenScaffold
import androidx.wear.compose.material3.Text
import com.endurain.endurain.watchlink.WatchActivityType
import kotlinx.coroutines.delay
import java.util.Locale

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val app = application as EndurainWearApplication
        setContent {
            MaterialTheme {
                AppScaffold {
                    EndurainWearScreen(app.recorder, app.phoneLink)
                }
            }
        }
    }
}

@Composable
private fun EndurainWearScreen(
    recorder: WorkoutRecorder,
    phoneLink: PhoneLink,
) {
    val state by recorder.state.collectAsStateWithLifecycle()
    val waiting by phoneLink.waitingCount.collectAsStateWithLifecycle()
    val error = state.errorMessage
    when {
        error != null -> MessageScreen(stringResource(error)) { recorder.dismissError() }
        else ->
            when (val phase = state.phase) {
                WorkoutPhase.Idle, WorkoutPhase.Starting ->
                    StartScreen(
                        enabled = phase == WorkoutPhase.Idle,
                        waitingCount = waiting,
                        onStart = recorder::start,
                    )
                is WorkoutPhase.Active, WorkoutPhase.Ending ->
                    ActiveScreen(
                        state = state,
                        onPause = recorder::pause,
                        onResume = recorder::resume,
                        onEnd = recorder::end,
                    )
                is WorkoutPhase.Finished -> SummaryScreen(phase.summary, recorder::dismissSummary)
            }
    }
}

private fun requiredPermissions(): Array<String> =
    buildList {
        add(Manifest.permission.ACCESS_FINE_LOCATION)
        add(Manifest.permission.ACTIVITY_RECOGNITION)
        add(if (Build.VERSION.SDK_INT >= 36) "android.permission.health.READ_HEART_RATE" else Manifest.permission.BODY_SENSORS)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) add(Manifest.permission.POST_NOTIFICATIONS)
    }.toTypedArray()

@Composable
private fun StartScreen(
    enabled: Boolean,
    waitingCount: Int,
    onStart: (WatchActivityType) -> Unit,
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
private fun ActiveScreen(
    state: WorkoutUiState,
    onPause: () -> Unit,
    onResume: () -> Unit,
    onEnd: () -> Unit,
) {
    val paused = (state.phase as? WorkoutPhase.Active)?.paused == true
    val ending = state.phase == WorkoutPhase.Ending
    var confirmingEnd by remember { mutableStateOf(false) }
    if (confirmingEnd) {
        ConfirmEndScreen(
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
    ScreenScaffold {
        HorizontalPager(state = pagerState, modifier = Modifier.fillMaxSize()) { page ->
            if (page == 0) {
                Column(
                    modifier = Modifier.fillMaxSize().padding(horizontal = 24.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp, Alignment.CenterVertically),
                    horizontalAlignment = Alignment.CenterHorizontally,
                ) {
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
                MetricsPage(state, paused, ending)
            }
        }
    }
}

@Composable
private fun MetricsPage(
    state: WorkoutUiState,
    paused: Boolean,
    ending: Boolean,
) {
    var now by remember { mutableLongStateOf(System.currentTimeMillis()) }
    LaunchedEffect(Unit) {
        while (true) {
            now = System.currentTimeMillis()
            delay(1_000)
        }
    }
    val elapsed = state.recording?.elapsedMillis(now) ?: 0
    Column(
        modifier = Modifier.fillMaxSize().padding(horizontal = 24.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        state.activityType?.let {
            Text(stringResource(it.label), style = MaterialTheme.typography.labelMedium)
        }
        Text(
            WorkoutFormat.duration(elapsed),
            style = MaterialTheme.typography.displaySmall,
            color = if (paused) MaterialTheme.colorScheme.tertiary else MaterialTheme.colorScheme.onSurface,
        )
        Text(WorkoutFormat.distance(state.distanceMeters), style = MaterialTheme.typography.titleMedium)
        Text("♥ ${state.heartRateBpm ?: "--"}", style = MaterialTheme.typography.titleMedium)
        if (ending) {
            Text(stringResource(R.string.saving), style = MaterialTheme.typography.labelSmall)
        }
    }
}

@Composable
private fun ConfirmEndScreen(
    onConfirm: () -> Unit,
    onCancel: () -> Unit,
) {
    ScreenScaffold {
        Column(
            modifier = Modifier.fillMaxSize().padding(horizontal = 24.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp, Alignment.CenterVertically),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Text(stringResource(R.string.end_confirm), textAlign = TextAlign.Center)
            Button(
                onClick = onConfirm,
                modifier = Modifier.fillMaxWidth(),
                label = { Text(stringResource(R.string.end_workout)) },
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
private fun SummaryScreen(
    summary: WorkoutSummary,
    onDone: () -> Unit,
) {
    val listState = rememberScalingLazyListState()
    ScreenScaffold(scrollState = listState) {
        ScalingLazyColumn(state = listState, modifier = Modifier.fillMaxSize()) {
            item { ListHeader { Text(stringResource(R.string.workout_saved)) } }
            item { Text(WorkoutFormat.duration(summary.elapsedMillis), style = MaterialTheme.typography.displaySmall) }
            if (summary.distanceMeters != null) {
                item { Text(WorkoutFormat.distance(summary.distanceMeters), style = MaterialTheme.typography.titleMedium) }
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
private fun MessageScreen(
    message: String,
    onDismiss: () -> Unit,
) {
    ScreenScaffold {
        Column(
            modifier = Modifier.fillMaxSize().padding(horizontal = 24.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp, Alignment.CenterVertically),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Text(message, textAlign = TextAlign.Center)
            Button(onClick = onDismiss, label = { Text(stringResource(android.R.string.ok)) })
        }
    }
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

private val WatchActivityType.label: Int
    get() =
        when (this) {
            WatchActivityType.RUN -> R.string.activity_run
            WatchActivityType.RIDE -> R.string.activity_ride
            WatchActivityType.WALK -> R.string.activity_walk
            WatchActivityType.HIKE -> R.string.activity_hike
        }

object WorkoutFormat {
    fun duration(millis: Long): String {
        val total = maxOf(0L, millis / 1000)
        val hours = total / 3600
        val minutes = (total % 3600) / 60
        val seconds = total % 60
        return if (hours > 0) {
            String.format(Locale.ROOT, "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            String.format(Locale.ROOT, "%02d:%02d", minutes, seconds)
        }
    }

    /** Kilometres, or miles in the regions that use them. */
    fun distance(meters: Double?, locale: Locale = Locale.getDefault()): String {
        val value = meters ?: 0.0
        return if (locale.country in IMPERIAL_REGIONS) {
            String.format(locale, "%.2f mi", value / 1609.344)
        } else {
            String.format(locale, "%.2f km", value / 1000)
        }
    }

    // Mirrors MeasurementSystem.forLocale in the phone app.
    private val IMPERIAL_REGIONS = setOf("US", "AS", "GU", "MP", "PR", "VI", "LR", "MM", "GB")
}
