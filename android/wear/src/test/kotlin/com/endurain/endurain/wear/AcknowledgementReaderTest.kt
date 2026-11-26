package com.endurain.endurain.wear

import com.endurain.endurain.watchlink.WatchProtocol
import org.junit.Assert.assertEquals
import org.junit.Test

class AcknowledgementReaderTest {
    @Test
    fun readsSessionsOfAcknowledgementPaths() {
        val items =
            listOf(
                WatchProtocol.ackPath("a") to WatchProtocol.PAYLOAD_VERSION,
                WatchProtocol.ackPath("b/c") to 0,
            )
        assertEquals(listOf("a", "b/c"), AcknowledgementReader.sessionIds(items))
    }

    @Test
    fun skipsOtherPathsButAcceptsNewerVersions() {
        // The phone may update first; its acknowledgements must still clear
        // the outbox.
        val items =
            listOf(
                WatchProtocol.handoffPath("a") to 1,
                null to 1,
                WatchProtocol.ackPath("future") to WatchProtocol.PAYLOAD_VERSION + 1,
                WatchProtocol.ackPath("ok") to 1,
            )
        assertEquals(listOf("future", "ok"), AcknowledgementReader.sessionIds(items))
    }
}
