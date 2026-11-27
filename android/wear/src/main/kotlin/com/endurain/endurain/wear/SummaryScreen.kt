package com.endurain.endurain.wear

import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.wear.compose.foundation.lazy.TransformingLazyColumn
import androidx.wear.compose.foundation.lazy.rememberTransformingLazyColumnState
import androidx.wear.compose.material3.Button
import androidx.wear.compose.material3.ListHeader
import androidx.wear.compose.material3.MaterialTheme
import androidx.wear.compose.material3.ScreenScaffold
import androidx.wear.compose.material3.SurfaceTransformation
import androidx.wear.compose.material3.Text
import androidx.wear.compose.material3.lazy.rememberTransformationSpec
import androidx.wear.compose.material3.lazy.transformedHeight

@Composable
internal fun SummaryScreen(
    summary: WorkoutSummary,
    onDone: () -> Unit,
) {
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
                ) { Text(stringResource(R.string.workout_saved)) }
            }
            item {
                Text(
                    WorkoutFormat.duration(summary.elapsedMillis),
                    style = MaterialTheme.typography.displaySmall,
                    modifier = Modifier.transformedHeight(this, transformationSpec),
                )
            }
            if (summary.distanceMeters != null) {
                item {
                    Text(
                        distanceText(summary.distanceMeters),
                        style = MaterialTheme.typography.titleMedium,
                        modifier = Modifier.transformedHeight(this, transformationSpec),
                    )
                }
            }
            item {
                FootnoteText(
                    stringResource(if (summary.hasRoute) R.string.summary_uploads else R.string.summary_no_route),
                    Modifier.transformedHeight(this, transformationSpec),
                )
            }
            item {
                Button(
                    onClick = onDone,
                    modifier = Modifier.fillMaxWidth().transformedHeight(this, transformationSpec),
                    transformation = SurfaceTransformation(transformationSpec),
                    label = { Text(stringResource(R.string.done)) },
                )
            }
        }
    }
}
