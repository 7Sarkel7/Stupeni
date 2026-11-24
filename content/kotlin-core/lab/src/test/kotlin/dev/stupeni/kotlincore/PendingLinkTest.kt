package dev.stupeni.kotlincore

import kotlin.test.Test
import kotlin.test.assertEquals

class PendingLinkTest {
    private class FakeTransport : Transport {
        var connectCalls = 0
        override fun connect() {
            connectCalls++
        }
    }

    @Test
    fun notConnectedStoresActionAndConnectsOnce() {
        val transport = FakeTransport()
        val link = PendingLink(transport)
        val log = mutableListOf<String>()
        link.runWhenReady { log += "a" }
        assertEquals(1, transport.connectCalls)
        assertEquals(emptyList(), log)
    }

    @Test
    fun onConnectedRunsPendingExactlyOnce() {
        val link = PendingLink(FakeTransport())
        val log = mutableListOf<String>()
        link.runWhenReady { log += "a" }
        link.onConnected()
        link.onConnected()
        assertEquals(listOf("a"), log)
    }

    @Test
    fun secondRequestWhileConnectingReplacesPendingAndDoesNotReconnect() {
        val transport = FakeTransport()
        val link = PendingLink(transport)
        val log = mutableListOf<String>()
        link.runWhenReady { log += "first" }
        link.runWhenReady { log += "second" }
        assertEquals(1, transport.connectCalls)
        link.onConnected()
        assertEquals(listOf("second"), log)
    }

    @Test
    fun connectedRunsImmediatelyWithoutConnecting() {
        val transport = FakeTransport()
        val link = PendingLink(transport)
        link.onConnected()
        val log = mutableListOf<String>()
        link.runWhenReady { log += "now" }
        assertEquals(listOf("now"), log)
        assertEquals(0, transport.connectCalls)
    }

    @Test
    fun afterDisconnectNextRequestConnectsAgain() {
        val transport = FakeTransport()
        val link = PendingLink(transport)
        link.runWhenReady { }
        link.onConnected()
        link.onDisconnected()
        val log = mutableListOf<String>()
        link.runWhenReady { log += "again" }
        assertEquals(2, transport.connectCalls)
        assertEquals(emptyList(), log)
        link.onConnected()
        assertEquals(listOf("again"), log)
    }

    @Test
    fun disconnectDropsPendingAction() {
        val transport = FakeTransport()
        val link = PendingLink(transport)
        val log = mutableListOf<String>()
        link.runWhenReady { log += "stale" }
        link.onDisconnected()
        link.onConnected()
        assertEquals(emptyList(), log)
    }
}
