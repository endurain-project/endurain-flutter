package com.endurain.endurain.wear

import com.endurain.endurain.watchlink.WatchProtocol
import org.junit.Assert.assertEquals
import org.junit.Test

class AcknowledgementReaderTest {
    @Test
    fun readsSessionsOfAcknowledgementPaths() {
        val paths = listOf(WatchProtocol.ackPath("a"), WatchProtocol.ackPath("b/c"))
        assertEquals(listOf("a", "b/c"), AcknowledgementReader.sessionIds(paths))
    }

    @Test
    fun skipsOtherPaths() {
        val paths = listOf(WatchProtocol.handoffPath("a"), null, WatchProtocol.ackPath("ok"))
        assertEquals(listOf("ok"), AcknowledgementReader.sessionIds(paths))
    }
}
