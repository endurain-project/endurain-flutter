package com.endurain.endurain.wear

import android.Manifest
import android.os.Build
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.wear.compose.foundation.lazy.TransformingLazyColumn
import androidx.wear.compose.foundation.lazy.rememberTransformingLazyColumnState
import androidx.wear.compose.material3.Button
import androidx.wear.compose.material3.ButtonDefaults
import androidx.wear.compose.material3.ListHeader
import androidx.wear.compose.material3.ScreenScaffold
import androidx.wear.compose.material3.SurfaceTransformation
import androidx.wear.compose.material3.Text
import androidx.wear.compose.material3.lazy.rememberTransformationSpec
import androidx.wear.compose.material3.lazy.transformedHeight
import com.endurain.endurain.watchlink.WatchActivityType

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
    val listState = rememberTransformingLazyColumnState()
    val transformationSpec = rememberTransformationSpec()
    ScreenScaffold(scrollState = listState) { contentPadding ->
        TransformingLazyColumn(
            state = listState,
            contentPadding = contentPadding,
            modifier = Modifier.fillMaxSize(),
        ) {
            item {
                ListHeader(
                    modifier = Modifier.fillMaxWidth().transformedHeight(this, transformationSpec),
                    transformation = SurfaceTransformation(transformationSpec),
                ) { Text(stringResource(R.string.app_name)) }
            }
            WatchActivityType.entries.forEach { type ->
                item {
                    Button(
                        onClick = {
                            pendingType = type
                            launcher.launch(ExercisePermissions.requestedAtStart(Build.VERSION.SDK_INT))
                        },
                        enabled = enabled,
                        modifier = Modifier.fillMaxWidth().transformedHeight(this, transformationSpec),
                        transformation = SurfaceTransformation(transformationSpec),
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
                    modifier = Modifier.fillMaxWidth().transformedHeight(this, transformationSpec),
                    transformation = SurfaceTransformation(transformationSpec),
                    label = { Text(stringResource(R.string.countdown_setting, value)) },
                )
            }
            if (permissionsDenied) {
                item {
                    FootnoteText(
                        stringResource(R.string.permissions_needed),
                        Modifier.transformedHeight(this, transformationSpec),
                    )
                }
            }
            if (waitingCount > 0) {
                item {
                    FootnoteText(
                        stringResource(R.string.waiting_for_phone, waitingCount),
                        Modifier.transformedHeight(this, transformationSpec),
                    )
                }
            }
        }
    }
}
