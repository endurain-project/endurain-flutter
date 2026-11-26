package com.endurain.endurain.watch

import android.content.Context
import android.util.Log
import com.endurain.endurain.watchlink.HandoffFileStore
import com.endurain.endurain.watchlink.WatchProtocol
import com.google.android.gms.common.api.ApiException
import com.google.android.gms.tasks.Tasks
import com.google.android.gms.wearable.CapabilityClient
import com.google.android.gms.wearable.DataClient
import com.google.android.gms.wearable.DataItem
import com.google.android.gms.wearable.DataMapItem
import com.google.android.gms.wearable.PutDataMapRequest
import com.google.android.gms.wearable.Wearable
import java.util.concurrent.ExecutionException
import java.util.concurrent.TimeUnit
import java.util.concurrent.TimeoutException

/**
 * [WatchLink] over the Wearable Data Layer.
 *
 * The watch publishes each session as a data item with the envelope as an
 * asset. Data items are stored by Google Play Services and synced whenever
 * the devices connect, so a workout finished out of range still arrives, and
 * an item stays available until the watch deletes it after the phone's
 * acknowledgement.
 */
class DataLayerWatchLink(private val context: Context) : WatchLink {
    private val dataClient by lazy { Wearable.getDataClient(context) }
    private val nodeClient by lazy { Wearable.getNodeClient(context) }
    private val capabilityClient by lazy { Wearable.getCapabilityClient(context) }
    private var capabilityListener: CapabilityClient.OnCapabilityChangedListener? = null

    override fun linkStatus(): String =
        try {
            val known = await(capabilityClient.getCapability(WatchProtocol.WEAR_APP_CAPABILITY, CapabilityClient.FILTER_ALL))
            val reachable =
                await(capabilityClient.getCapability(WatchProtocol.WEAR_APP_CAPABILITY, CapabilityClient.FILTER_REACHABLE))
            val connected = await(nodeClient.connectedNodes)
            WatchLinkState.status(
                isAvailable = true,
                appNodesKnown = known.nodes.isNotEmpty(),
                appNodeReachable = reachable.nodes.isNotEmpty(),
                anyNodeConnected = connected.isNotEmpty(),
            )
        } catch (error: Exception) {
            // ApiException: the Wearable API is missing on this phone (no
            // Play Services, or no Wear OS companion app installed).
            if (unwrap(error) !is ApiException) {
                Log.w(TAG, "Could not read the watch link state", error)
            }
            WatchLinkState.status(
                isAvailable = false,
                appNodesKnown = false,
                appNodeReachable = false,
                anyNodeConnected = false,
            )
        }

    override fun pullPendingHandoffs(inbox: HandoffFileStore) {
        val acknowledged =
            items(WatchProtocol.ACK_PATH_PREFIX)
                .mapNotNull { WatchProtocol.sessionIdFromPath(it.uri.path, WatchProtocol.ACK_PATH_PREFIX) }
                .toSet()
        for (item in items(WatchProtocol.HANDOFF_PATH_PREFIX)) {
            val sessionId = WatchProtocol.sessionIdFromPath(item.uri.path, WatchProtocol.HANDOFF_PATH_PREFIX)
            if (sessionId == null || sessionId in acknowledged || inbox.entry(sessionId) != null) {
                continue
            }
            storeHandoff(context, item, inbox)
        }
    }

    override fun acknowledge(sessionId: String) {
        val request =
            PutDataMapRequest.create(WatchProtocol.ackPath(sessionId)).apply {
                dataMap.putString(WatchProtocol.KEY_SESSION_ID, sessionId)
                dataMap.putInt(WatchProtocol.KEY_VERSION, WatchProtocol.PAYLOAD_VERSION)
            }
        // Stored locally by Play Services right away and synced when the
        // watch connects, so it survives the app closing in between.
        await(dataClient.putDataItem(request.asPutDataRequest().setUrgent()))
    }

    override fun startObserving(onLinkStatusChanged: (String) -> Unit) {
        stopObserving()
        val listener =
            CapabilityClient.OnCapabilityChangedListener {
                Thread { onLinkStatusChanged(linkStatus()) }.start()
            }
        capabilityListener = listener
        capabilityClient.addListener(listener, WatchProtocol.WEAR_APP_CAPABILITY)
    }

    override fun stopObserving() {
        capabilityListener?.let { capabilityClient.removeListener(it) }
        capabilityListener = null
    }

    private fun items(prefix: String): List<DataItem> {
        val buffer = await(dataClient.getDataItems(WatchProtocol.dataLayerUri(prefix), DataClient.FILTER_PREFIX))
        return try {
            buffer.map { it.freeze() }
        } finally {
            buffer.release()
        }
    }

    companion object {
        private const val TAG = "EndurainWatch"
        private const val TIMEOUT_SECONDS = 10L

        /**
         * Downloads the envelope asset of a handoff [item] into [inbox].
         * Returns false when the item carries no usable session.
         */
        fun storeHandoff(context: Context, item: DataItem, inbox: HandoffFileStore): Boolean {
            val sessionId = WatchProtocol.sessionIdFromPath(item.uri.path, WatchProtocol.HANDOFF_PATH_PREFIX) ?: return false
            val dataMap = DataMapItem.fromDataItem(item).dataMap
            val version = dataMap.getInt(WatchProtocol.KEY_VERSION)
            if (!WatchProtocol.isSupportedVersion(version)) {
                // Left in the Data Layer, unacknowledged, for an app version that understands it.
                Log.w(TAG, "Ignoring a session with unsupported version $version")
                return false
            }
            val asset = dataMap.getAsset(WatchProtocol.KEY_PAYLOAD) ?: return false
            return try {
                val response = await(Wearable.getDataClient(context).getFdForAsset(asset))
                val bytes = response.inputStream.use { WatchProtocol.readCapped(it) }
                if (bytes == null) {
                    Log.w(TAG, "Dropping a session larger than ${WatchProtocol.MAX_PAYLOAD_BYTES} bytes")
                    return false
                }
                inbox.save(bytes, sessionId)
                true
            } catch (error: Exception) {
                Log.w(TAG, "Could not store a session from the watch", error)
                false
            }
        }

        fun <T> await(task: com.google.android.gms.tasks.Task<T>): T = Tasks.await(task, TIMEOUT_SECONDS, TimeUnit.SECONDS)

        private fun unwrap(error: Throwable): Throwable =
            if (error is ExecutionException || error is TimeoutException) error.cause ?: error else error
    }
}
