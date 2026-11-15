package dev.stupeni.career

enum class Link { LocalHttp, Ble, Cloud, None }

data class DeviceFacts(
    val sameLan: Boolean,
    val bleProvenOnDevice: Boolean,
    val cloudReachable: Boolean,
    val needsLowLatency: Boolean,
)

fun chooseTransport(facts: DeviceFacts): Link = TODO("C2: chooseTransport")
