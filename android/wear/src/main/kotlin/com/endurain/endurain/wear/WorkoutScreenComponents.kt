package com.endurain.endurain.wear

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.wear.compose.material3.Button
import androidx.wear.compose.material3.ButtonDefaults
import androidx.wear.compose.material3.MaterialTheme
import androidx.wear.compose.material3.ScreenScaffold
import androidx.wear.compose.material3.Text
import com.endurain.endurain.watchlink.WatchActivityType

// Pieces shared by the workout screens.

@Composable
internal fun LocationStatusNote(status: SensorStatus) {
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
internal fun CenteredColumn(
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
internal fun FootnoteText(
    text: String,
    modifier: Modifier = Modifier,
) {
    Text(
        text,
        style = MaterialTheme.typography.labelSmall,
        color = MaterialTheme.colorScheme.onSurfaceVariant,
        textAlign = TextAlign.Center,
        modifier = modifier.fillMaxWidth(),
    )
}

/** [WorkoutFormat.distance] with its localized unit, such as "1.50 km". */
@Composable
internal fun distanceText(meters: Double?): String {
    val distance = WorkoutFormat.distance(meters)
    return stringResource(if (distance.imperial) R.string.distance_mi else R.string.distance_km, distance.value)
}

internal val WatchActivityType.label: Int
    get() =
        when (this) {
            WatchActivityType.RUN -> R.string.activity_run
            WatchActivityType.RIDE -> R.string.activity_ride
            WatchActivityType.WALK -> R.string.activity_walk
            WatchActivityType.HIKE -> R.string.activity_hike
        }
