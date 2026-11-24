package dev.stupeni.kotlincore

interface Transport {
    fun connect()
}

class PendingLink(private val transport: Transport) {
    private var pendingAction: (() -> Unit)? = null
    private var connected = false
    private var connecting = false

    fun runWhenReady(action: () -> Unit): Unit = TODO("K: runWhenReady")

    fun onConnected(): Unit = TODO("K: onConnected")

    fun onDisconnected(): Unit = TODO("K: onDisconnected")
}
