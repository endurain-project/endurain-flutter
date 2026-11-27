package com.endurain.endurain.wear

import androidx.wear.protolayout.ActionBuilders
import androidx.wear.protolayout.ColorBuilders.argb
import androidx.wear.protolayout.DimensionBuilders.dp
import androidx.wear.protolayout.DimensionBuilders.expand
import androidx.wear.protolayout.DimensionBuilders.sp
import androidx.wear.protolayout.DimensionBuilders.wrap
import androidx.wear.protolayout.LayoutElementBuilders
import androidx.wear.protolayout.ModifiersBuilders
import androidx.wear.protolayout.ResourceBuilders
import androidx.wear.protolayout.TimelineBuilders
import androidx.wear.tiles.RequestBuilders
import androidx.wear.tiles.TileBuilders
import androidx.wear.tiles.TileService
import com.google.common.util.concurrent.ListenableFuture
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.guava.future

/** A tile with one button that opens the app, so a workout starts a swipe away from the watch face. */
class StartWorkoutTileService : TileService() {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)

    override fun onDestroy() {
        scope.cancel()
        super.onDestroy()
    }

    override fun onTileRequest(requestParams: RequestBuilders.TileRequest): ListenableFuture<TileBuilders.Tile> =
        scope.future {
            TileBuilders.Tile.Builder()
                .setResourcesVersion(RESOURCES_VERSION)
                .setTileTimeline(TimelineBuilders.Timeline.fromLayoutElement(layout()))
                .build()
        }

    override fun onTileResourcesRequest(
        requestParams: RequestBuilders.ResourcesRequest,
    ): ListenableFuture<ResourceBuilders.Resources> =
        scope.future { ResourceBuilders.Resources.Builder().setVersion(RESOURCES_VERSION).build() }

    private fun layout(): LayoutElementBuilders.LayoutElement {
        val opensApp =
            ModifiersBuilders.Clickable.Builder()
                .setId(CLICKABLE_ID)
                .setOnClick(
                    ActionBuilders.LaunchAction.Builder()
                        .setAndroidActivity(
                            ActionBuilders.AndroidActivity.Builder()
                                .setPackageName(packageName)
                                .setClassName(MainActivity::class.java.name)
                                .build(),
                        )
                        .build(),
                )
                .build()
        val button =
            LayoutElementBuilders.Box.Builder()
                .setWidth(wrap())
                .setHeight(wrap())
                .setModifiers(
                    ModifiersBuilders.Modifiers.Builder()
                        .setBackground(
                            ModifiersBuilders.Background.Builder()
                                .setColor(argb(BUTTON_COLOR))
                                .setCorner(ModifiersBuilders.Corner.Builder().setRadius(dp(BUTTON_RADIUS_DP)).build())
                                .build(),
                        )
                        .setPadding(
                            ModifiersBuilders.Padding.Builder()
                                .setAll(dp(BUTTON_PADDING_DP))
                                .build(),
                        )
                        .setClickable(opensApp)
                        .build(),
                )
                .addContent(
                    LayoutElementBuilders.Text.Builder()
                        .setText(getString(R.string.tile_label))
                        .setFontStyle(
                            LayoutElementBuilders.FontStyle.Builder()
                                .setSize(sp(TEXT_SIZE_SP))
                                .setColor(argb(TEXT_COLOR))
                                .build(),
                        )
                        .build(),
                )
                .build()
        return LayoutElementBuilders.Box.Builder()
            .setWidth(expand())
            .setHeight(expand())
            .addContent(button)
            .build()
    }

    private companion object {
        const val RESOURCES_VERSION = "1"
        const val CLICKABLE_ID = "start_workout"
        const val BUTTON_COLOR = 0xFF19AB88.toInt()
        const val TEXT_COLOR = 0xFF000000.toInt()
        const val BUTTON_RADIUS_DP = 24f
        const val BUTTON_PADDING_DP = 16f
        const val TEXT_SIZE_SP = 18f
    }
}
