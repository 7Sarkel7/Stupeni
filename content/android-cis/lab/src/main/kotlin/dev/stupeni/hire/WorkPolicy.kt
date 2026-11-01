package dev.stupeni.hire

data class SyncSignals(
    val pending: Int,
    val networkConnected: Boolean,
    val batteryLow: Boolean,
    val alreadyRunning: Boolean,
)

fun shouldEnqueueSync(signals: SyncSignals): Boolean = TODO("A8: shouldEnqueueSync")
