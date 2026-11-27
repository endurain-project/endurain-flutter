package com.endurain.endurain.wear

import androidx.wear.protolayout.ActionBuilders
import androidx.wear.protolayout.DeviceParametersBuilders
import androidx.wear.protolayout.DimensionBuilders.expand
import androidx.wear.protolayout.LayoutElementBuilders
import androidx.wear.protolayout.ModifiersBuilders
import androidx.wear.protolayout.ResourceBuilders
import androidx.wear.protolayout.TimelineBuilders
import androidx.wear.protolayout.material3.materialScope
import androidx.wear.protolayout.material3.primaryLayout
import androidx.wear.protolayout.material3.text
import androidx.wear.protolayout.material3.textButton
import androidx.wear.protolayout.types.layoutString
import androidx.wear.tiles.RequestBuilders
import androidx.wear.tiles.TileBuilders
import androidx.wear.tiles.TileService
import com.google.common.util.concurrent.Futures
import com.google.common.util.concurrent.ListenableFuture

/**
 * A tile with one button that opens the app, so a workout starts a swipe
 * away from the watch face.
 *
 * Built with the Material 3 ProtoLayout components, so the button follows the
 * system's dynamic colour theme and the tile's layout margins. Nothing here
 * waits on I/O, so the futures are already completed.
 */
class StartWorkoutTileService : TileService() {
    override fun onTileRequest(requestParams: RequestBuilders.TileRequest): ListenableFuture<TileBuilders.Tile> =
        Futures.immediateFuture(
            TileBuilders.Tile.Builder()
                .setResourcesVersion(RESOURCES_VERSION)
                .setTileTimeline(
                    TimelineBuilders.Timeline.fromLayoutElement(layout(requestParams.deviceConfiguration)),
                )
                .build(),
        )

    override fun onTileResourcesRequest(
        requestParams: RequestBuilders.ResourcesRequest,
    ): ListenableFuture<ResourceBuilders.Resources> =
        Futures.immediateFuture(ResourceBuilders.Resources.Builder().setVersion(RESOURCES_VERSION).build())

    private fun layout(deviceParameters: DeviceParametersBuilders.DeviceParameters): LayoutElementBuilders.LayoutElement {
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
        return materialScope(this, deviceParameters) {
            primaryLayout(
                mainSlot = {
                    textButton(
                        onClick = opensApp,
                        labelContent = { text(getString(R.string.tile_label).layoutString) },
                        width = expand(),
                        height = expand(),
                    )
                },
            )
        }
    }

    private companion object {
        const val RESOURCES_VERSION = "1"
        const val CLICKABLE_ID = "start_workout"
    }
}
