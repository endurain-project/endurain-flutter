package com.endurain.endurain.watch

import com.endurain.endurain.watchlink.WatchProtocol
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import java.io.ByteArrayInputStream

@RunWith(RobolectricTestRunner::class)
class WatchProtocolTest {
    @Test
    fun acceptsTheCurrentAndOlderVersionsButNotNewerOnes() {
        assertTrue(WatchProtocol.isSupportedVersion(WatchProtocol.PAYLOAD_VERSION))
        assertTrue(WatchProtocol.isSupportedVersion(0))
        assertFalse(WatchProtocol.isSupportedVersion(WatchProtocol.PAYLOAD_VERSION + 1))
    }

    @Test
    fun readCappedReturnsPayloadsWithinTheLimit() {
        val data = ByteArray(20_000) { it.toByte() }
        assertEquals(data.toList(), WatchProtocol.readCapped(ByteArrayInputStream(data), maxBytes = 20_000)?.toList())
    }

    @Test
    fun readCappedDropsOversizePayloads() {
        val data = ByteArray(20_001)
        assertNull(WatchProtocol.readCapped(ByteArrayInputStream(data), maxBytes = 20_000))
    }

    @Test
    fun dataLayerUriUsesTheWearSchemeAndKeepsThePath() {
        val uri = WatchProtocol.dataLayerUri(WatchProtocol.ackPath("session/1"))
        assertEquals("wear", uri.scheme)
        assertEquals(WatchProtocol.ackPath("session/1"), uri.path)
    }
}
