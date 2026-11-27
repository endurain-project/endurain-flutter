package com.endurain.endurain.wear

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import androidx.wear.compose.material3.Button
import androidx.wear.compose.material3.ButtonDefaults
import androidx.wear.compose.material3.MaterialTheme
import androidx.wear.compose.material3.ScreenScaffold
import androidx.wear.compose.material3.Text
import kotlinx.coroutines.delay

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
